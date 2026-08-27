import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/score_helper.dart';
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

  MatchesBloc({
    required this.repository,
    required this.webSocketService,
    required this.localStorageService,
  }) : super(MatchesState(selectedDate: DateTime.now())) {
    on<LoadMatchesEvent>(_onLoadMatches);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<SearchMatchesEvent>(_onSearchMatches);
    on<LiveMatchReceivedEvent>(_onLiveMatchReceived);
    on<ToggleMatchFavoriteEvent>(_onToggleMatchFavorite);

    // Listen to WebSocket events
    _wsSubscription = webSocketService.updatesStream.listen((update) {
      add(LiveMatchReceivedEvent(update));
    });
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

    final result = await repository.getMatches(
      date: dateStr,
      lang: lang,
      utcOffset: offset,
    );

    result.fold(
      onSuccess: (leagues) {
        final liveCount = _calculateLiveCount(leagues);
        final filtered = _applyFilters(
          leagues: leagues,
          filter: state.activeFilter,
          query: state.searchQuery,
        );

        emit(
          state.copyWith(
            status: leagues.isEmpty
                ? MatchesStatus.empty
                : MatchesStatus.success,
            allLeagues: leagues,
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
    final update = event.update;
    bool matchFound = false;

    final updatedLeagues = state.allLeagues.map((league) {
      final updatedMatches = league.matches.map((m) {
        final matchesId = update.matchId != null && m.id == update.matchId;
        final matchesTeams =
            (update.team1 != null &&
            update.team2 != null &&
            m.team1.toLowerCase().contains(update.team1!.toLowerCase()) &&
            m.team2.toLowerCase().contains(update.team2!.toLowerCase()));

        if (matchesId || matchesTeams) {
          matchFound = true;
          return m.copyWith(
            score1: update.score1 ?? m.score1,
            score2: update.score2 ?? m.score2,
            status: update.status ?? m.status,
            minute: update.minute ?? m.minute,
          );
        }
        return m;
      }).toList();

      return league.copyWith(matches: updatedMatches);
    }).toList();

    if (matchFound) {
      final liveCount = _calculateLiveCount(updatedLeagues);
      final filtered = _applyFilters(
        leagues: updatedLeagues,
        filter: state.activeFilter,
        query: state.searchQuery,
      );

      emit(
        state.copyWith(
          allLeagues: updatedLeagues,
          filteredLeagues: filtered,
          liveMatchesCount: liveCount,
        ),
      );
    }
  }

  int _calculateLiveCount(List<LeagueGroupEntity> leagues) {
    int count = 0;
    for (final l in leagues) {
      for (final m in l.matches) {
        if (ScoreHelper.isLiveStatus(m.status)) {
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

    return leagues
        .map((league) {
          final matches = league.matches.where((match) {
            // Apply filter
            final matchesFilter = switch (filter) {
              MatchFilterType.all => true,
              MatchFilterType.live => ScoreHelper.isLiveStatus(match.status),
              MatchFilterType.upcoming => ScoreHelper.isUpcomingStatus(
                match.status,
              ),
              MatchFilterType.finished => ScoreHelper.isFinishedStatus(
                match.status,
              ),
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

          return league.copyWith(matches: matches);
        })
        .where((league) => league.matches.isNotEmpty)
        .toList();
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
