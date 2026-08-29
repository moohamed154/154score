import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/realtime_merge_engine.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/matches_repository.dart';
import 'matches_event.dart';
import 'matches_state.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final MatchesRepository repository;
  final WebSocketService webSocketService;
  final LocalStorageService localStorageService;

  StreamSubscription? _wsSubscription;
  StreamSubscription? _wsStatusSubscription;
  Timer? _fallbackPollingTimer;

  MatchesBloc({
    required this.repository,
    required this.webSocketService,
    required this.localStorageService,
  }) : super(MatchesState(selectedDate: DateTime.now())) {
    on<LoadMatchesEvent>(_onLoadMatches);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<SearchMatchesEvent>(_onSearchMatches);
    on<LiveMatchReceivedEvent>(_onLiveMatchReceived);
    on<SocketStatusChangedEvent>(_onSocketStatusChanged);
    on<ToggleMatchFavoriteEvent>(_onToggleMatchFavorite);

    // 1. Listen to Real-Time WebSocket updates
    try {
      _wsSubscription = webSocketService.updatesStream.listen((update) {
        add(LiveMatchReceivedEvent(update));
      });
    } catch (_) {}

    // 2. Listen to WebSocket Connection status for intelligent fallback polling
    try {
      _wsStatusSubscription = webSocketService.statusStream.listen((status) {
        add(SocketStatusChangedEvent(status));
      });
    } catch (_) {}

    // 3. Connect WebSocket if not already connected
    try {
      webSocketService.connect();
    } catch (_) {}
  }

  Future<void> _onLoadMatches(
    LoadMatchesEvent event,
    Emitter<MatchesState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(
        state.copyWith(status: MatchesStatus.loading, selectedDate: event.date),
      );
    }

    final dateStr = DateFormatter.toApiDateString(event.date);
    final lang = localStorageService.getLanguage();
    final offset = localStorageService.getTimezoneOffset();

    final result = await repository.getMatchesByDate(
      date: dateStr,
      lang: lang,
      utcOffset: offset,
    );

    try {
      webSocketService.recordRestFallback(
        isActive:
            _fallbackPollingTimer != null && _fallbackPollingTimer!.isActive,
        refreshedAt: DateTime.now(),
      );
    } catch (_) {}

    result.fold(
      onSuccess: (leagues) {
        final reconciledLeagues =
            RealtimeMergeEngine.reconcileRestLeaguesWithRealtime(
              restLeagues: leagues,
              currentLeagues: state.allLeagues,
            );

        final liveCount = _calculateLiveCount(reconciledLeagues);
        final filtered = _applyFilters(
          leagues: reconciledLeagues,
          filter: state.activeFilter,
          query: state.searchQuery,
        );

        emit(
          state.copyWith(
            status: reconciledLeagues.isEmpty
                ? MatchesStatus.empty
                : MatchesStatus.success,
            allLeagues: reconciledLeagues,
            filteredLeagues: filtered,
            selectedDate: event.date,
            liveMatchesCount: liveCount,
            errorMessage: null,
          ),
        );
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: MatchesStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  void _onChangeFilter(ChangeFilterEvent event, Emitter<MatchesState> emit) {
    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: event.filter,
      query: state.searchQuery,
    );

    emit(state.copyWith(activeFilter: event.filter, filteredLeagues: filtered));
  }

  void _onSearchMatches(SearchMatchesEvent event, Emitter<MatchesState> emit) {
    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: state.activeFilter,
      query: event.query,
    );

    emit(state.copyWith(searchQuery: event.query, filteredLeagues: filtered));
  }

  Future<void> _onToggleMatchFavorite(
    ToggleMatchFavoriteEvent event,
    Emitter<MatchesState> emit,
  ) async {
    await localStorageService.toggleFavoriteMatch(event.matchId);
    final favorites = localStorageService.getFavoriteMatches();

    final updatedAll = state.allLeagues.map((league) {
      final updatedMatches = league.matches.map((match) {
        if (match.id == event.matchId) {
          return match.copyWith(isFavorite: favorites.contains(match.id));
        }
        return match;
      }).toList();
      return league.copyWith(matches: updatedMatches);
    }).toList();

    final filtered = _applyFilters(
      leagues: updatedAll,
      filter: state.activeFilter,
      query: state.searchQuery,
    );

    emit(state.copyWith(allLeagues: updatedAll, filteredLeagues: filtered));
  }

  void _onLiveMatchReceived(
    LiveMatchReceivedEvent event,
    Emitter<MatchesState> emit,
  ) {
    final mergeResult = RealtimeMergeEngine.mergeMatchesWithRealtime(
      existingLeagues: state.allLeagues,
      update: event.update,
    );

    if (mergeResult.isUpdated) {
      final liveCount = _calculateLiveCount(mergeResult.data);
      final filtered = _applyFilters(
        leagues: mergeResult.data,
        filter: state.activeFilter,
        query: state.searchQuery,
      );

      emit(
        state.copyWith(
          allLeagues: mergeResult.data,
          filteredLeagues: filtered,
          liveMatchesCount: liveCount,
        ),
      );
    }
  }

  void _onSocketStatusChanged(
    SocketStatusChangedEvent event,
    Emitter<MatchesState> emit,
  ) {
    if (event.status == SocketConnectionState.connected) {
      _stopFallbackPolling();
      try {
        webSocketService.recordRestFallback(isActive: false);
      } catch (_) {}
      // Refresh REST snapshot to heal any gap during disconnect
      if (state.status == MatchesStatus.success ||
          state.status == MatchesStatus.empty) {
        add(LoadMatchesEvent(date: state.selectedDate, isRefresh: true));
      }
    } else if (event.status == SocketConnectionState.disconnected ||
        event.status == SocketConnectionState.error) {
      try {
        webSocketService.recordRestFallback(isActive: true);
      } catch (_) {}
      _startFallbackPolling();
    }
  }

  void _startFallbackPolling() {
    if (_fallbackPollingTimer != null && _fallbackPollingTimer!.isActive) {
      return;
    }

    // Poll every 35 seconds only when disconnected and matches are loaded
    _fallbackPollingTimer = Timer.periodic(const Duration(seconds: 35), (
      timer,
    ) {
      if (state.status == MatchesStatus.success ||
          state.status == MatchesStatus.empty) {
        add(LoadMatchesEvent(date: state.selectedDate, isRefresh: true));
      }
    });
  }

  void _stopFallbackPolling() {
    _fallbackPollingTimer?.cancel();
    _fallbackPollingTimer = null;
  }

  int _calculateLiveCount(List<LeagueGroupEntity> leagues) {
    int count = 0;
    for (final l in leagues) {
      for (final m in l.matches) {
        final phase = MatchStatusHelper.parseStatus(m.status, time: m.time);
        if (MatchStatusHelper.isLive(phase)) {
          count++;
        }
      }
    }
    return count;
  }

  List<LeagueGroupEntity> _applyFilters({
    required List<LeagueGroupEntity> leagues,
    required MatchFilterType filter,
    required String query,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    final result = leagues
        .map((league) {
          final matches = league.matches.where((match) {
            final phase = MatchStatusHelper.parseStatus(
              match.status,
              time: match.time,
            );

            // Apply filter
            final matchesFilter = switch (filter) {
              MatchFilterType.all => true,
              MatchFilterType.live => MatchStatusHelper.isLive(phase),
              MatchFilterType.upcoming => MatchStatusHelper.isUpcoming(phase),
              MatchFilterType.finished => MatchStatusHelper.isFinished(phase),
              MatchFilterType.favorites => match.isFavorite,
            };

            if (!matchesFilter) return false;

            // Apply search query
            if (cleanQuery.isNotEmpty) {
              final inTeams =
                  match.team1.toLowerCase().contains(cleanQuery) ||
                  match.team2.toLowerCase().contains(cleanQuery);
              final inLeague = (match.leagueTitle ?? league.leagueTitle)
                  .toLowerCase()
                  .contains(cleanQuery);
              return inTeams || inLeague;
            }

            return true;
          }).toList();

          // Sort matches within each league: Live -> Upcoming -> Finished
          matches.sort((a, b) {
            final pA = MatchStatusHelper.getPriority(
              MatchStatusHelper.parseStatus(a.status, time: a.time),
            );
            final pB = MatchStatusHelper.getPriority(
              MatchStatusHelper.parseStatus(b.status, time: b.time),
            );
            return pA.compareTo(pB);
          });

          return league.copyWith(matches: matches);
        })
        .where((league) => league.matches.isNotEmpty)
        .toList();

    // Sort leagues with live matches first
    result.sort((a, b) {
      final aHasLive = a.matches.any(
        (m) => MatchStatusHelper.isLive(
          MatchStatusHelper.parseStatus(m.status, time: m.time),
        ),
      );
      final bHasLive = b.matches.any(
        (m) => MatchStatusHelper.isLive(
          MatchStatusHelper.parseStatus(m.status, time: m.time),
        ),
      );
      if (aHasLive && !bHasLive) return -1;
      if (!aHasLive && bHasLive) return 1;
      return 0;
    });

    return result;
  }

  @override
  Future<void> close() {
    _stopFallbackPolling();
    _wsSubscription?.cancel();
    _wsStatusSubscription?.cancel();
    return super.close();
  }
}
