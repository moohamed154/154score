import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score154/core/utils/score_helper.dart';

import '../../../../core/notifications/live_match_foreground_service.dart';
import '../../../../core/notifications/match_notification_tracker.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/realtime_merge_engine.dart';
import '../../../../core/utils/team_resolver.dart';
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
  Timer? _livePollerTimer;
  final Set<String> _joinedLiveMatchRooms = <String>{};
  int _currentPollIntervalSeconds = 30;
  final Map<String, List<LeagueGroupEntity>> _cachedDateLeagues = {};
  final Map<String, List<LeagueGroupEntity>> _cachedFilteredDateLeagues = {};
  final Map<String, DateTime> _cachedDateTimes = {};

  static String _cacheKey(String dateStr, String lang) => '$dateStr-$lang';

  static MatchFilterType _parseSavedFilter(String? val) {
    if (val == null) return MatchFilterType.all;
    return MatchFilterType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => MatchFilterType.all,
    );
  }

  static MatchesSortOrder _parseSavedSortOrder(String? val) {
    if (val == null) return MatchesSortOrder.championship;
    if (val == 'championship' || val == 'importance') {
      return MatchesSortOrder.championship;
    }
    return MatchesSortOrder.values.firstWhere(
      (e) => e.name == val,
      orElse: () => MatchesSortOrder.championship,
    );
  }

  MatchesBloc({
    required this.repository,
    required this.webSocketService,
    required this.localStorageService,
  }) : super(
          MatchesState(
            selectedDate: DateTime.now(),
            activeFilter: _parseSavedFilter(
              localStorageService.getMatchesFilter(),
            ),
            sortOrder: _parseSavedSortOrder(
              localStorageService.getMatchesSortOrder(),
            ),
            hideFavorites: localStorageService.getHideFavorites(),
            timeFormat: localStorageService.getTimeFormat(),
          ),
        ) {
    on<LoadMatchesEvent>(_onLoadMatches);
    on<PreloadMatchesEvent>(_onPreloadMatches);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<ApplyMatchesFilterEvent>(_onApplyMatchesFilter);
    on<ResetMatchesFilterEvent>(_onResetMatchesFilter);
    on<SearchMatchesEvent>(_onSearchMatches);
    on<LiveMatchReceivedEvent>(_onLiveMatchReceived);
    on<SocketStatusChangedEvent>(_onSocketStatusChanged);
    on<ToggleMatchFavoriteEvent>(_onToggleMatchFavorite);
    on<RefreshFavoritesEvent>(_onRefreshFavorites);
    on<ChangeTimezoneEvent>(_onChangeTimezone);
    on<ChangeTimeFormatEvent>(_onChangeTimeFormat);
    on<LiveMatchesSnapshotReceivedEvent>(_onLiveMatchesSnapshotReceived);
    on<ChangeMatchesLanguageEvent>(_onChangeMatchesLanguage);

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
    final dateStr = DateFormatter.toApiDateString(event.date);
    final lang = localStorageService.getLanguage();
    final cacheKey = _cacheKey(dateStr, lang);
    final isToday = dateStr == DateFormatter.toApiDateString(DateTime.now());
    final ttl =
        isToday ? const Duration(seconds: 30) : const Duration(minutes: 5);

    // 1. SWR Instant Memory Cache: If already loaded, show cached data immediately (0ms)
    if (!event.isRefresh && _cachedDateLeagues.containsKey(cacheKey)) {
      final favMatches = localStorageService.getFavoriteMatches();
      final cached = _cachedDateLeagues[cacheKey]!.map((l) {
        return l.copyWith(
          matches: l.matches.map((m) {
            return m.copyWith(isFavorite: favMatches.contains(m.id));
          }).toList(),
        );
      }).toList();
      final liveCount = _calculateLiveCount(cached);
      final filtered = _applyFilters(
        leagues: cached,
        filter: state.activeFilter,
        leagueId: state.selectedLeagueId,
        leagueTitle: state.selectedLeagueTitle,
        sortOrder: state.sortOrder,
        query: state.searchQuery,
      );
      emit(
        state.copyWith(
          status: cached.isEmpty ? MatchesStatus.empty : MatchesStatus.success,
          allLeagues: cached,
          filteredLeagues: filtered,
          selectedDate: event.date,
          liveMatchesCount: liveCount,
          errorMessage: null,
        ),
      );

      // Prewarm adjacent days around this date in background
      _preloadAdjacentDates(event.date);

      final cachedTime = _cachedDateTimes[cacheKey];
      final isFresh =
          cachedTime != null && DateTime.now().difference(cachedTime) < ttl;

      if (isFresh) {
        if (event.completer != null && !event.completer!.isCompleted) {
          event.completer!.complete();
        }
        return;
      }
    } else if (!event.isRefresh) {
      emit(
        state.copyWith(
          status: MatchesStatus.loading,
          selectedDate: event.date,
          allLeagues: [], // clear stale data → skeleton shows
          filteredLeagues: [],
        ),
      );
    }

    try {
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
          final favMatches = localStorageService.getFavoriteMatches();
          final populatedWithFavs = leagues.map((l) {
            return l.copyWith(
              matches: l.matches.map((m) {
                return m.copyWith(isFavorite: favMatches.contains(m.id));
              }).toList(),
            );
          }).toList();

          // Update in-memory date cache
          _cachedDateLeagues[cacheKey] = populatedWithFavs;
          _cachedDateTimes[cacheKey] = DateTime.now();

          final reconciledLeagues =
              RealtimeMergeEngine.reconcileRestLeaguesWithRealtime(
            restLeagues: populatedWithFavs,
            currentLeagues: state.allLeagues,
          ).map((l) {
            return l.copyWith(
              matches: l.matches.map((m) {
                return m.copyWith(isFavorite: favMatches.contains(m.id));
              }).toList(),
            );
          }).toList();

          final liveCount = _calculateLiveCount(reconciledLeagues);
          final filtered = _applyFilters(
            leagues: reconciledLeagues,
            filter: state.activeFilter,
            leagueId: state.selectedLeagueId,
            leagueTitle: state.selectedLeagueTitle,
            sortOrder: state.sortOrder,
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
          _syncLiveRoomsAndPoller();
          MatchNotificationTracker.instance.processLeagues(reconciledLeagues);

          // Silently pre-warm adjacent days in background for instant swipes
          _preloadAdjacentDates(event.date);
        },
        onFailure: (failure) {
          if (failure.statusCode == 404 ||
              failure.message.contains('لا توجد مباريات') ||
              failure.message.toLowerCase().contains('no matches') ||
              failure.message.toLowerCase().contains('not found')) {
            _cachedDateLeagues[cacheKey] = [];
            _cachedDateTimes[cacheKey] = DateTime.now();
            emit(
              state.copyWith(
                status: MatchesStatus.empty,
                allLeagues: [],
                filteredLeagues: [],
                selectedDate: event.date,
                liveMatchesCount: 0,
                errorMessage: null,
              ),
            );
            return;
          }

          // If we already have cached data displayed, don't clobber it with an error screen on silent revalidation
          if (!_cachedDateLeagues.containsKey(cacheKey)) {
            emit(
              state.copyWith(
                status: MatchesStatus.error,
                errorMessage: failure.message,
              ),
            );
          }
        },
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Timer? _preloadDebounceTimer;
  int _preloadSessionId = 0;

  /// Silently preheats immediate adjacent dates ([D-1, D+1]) in the background.
  /// Debounced by 600ms so fast user interactions or date changes don't spam the network or starve the UI isolate.
  void _preloadAdjacentDates(DateTime centerDate) {
    _preloadDebounceTimer?.cancel();
    final currentSession = ++_preloadSessionId;

    _preloadDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (isClosed || currentSession != _preloadSessionId) return;
      _silentBackgroundPreload([
        DateTime(centerDate.year, centerDate.month, centerDate.day - 1),
        DateTime(centerDate.year, centerDate.month, centerDate.day + 1),
      ], currentSession);
    });
  }

  /// Silently pre-warms the cache in a detached background asynchronous task.
  /// Does NOT block the Bloc's event loop queue, guaranteeing instantaneous UI responsiveness.
  void _silentBackgroundPreload(List<DateTime> dates, [int? sessionId]) {
    final activeSession = sessionId ?? _preloadSessionId;
    unawaited(() async {
      final lang = localStorageService.getLanguage();
      final offset = localStorageService.getTimezoneOffset();
      final now = DateTime.now();
      final todayStr = DateFormatter.toApiDateString(now);

      for (final date in dates) {
        if (isClosed || activeSession != _preloadSessionId) return;
        final dateStr = DateFormatter.toApiDateString(date);
        final cacheKey = _cacheKey(dateStr, lang);

        final isToday = dateStr == todayStr;
        final ttl =
            isToday ? const Duration(seconds: 30) : const Duration(minutes: 5);

        final cachedTime = _cachedDateTimes[cacheKey];
        final isFresh =
            cachedTime != null && DateTime.now().difference(cachedTime) < ttl;
        if (isFresh) continue;

        try {
          final result = await repository.getMatchesByDate(
            date: dateStr,
            lang: lang,
            utcOffset: offset,
          );
          if (isClosed || activeSession != _preloadSessionId) return;
          result.fold(
            onSuccess: (leagues) {
              final favMatches = localStorageService.getFavoriteMatches();
              final populated = leagues.map((l) {
                return l.copyWith(
                  matches: l.matches.map((m) {
                    return m.copyWith(isFavorite: favMatches.contains(m.id));
                  }).toList(),
                );
              }).toList();
              _cachedDateLeagues[cacheKey] = populated;
              _cachedDateTimes[cacheKey] = DateTime.now();
            },
            onFailure: (_) {},
          );
        } catch (_) {}

        // Slight stagger to avoid flooding network
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }());
  }

  /// Silently pre-warms the cache for [event.dates] without blocking the UI or event queue.
  Future<void> _onPreloadMatches(
    PreloadMatchesEvent event,
    Emitter<MatchesState> emit,
  ) async {
    _silentBackgroundPreload(event.dates);
  }

  /// Returns in-memory cached leagues for [date] if available, or null.
  List<LeagueGroupEntity>? getCachedLeaguesForDate(DateTime date) {
    final dateStr = DateFormatter.toApiDateString(date);
    final lang = localStorageService.getLanguage();
    final cacheKey = _cacheKey(dateStr, lang);
    return _cachedDateLeagues[cacheKey];
  }

  /// Returns filtered leagues for [date] with current active filters applied, or null.
  List<LeagueGroupEntity>? getFilteredLeaguesForDate(DateTime date) {
    final dateStr = DateFormatter.toApiDateString(date);
    final lang = localStorageService.getLanguage();
    final filterKey =
        '$dateStr-$lang-${state.activeFilter.name}-${state.sortOrder.name}-${state.selectedLeagueId ?? ""}-${state.searchQuery}';

    final cachedFiltered = _cachedFilteredDateLeagues[filterKey];
    if (cachedFiltered != null) return cachedFiltered;

    final cached = getCachedLeaguesForDate(date);
    if (cached == null) return null;

    final filtered = _applyFilters(
      leagues: cached,
      filter: state.activeFilter,
      leagueId: state.selectedLeagueId,
      leagueTitle: state.selectedLeagueTitle,
      sortOrder: state.sortOrder,
      query: state.searchQuery,
    );
    _cachedFilteredDateLeagues[filterKey] = filtered;
    return filtered;
  }

  void _onChangeFilter(ChangeFilterEvent event, Emitter<MatchesState> emit) {
    unawaited(localStorageService.setMatchesFilter(event.filter.name));

    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: event.filter,
      leagueId: state.selectedLeagueId,
      leagueTitle: state.selectedLeagueTitle,
      sortOrder: state.sortOrder,
      query: state.searchQuery,
    );

    emit(state.copyWith(activeFilter: event.filter, filteredLeagues: filtered));
  }

  void _onApplyMatchesFilter(
    ApplyMatchesFilterEvent event,
    Emitter<MatchesState> emit,
  ) {
    final nextFilter = event.filter ?? state.activeFilter;
    final nextLeagueId = event.leagueId ?? state.selectedLeagueId;
    final nextLeagueTitle = event.leagueTitle ?? state.selectedLeagueTitle;
    final nextSortOrder = event.sortOrder ?? state.sortOrder;
    final nextHideFavorites = event.hideFavorites ?? state.hideFavorites;

    unawaited(localStorageService.setMatchesFilter(nextFilter.name));
    unawaited(localStorageService.setMatchesSortOrder(nextSortOrder.name));
    unawaited(localStorageService.setHideFavorites(nextHideFavorites));

    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: nextFilter,
      leagueId: nextLeagueId,
      leagueTitle: nextLeagueTitle,
      sortOrder: nextSortOrder,
      hideFavorites: nextHideFavorites,
      query: state.searchQuery,
    );

    emit(
      state.copyWith(
        activeFilter: nextFilter,
        selectedLeagueId: nextLeagueId,
        clearSelectedLeague: nextLeagueId == null,
        selectedLeagueTitle: nextLeagueTitle,
        sortOrder: nextSortOrder,
        hideFavorites: nextHideFavorites,
        filteredLeagues: filtered,
      ),
    );
  }

  void _onResetMatchesFilter(
    ResetMatchesFilterEvent event,
    Emitter<MatchesState> emit,
  ) {
    unawaited(localStorageService.setMatchesFilter(MatchFilterType.all.name));
    unawaited(
      localStorageService
          .setMatchesSortOrder(MatchesSortOrder.championship.name),
    );
    unawaited(localStorageService.setHideFavorites(false));

    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: MatchFilterType.all,
      leagueId: null,
      leagueTitle: null,
      sortOrder: MatchesSortOrder.championship,
      hideFavorites: false,
      query: state.searchQuery,
    );

    emit(
      state.copyWith(
        activeFilter: MatchFilterType.all,
        clearSelectedLeague: true,
        sortOrder: MatchesSortOrder.championship,
        hideFavorites: false,
        filteredLeagues: filtered,
      ),
    );
  }

  void _onSearchMatches(SearchMatchesEvent event, Emitter<MatchesState> emit) {
    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: state.activeFilter,
      leagueId: state.selectedLeagueId,
      leagueTitle: state.selectedLeagueTitle,
      sortOrder: state.sortOrder,
      query: event.query,
    );

    emit(state.copyWith(searchQuery: event.query, filteredLeagues: filtered));
  }

  ({Set<String> ids, Set<String> names}) _extractFavTeamData(
    List<String> favTeams,
  ) {
    final ids = <String>{};
    final names = <String>{};
    for (final t in favTeams) {
      final clean = t.trim();
      if (clean.isEmpty) continue;
      if (int.tryParse(clean) != null) {
        ids.add(clean.toLowerCase());
      } else {
        final knownId =
            LocalStorageServiceImpl.knownTeamNameToId[clean.toLowerCase()] ??
                LocalStorageServiceImpl.knownTeamNameToId[clean];
        if (knownId != null) {
          ids.add(knownId.toLowerCase());
        } else {
          names.add(clean.toLowerCase());
          final key = TeamResolver.getCanonicalKey(clean);
          if (key != null && key.isNotEmpty) {
            names.add(key.toLowerCase());
          }
        }
      }
    }
    return (ids: ids, names: names);
  }

  bool _isMatchFavoriteFast(
    MatchEntity match,
    Set<String> favMatchesSet,
    Set<String> favTeamIds,
    Set<String> favTeamNames,
  ) {
    if (favMatchesSet.contains(match.id)) return true;
    if (favTeamIds.isEmpty && favTeamNames.isEmpty) return false;

    // 1. Strict Team ID Matching (High Priority)
    final t1Id = match.team1Id?.trim().toLowerCase();
    final hasT1Id = t1Id != null && t1Id.isNotEmpty;
    if (hasT1Id && favTeamIds.contains(t1Id)) return true;

    final t2Id = match.team2Id?.trim().toLowerCase();
    final hasT2Id = t2Id != null && t2Id.isNotEmpty;
    if (hasT2Id && favTeamIds.contains(t2Id)) return true;

    // 2. Strict ID Policy: If match has valid team IDs, DO NOT do ambiguous name matching!
    // This prevents teams with similar names across different leagues (e.g. Al Ahly Egypt 101745 vs Al Ahli Saudi 2530)
    // from falsely marking matches as favorites.
    if (hasT1Id && hasT2Id) {
      return false;
    }

    // 3. Fallback to name matching ONLY if match lacks IDs and we have non-ID favorites
    if (favTeamNames.isNotEmpty) {
      if (!hasT1Id) {
        final t1 = match.team1.trim().toLowerCase();
        if (t1.isNotEmpty && favTeamNames.contains(t1)) return true;
        final key1 = TeamResolver.getCanonicalKey(match.team1);
        if (key1 != null && favTeamNames.contains(key1.toLowerCase()))
          return true;
      }

      if (!hasT2Id) {
        final t2 = match.team2.trim().toLowerCase();
        if (t2.isNotEmpty && favTeamNames.contains(t2)) return true;
        final key2 = TeamResolver.getCanonicalKey(match.team2);
        if (key2 != null && favTeamNames.contains(key2.toLowerCase()))
          return true;
      }
    }

    return false;
  }

  Future<void> _onToggleMatchFavorite(
    ToggleMatchFavoriteEvent event,
    Emitter<MatchesState> emit,
  ) async {
    await localStorageService.toggleFavoriteMatch(event.matchId);
    final favMatches = localStorageService.getFavoriteMatches();
    final favTeams = localStorageService.getFavoriteTeams();
    final favMatchesSet = favMatches.toSet();
    final favTeamData = _extractFavTeamData(favTeams);

    final updatedAll = state.allLeagues.map((league) {
      final updatedMatches = league.matches.map((match) {
        return match.copyWith(
          isFavorite: _isMatchFavoriteFast(
            match,
            favMatchesSet,
            favTeamData.ids,
            favTeamData.names,
          ),
        );
      }).toList();
      return league.copyWith(matches: updatedMatches);
    }).toList();

    final dateStr = DateFormatter.toApiDateString(state.selectedDate);
    final lang = localStorageService.getLanguage();
    final cacheKey = _cacheKey(dateStr, lang);
    if (_cachedDateLeagues.containsKey(cacheKey)) {
      _cachedDateLeagues[cacheKey] = updatedAll;
    }

    final filtered = _applyFilters(
      leagues: updatedAll,
      filter: state.activeFilter,
      leagueId: state.selectedLeagueId,
      leagueTitle: state.selectedLeagueTitle,
      sortOrder: state.sortOrder,
      query: state.searchQuery,
      favMatches: favMatches,
      favTeams: favTeams,
    );

    emit(state.copyWith(allLeagues: updatedAll, filteredLeagues: filtered));
  }

  void _onRefreshFavorites(
    RefreshFavoritesEvent event,
    Emitter<MatchesState> emit,
  ) {
    final favMatches =
        event.favoriteMatches ?? localStorageService.getFavoriteMatches();
    final favTeams =
        event.favoriteTeams ?? localStorageService.getFavoriteTeams();
    final favCompetitions = event.favoriteCompetitions ??
        localStorageService.getFavoriteCompetitions();

    final favMatchesSet = favMatches.toSet();
    final favTeamData = _extractFavTeamData(favTeams);

    final updatedAll = state.allLeagues.map((league) {
      final updatedMatches = league.matches.map((match) {
        return match.copyWith(
          isFavorite: _isMatchFavoriteFast(
            match,
            favMatchesSet,
            favTeamData.ids,
            favTeamData.names,
          ),
        );
      }).toList();
      return league.copyWith(matches: updatedMatches);
    }).toList();

    final dateStr = DateFormatter.toApiDateString(state.selectedDate);
    final lang = localStorageService.getLanguage();
    final cacheKey = _cacheKey(dateStr, lang);
    if (_cachedDateLeagues.containsKey(cacheKey)) {
      _cachedDateLeagues[cacheKey] = updatedAll;
    }

    final filtered = _applyFilters(
      leagues: updatedAll,
      filter: state.activeFilter,
      leagueId: state.selectedLeagueId,
      leagueTitle: state.selectedLeagueTitle,
      sortOrder: state.sortOrder,
      query: state.searchQuery,
      favMatches: favMatches,
      favTeams: favTeams,
      favCompetitions: favCompetitions,
    );

    emit(state.copyWith(allLeagues: updatedAll, filteredLeagues: filtered));
  }

  Future<void> _onChangeTimezone(
    ChangeTimezoneEvent event,
    Emitter<MatchesState> emit,
  ) async {
    await localStorageService.setTimezoneOffset(event.offset);
    _cachedDateLeagues.clear();
    add(LoadMatchesEvent(date: state.selectedDate, isRefresh: true));
  }

  Future<void> _onChangeTimeFormat(
    ChangeTimeFormatEvent event,
    Emitter<MatchesState> emit,
  ) async {
    await localStorageService.setTimeFormat(event.format);
    final filtered = _applyFilters(
      leagues: state.allLeagues,
      filter: state.activeFilter,
      leagueId: state.selectedLeagueId,
      leagueTitle: state.selectedLeagueTitle,
      sortOrder: state.sortOrder,
      query: state.searchQuery,
    );
    emit(
      state.copyWith(
        filteredLeagues: List.from(filtered),
        timeFormat: event.format,
      ),
    );
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
        leagueId: state.selectedLeagueId,
        leagueTitle: state.selectedLeagueTitle,
        sortOrder: state.sortOrder,
        query: state.searchQuery,
      );

      emit(
        state.copyWith(
          allLeagues: mergeResult.data,
          filteredLeagues: filtered,
          liveMatchesCount: liveCount,
        ),
      );
      _syncLiveRoomsAndPoller();
      MatchNotificationTracker.instance.processLeagues(mergeResult.data);
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
      // Re-join active live match rooms on reconnect
      for (final id in _joinedLiveMatchRooms) {
        try {
          webSocketService.joinMatchRoom(id);
        } catch (_) {}
      }
      // Refresh REST snapshot to heal any gap during disconnect
      if (state.status == MatchesStatus.success ||
          state.status == MatchesStatus.empty) {
        add(LoadMatchesEvent(date: state.selectedDate, isRefresh: true));
      }
      _syncLiveRoomsAndPoller();
    } else if (event.status == SocketConnectionState.disconnected ||
        event.status == SocketConnectionState.error) {
      try {
        webSocketService.recordRestFallback(isActive: true);
      } catch (_) {}
      _startFallbackPolling();
      // Immediately accelerate live poller to 3 seconds during socket disconnect
      _startLivePoller(3);
    }
  }

  void _startFallbackPolling() {
    if (_fallbackPollingTimer != null && _fallbackPollingTimer!.isActive) {
      return;
    }

    // Poll every 25 seconds only when disconnected and matches are loaded
    _fallbackPollingTimer = Timer.periodic(const Duration(seconds: 25), (
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

  bool _hasLiveMatchChanged(MatchEntity old, MatchEntity live) {
    if (live.minute != null &&
        live.minute!.isNotEmpty &&
        live.minute != old.minute) {
      return true;
    }
    if (live.status != null &&
        live.status!.isNotEmpty &&
        live.status != old.status) {
      return true;
    }
    if (live.statusCode != null &&
        live.statusCode!.isNotEmpty &&
        live.statusCode != old.statusCode) {
      return true;
    }
    if (live.score1 != null &&
        live.score1!.isNotEmpty &&
        live.score1 != old.score1) {
      return true;
    }
    if (live.score2 != null &&
        live.score2!.isNotEmpty &&
        live.score2 != old.score2) {
      return true;
    }
    if (live.period != null &&
        live.period!.isNotEmpty &&
        live.period != old.period) {
      return true;
    }
    if (live.extraTime != null &&
        live.extraTime!.isNotEmpty &&
        live.extraTime != old.extraTime) {
      return true;
    }
    return false;
  }

  void _onLiveMatchesSnapshotReceived(
    LiveMatchesSnapshotReceivedEvent event,
    Emitter<MatchesState> emit,
  ) {
    if (isClosed) return;
    final liveMatches = event.liveMatches;
    final liveIds = liveMatches
        .map((m) => m.id.replaceAll('match:', '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    // 1. If any match that was previously live is no longer in liveMatches,
    // it likely finished or went to half-time break. Trigger a full refresh
    // to get the authoritative status and final score.
    bool hasEndedMatch = false;
    for (final id in _joinedLiveMatchRooms) {
      if (!liveIds.contains(id)) {
        hasEndedMatch = true;
        break;
      }
    }

    if (hasEndedMatch) {
      add(LoadMatchesEvent(date: state.selectedDate, isRefresh: true));
      return;
    }

    // 2. Check if any active match has changed scores, minute, status, extraTime
    bool anyChanged = false;
    final liveById = <String, MatchEntity>{};
    for (final m in liveMatches) {
      liveById[m.id.replaceAll('match:', '').trim()] = m;
    }

    for (final league in state.allLeagues) {
      for (final match in league.matches) {
        final cleanId = match.id.replaceAll('match:', '').trim();
        MatchEntity? live = liveById[cleanId];
        if (live == null) {
          try {
            live = liveMatches.firstWhere(
              (lm) =>
                  (lm.team1.toLowerCase().contains(match.team1.toLowerCase()) ||
                      match.team1.toLowerCase().contains(
                            lm.team1.toLowerCase(),
                          )) &&
                  (lm.team2.toLowerCase().contains(match.team2.toLowerCase()) ||
                      match.team2.toLowerCase().contains(
                            lm.team2.toLowerCase(),
                          )),
            );
          } catch (_) {
            live = null;
          }
        }
        if (live != null && _hasLiveMatchChanged(match, live)) {
          anyChanged = true;
          break;
        }
      }
      if (anyChanged) break;
    }

    if (anyChanged) {
      final updatedLeagues = _overlayLiveMatches(state.allLeagues, liveMatches);
      final favMatches = localStorageService.getFavoriteMatches();
      final updatedWithFavs = updatedLeagues.map((l) {
        return l.copyWith(
          matches: l.matches.map((m) {
            return m.copyWith(isFavorite: favMatches.contains(m.id));
          }).toList(),
        );
      }).toList();

      final dateStr = DateFormatter.toApiDateString(state.selectedDate);
      final lang = localStorageService.getLanguage();
      final cacheKey = _cacheKey(dateStr, lang);
      _cachedDateLeagues[cacheKey] = updatedWithFavs;

      final liveCount = _calculateLiveCount(updatedWithFavs);
      final filtered = _applyFilters(
        leagues: updatedWithFavs,
        filter: state.activeFilter,
        leagueId: state.selectedLeagueId,
        leagueTitle: state.selectedLeagueTitle,
        sortOrder: state.sortOrder,
        query: state.searchQuery,
      );

      emit(
        state.copyWith(
          allLeagues: updatedWithFavs,
          filteredLeagues: filtered,
          liveMatchesCount: liveCount,
        ),
      );
      _syncLiveRoomsAndPoller();
    }
    // Always process live matches through notification tracker so goal alerts
    // fire immediately regardless of whether the UI state needed an overlay update.
    MatchNotificationTracker.instance.processMatches(liveMatches);

    // Sync active matches with Android Foreground Service for zero-delay delivery
    LiveMatchForegroundService.syncWithMatches(
      matches: liveMatches,
      isLiveMatchModeEnabled: localStorageService.isLiveMatchModeEnabled(),
      favoriteTeamIds: localStorageService.getFavoriteTeams(),
      favoriteMatchIds: [
        ...localStorageService.getFavoriteMatches(),
        ...localStorageService.getMatchNotificationIds(),
      ],
    );
  }

  void _onLivePollTick() async {
    if (isClosed) return;
    final isToday = DateFormatter.isToday(state.selectedDate);
    final hasLive =
        state.liveMatchesCount > 0 || _joinedLiveMatchRooms.isNotEmpty;
    if (!isToday && !hasLive) {
      _stopLivePoller();
      return;
    }

    final lang = localStorageService.getLanguage();
    final offset = localStorageService.getTimezoneOffset();
    final result = await repository.getLiveMatchesFlat(
      lang: lang,
      utcOffset: offset,
    );

    result.fold(
      onSuccess: (liveMatches) {
        if (isClosed) return;
        add(LiveMatchesSnapshotReceivedEvent(liveMatches));
      },
      onFailure: (_) {},
    );
  }

  void _syncLiveRoomsAndPoller() {
    if (isClosed) return;
    final currentLiveIds = <String>{};

    for (final l in state.allLeagues) {
      for (final m in l.matches) {
        final phase = MatchStatusHelper.parseMatch(m);
        if (MatchStatusHelper.isLive(phase) ||
            ScoreHelper.isLiveStatus(m.status)) {
          final clean = m.id.replaceAll('match:', '').trim();
          if (clean.isNotEmpty) {
            currentLiveIds.add(clean);
          }
          if (m.extraTime != null &&
              m.extraTime!.isNotEmpty &&
              m.extraTime != 'null') {}
          final minNum = int.tryParse(
            m.minute?.replaceAll("'", '').trim() ?? '',
          );
          if (minNum != null &&
              ((minNum >= 45 && minNum < 55) || minNum >= 90)) {}
        }
      }
    }

    // Synchronize match rooms with WebSocket backend
    for (final id in currentLiveIds) {
      if (!_joinedLiveMatchRooms.contains(id)) {
        try {
          webSocketService.joinMatchRoom(id);
        } catch (_) {}
        _joinedLiveMatchRooms.add(id);
      }
    }

    final toRemove = <String>[];
    for (final id in _joinedLiveMatchRooms) {
      if (!currentLiveIds.contains(id)) {
        try {
          webSocketService.leaveMatchRoom(id);
        } catch (_) {}
        toRemove.add(id);
      }
    }
    _joinedLiveMatchRooms.removeAll(toRemove);

    const desiredInterval = 30;
    final isToday = DateFormatter.isToday(state.selectedDate);
    final shouldPoll = isToday || currentLiveIds.isNotEmpty;

    if (!shouldPoll) {
      _stopLivePoller();
    } else if (_livePollerTimer == null ||
        !_livePollerTimer!.isActive ||
        _currentPollIntervalSeconds != desiredInterval) {
      _startLivePoller(desiredInterval);
    }
  }

  void _startLivePoller(int seconds) {
    _livePollerTimer?.cancel();
    _currentPollIntervalSeconds = seconds;
    _livePollerTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      _onLivePollTick();
    });
  }

  void _stopLivePoller() {
    _livePollerTimer?.cancel();
    _livePollerTimer = null;
  }

  List<LeagueGroupEntity> _overlayLiveMatches(
    List<LeagueGroupEntity> leagues,
    List<MatchEntity> liveMatches,
  ) {
    if (liveMatches.isEmpty) return leagues;

    final liveById = <String, MatchEntity>{};
    for (final m in liveMatches) {
      liveById[m.id] = m;
    }

    return leagues.map((league) {
      final updatedMatches = league.matches.map((match) {
        MatchEntity? live = liveById[match.id];
        if (live == null) {
          try {
            live = liveMatches.firstWhere(
              (lm) =>
                  (lm.team1.toLowerCase().contains(match.team1.toLowerCase()) ||
                      match.team1.toLowerCase().contains(
                            lm.team1.toLowerCase(),
                          )) &&
                  (lm.team2.toLowerCase().contains(match.team2.toLowerCase()) ||
                      match.team2.toLowerCase().contains(
                            lm.team2.toLowerCase(),
                          )),
            );
          } catch (_) {
            live = null;
          }
        }

        if (live != null) {
          return match.copyWith(
            minute: (live.minute != null && live.minute!.isNotEmpty)
                ? live.minute
                : match.minute,
            status: (live.status != null && live.status!.isNotEmpty)
                ? live.status
                : match.status,
            statusCode: (live.statusCode != null && live.statusCode!.isNotEmpty)
                ? live.statusCode
                : match.statusCode,
            score1: (live.score1 != null && live.score1!.isNotEmpty)
                ? live.score1
                : match.score1,
            score2: (live.score2 != null && live.score2!.isNotEmpty)
                ? live.score2
                : match.score2,
            period: (live.period != null && live.period!.isNotEmpty)
                ? live.period
                : match.period,
            extraTime: (live.extraTime != null && live.extraTime!.isNotEmpty)
                ? live.extraTime
                : match.extraTime,
          );
        }
        return match;
      }).toList();

      return league.copyWith(matches: updatedMatches);
    }).toList();
  }

  int _calculateLiveCount(List<LeagueGroupEntity> leagues) {
    int count = 0;
    for (final l in leagues) {
      for (final m in l.matches) {
        final phase = MatchStatusHelper.parseMatch(m);
        if (MatchStatusHelper.isLive(phase)) {
          count++;
        }
      }
    }
    return count;
  }

  static int _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr == '-') {
      return 99999;
    }

    var s = timeStr.trim();
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(arabicDigits[i], '$i');
    }

    final regExp = RegExp(r'(\d{1,2}):(\d{2})\s*([صم]|AM|PM|am|pm)?');
    final match = regExp.firstMatch(s);
    if (match == null) return 99999;

    int hours = int.tryParse(match.group(1)!) ?? 0;
    final int minutes = int.tryParse(match.group(2)!) ?? 0;
    final String? period = match.group(3)?.toLowerCase();

    if (period == 'م' || period == 'pm') {
      if (hours < 12) hours += 12;
    } else if (period == 'ص' || period == 'am') {
      if (hours == 12) hours = 0;
    }

    return hours * 60 + minutes;
  }

  static bool _isImportantCompetition(String title) {
    final lower = title.toLowerCase();
    const importantKeywords = [
      'أبطال أوروبا',
      'champions league',
      'الدوري الإنجليزي',
      'premier league',
      'الدوري الإسباني',
      'la liga',
      'الدوري الإيطالي',
      'serie a',
      'الدوري الألماني',
      'bundesliga',
      'الدوري الفرنسي',
      'ligue 1',
      'أبطال أفريقيا',
      'أبطال آسيا',
      'caf',
      'afc',
      'الدوري المصري',
      'كأس عاصمة مصر',
      'دوري روشن',
      'الدوري السعودي',
      'كأس العالم',
      'world cup',
      'كأس أمم',
      'كوبا أمريكا',
      'copa america',
      'كأس ملك',
      'كأس الاتحاد',
      'كأس الرابطة',
      'كأس مصر',
      'كأس خادم الحرمين',
      'super cup',
      'السوبر',
    ];
    return importantKeywords.any((kw) => lower.contains(kw));
  }

  bool _isLeagueFav(
    String? title,
    String? id,
    Set<String> favCompetitionsSet,
    List<String> effectiveFavCompetitions,
  ) {
    final cleanTitle = title?.trim().toLowerCase();
    if (cleanTitle != null && favCompetitionsSet.contains(cleanTitle)) {
      return true;
    }
    final cleanId = id?.trim().toLowerCase();
    if (cleanId != null && favCompetitionsSet.contains(cleanId)) {
      return true;
    }
    return effectiveFavCompetitions.any(
      (c) => LeagueResolver.areSameCompetition(c, title, idB: id),
    );
  }

  List<LeagueGroupEntity> _applyFilters({
    required List<LeagueGroupEntity> leagues,
    required MatchFilterType filter,
    required String? leagueId,
    required String? leagueTitle,
    required MatchesSortOrder sortOrder,
    required String query,
    bool? hideFavorites,
    List<String>? favMatches,
    List<String>? favTeams,
    List<String>? favCompetitions,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final effectiveHideFavorites = hideFavorites ?? state.hideFavorites;
    final effectiveFavCompetitions = effectiveHideFavorites
        ? const <String>[]
        : (favCompetitions ?? localStorageService.getFavoriteCompetitions());
    final effectiveFavTeams = effectiveHideFavorites
        ? const <String>[]
        : (favTeams ?? localStorageService.getFavoriteTeams());
    final effectiveFavMatches = effectiveHideFavorites
        ? const <String>[]
        : (favMatches ?? localStorageService.getFavoriteMatches());

    final favMatchesSet = effectiveFavMatches.toSet();
    final favTeamData = _extractFavTeamData(effectiveFavTeams);
    final favCompetitionsSet =
        effectiveFavCompetitions.map((c) => c.trim().toLowerCase()).toSet();

    var result = leagues
        .where((league) {
          // Championship / League Filter
          if (leagueId != null && leagueId.isNotEmpty) {
            final matchesId =
                league.leagueId != null && league.leagueId == leagueId;
            final matchesTitle = leagueTitle != null &&
                leagueTitle.isNotEmpty &&
                league.leagueTitle.trim().toLowerCase() ==
                    leagueTitle.trim().toLowerCase();
            return matchesId || matchesTitle;
          }
          return true;
        })
        .map((league) {
          final isLeagueFavorite = _isLeagueFav(
            league.leagueTitle,
            league.leagueId,
            favCompetitionsSet,
            effectiveFavCompetitions,
          );

          final matches = league.matches.map((match) {
            final isMatchFav = _isMatchFavoriteFast(
              match,
              favMatchesSet,
              favTeamData.ids,
              favTeamData.names,
            );
            return match.copyWith(isFavorite: isMatchFav);
          }).where((match) {
            final phase = MatchStatusHelper.parseMatch(match);

            // Check if match belongs to a favorite league
            final isMatchLeagueFavorite = isLeagueFavorite ||
                _isLeagueFav(
                  match.leagueTitle,
                  match.leagueId,
                  favCompetitionsSet,
                  effectiveFavCompetitions,
                );

            // Apply status filter
            final matchesFilter = switch (filter) {
              MatchFilterType.all => true,
              MatchFilterType.live => MatchStatusHelper.isLive(phase),
              MatchFilterType.upcoming => MatchStatusHelper.isUpcoming(
                  phase,
                ),
              MatchFilterType.finished => MatchStatusHelper.isFinished(
                  phase,
                ),
              MatchFilterType.favorites =>
                isMatchLeagueFavorite || match.isFavorite,
            };

            if (!matchesFilter) return false;

            // Apply search query
            if (cleanQuery.isNotEmpty) {
              final inTeams = match.team1.toLowerCase().contains(cleanQuery) ||
                  match.team2.toLowerCase().contains(cleanQuery);
              final inLeague = (match.leagueTitle ?? league.leagueTitle)
                  .toLowerCase()
                  .contains(cleanQuery);
              return inTeams || inLeague;
            }

            return true;
          }).toList();

          if (sortOrder == MatchesSortOrder.time) {
            // Sort matches: favorites first, then chronologically by kick-off time
            matches.sort((a, b) {
              if (a.isFavorite && !b.isFavorite) return -1;
              if (!a.isFavorite && b.isFavorite) return 1;
              final tA = _parseTimeToMinutes(a.time);
              final tB = _parseTimeToMinutes(b.time);
              return tA.compareTo(tB);
            });
          } else {
            // In Yalla Shoot, matches within each championship are ordered chronologically by kick-off time
            matches.sort((a, b) {
              if (a.isFavorite && !b.isFavorite) return -1;
              if (!a.isFavorite && b.isFavorite) return 1;
              return _parseTimeToMinutes(a.time)
                  .compareTo(_parseTimeToMinutes(b.time));
            });
          }

          return league.copyWith(matches: matches);
        })
        .where((league) => league.matches.isNotEmpty)
        .toList();

    // League Ordering / Grouping
    if (sortOrder == MatchesSortOrder.time) {
      // Flatten all filtered matches preserving their parent league metadata
      final allMatches = <MatchEntity>[];
      for (final league in result) {
        for (final m in league.matches) {
          allMatches.add(
            m.copyWith(
              leagueTitle: m.leagueTitle ?? league.leagueTitle,
              leagueLogo: m.leagueLogo ?? league.leagueLogo,
              leagueId: m.leagueId ?? league.leagueId,
            ),
          );
        }
      }

      // Sort every match: favorites first, then strictly chronologically by kick-off time
      allMatches.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;

        final tA = _parseTimeToMinutes(a.time);
        final tB = _parseTimeToMinutes(b.time);
        if (tA != tB) return tA.compareTo(tB);

        final pA = MatchStatusHelper.getPriority(
          MatchStatusHelper.parseMatch(a),
        );
        final pB = MatchStatusHelper.getPriority(
          MatchStatusHelper.parseMatch(b),
        );
        if (pA != pB) return pA.compareTo(pB);

        return (a.leagueTitle ?? '').compareTo(b.leagueTitle ?? '');
      });

      // Group matches chronologically by kick-off time slot
      final timeGroups = <String, List<MatchEntity>>{};
      for (final match in allMatches) {
        final timeKey = (match.time != null &&
                match.time!.trim().isNotEmpty &&
                match.time != '-')
            ? DateFormatter.formatDisplayTime(
                match.time!,
                timeFormat: localStorageService.getTimeFormat(),
                isArabic: true,
              )
            : 'غير محدد';
        timeGroups.putIfAbsent(timeKey, () => []).add(match);
      }

      return timeGroups.entries.map((entry) {
        return LeagueGroupEntity(leagueTitle: entry.key, matches: entry.value);
      }).toList();
    } else if (sortOrder == MatchesSortOrder.league) {
      // Sort leagues: favorites first, then alphabetically by league title
      result.sort((a, b) {
        final aIsFav = _isLeagueFav(
              a.leagueTitle,
              a.leagueId,
              favCompetitionsSet,
              effectiveFavCompetitions,
            ) ||
            a.matches.any((m) => m.isFavorite);

        final bIsFav = _isLeagueFav(
              b.leagueTitle,
              b.leagueId,
              favCompetitionsSet,
              effectiveFavCompetitions,
            ) ||
            b.matches.any((m) => m.isFavorite);

        if (aIsFav && !bIsFav) return -1;
        if (!aIsFav && bIsFav) return 1;

        return a.leagueTitle.compareTo(b.leagueTitle);
      });
    } else {
      // MatchesSortOrder.championship / MatchesSortOrder.importance / MatchesSortOrder.importantOnly:
      // Favorites first (if not hideFavorites) -> maintain natural API priority order (matching Yalla Shoot)
      final originalIndices = {
        for (int i = 0; i < leagues.length; i++) leagues[i].leagueTitle: i,
      };
      result.sort((a, b) {
        final aIsFav = _isLeagueFav(
              a.leagueTitle,
              a.leagueId,
              favCompetitionsSet,
              effectiveFavCompetitions,
            ) ||
            a.matches.any((m) => m.isFavorite);

        final bIsFav = _isLeagueFav(
              b.leagueTitle,
              b.leagueId,
              favCompetitionsSet,
              effectiveFavCompetitions,
            ) ||
            b.matches.any((m) => m.isFavorite);

        if (aIsFav && !bIsFav) return -1;
        if (!aIsFav && bIsFav) return 1;

        final idxA = originalIndices[a.leagueTitle] ?? 9999;
        final idxB = originalIndices[b.leagueTitle] ?? 9999;
        return idxA.compareTo(idxB);
      });

      if (sortOrder == MatchesSortOrder.importantOnly) {
        result = result.where((league) {
          final isFav = _isLeagueFav(
                league.leagueTitle,
                league.leagueId,
                favCompetitionsSet,
                effectiveFavCompetitions,
              ) ||
              league.matches.any((m) => m.isFavorite);
          if (isFav) return true;
          return _isImportantCompetition(league.leagueTitle);
        }).toList();
      }
    }

    return result;
  }

  Future<void> _onChangeMatchesLanguage(
    ChangeMatchesLanguageEvent event,
    Emitter<MatchesState> emit,
  ) async {
    final targetLang = event.languageCode;
    final dateStr = DateFormatter.toApiDateString(state.selectedDate);
    final targetCacheKey = _cacheKey(dateStr, targetLang);

    final favMatches = localStorageService.getFavoriteMatches();

    // 1. Instant Cache: If target language already cached, display immediately (0ms)
    if (_cachedDateLeagues.containsKey(targetCacheKey)) {
      final cached = _cachedDateLeagues[targetCacheKey]!.map((l) {
        return l.copyWith(
          matches: l.matches.map((m) {
            return m.copyWith(isFavorite: favMatches.contains(m.id));
          }).toList(),
        );
      }).toList();

      final liveCount = _calculateLiveCount(cached);
      final filtered = _applyFilters(
        leagues: cached,
        filter: state.activeFilter,
        leagueId: state.selectedLeagueId,
        leagueTitle: state.selectedLeagueTitle,
        sortOrder: state.sortOrder,
        query: state.searchQuery,
      );

      emit(
        state.copyWith(
          status: cached.isEmpty ? MatchesStatus.empty : MatchesStatus.success,
          allLeagues: cached,
          filteredLeagues: filtered,
          liveMatchesCount: liveCount,
          isLanguageRefreshing: false,
          errorMessage: null,
        ),
      );
      _syncLiveRoomsAndPoller();

      final cachedTime = _cachedDateTimes[targetCacheKey];
      final isFresh = cachedTime != null &&
          DateTime.now().difference(cachedTime) < const Duration(seconds: 30);
      if (isFresh) {
        if (event.completer != null && !event.completer!.isCompleted) {
          event.completer!.complete();
        }
        return;
      }
    } else {
      // 2. Uncached: KEEP CURRENT LEAGUES VISIBLE on screen!
      // Do NOT set MatchesStatus.loading or clear allLeagues.
      emit(state.copyWith(isLanguageRefreshing: true));
    }

    try {
      final offset = localStorageService.getTimezoneOffset();
      final result = await repository.getMatchesByDate(
        date: dateStr,
        lang: targetLang,
        utcOffset: offset,
      );

      // 3. Race condition protection: ensure user hasn't switched away
      final currentAppLang = localStorageService.getLanguage();
      if (currentAppLang != targetLang) {
        return;
      }

      result.fold(
        onSuccess: (leagues) {
          final populatedWithFavs = leagues.map((l) {
            return l.copyWith(
              matches: l.matches.map((m) {
                return m.copyWith(isFavorite: favMatches.contains(m.id));
              }).toList(),
            );
          }).toList();

          _cachedDateLeagues[targetCacheKey] = populatedWithFavs;
          _cachedDateTimes[targetCacheKey] = DateTime.now();

          final reconciledLeagues =
              RealtimeMergeEngine.reconcileRestLeaguesWithRealtime(
            restLeagues: populatedWithFavs,
            currentLeagues: state.allLeagues,
          ).map((l) {
            return l.copyWith(
              matches: l.matches.map((m) {
                return m.copyWith(isFavorite: favMatches.contains(m.id));
              }).toList(),
            );
          }).toList();

          final liveCount = _calculateLiveCount(reconciledLeagues);
          final filtered = _applyFilters(
            leagues: reconciledLeagues,
            filter: state.activeFilter,
            leagueId: state.selectedLeagueId,
            leagueTitle: state.selectedLeagueTitle,
            sortOrder: state.sortOrder,
            query: state.searchQuery,
          );

          emit(
            state.copyWith(
              status: reconciledLeagues.isEmpty
                  ? MatchesStatus.empty
                  : MatchesStatus.success,
              allLeagues: reconciledLeagues,
              filteredLeagues: filtered,
              liveMatchesCount: liveCount,
              isLanguageRefreshing: false,
              errorMessage: null,
            ),
          );
          _syncLiveRoomsAndPoller();
        },
        onFailure: (failure) {
          // Keep existing visible data intact
          emit(state.copyWith(isLanguageRefreshing: false));
        },
      );
    } catch (_) {
      emit(state.copyWith(isLanguageRefreshing: false));
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  @override
  Future<void> close() {
    _preloadDebounceTimer?.cancel();
    _stopLivePoller();
    _stopFallbackPolling();
    for (final id in _joinedLiveMatchRooms) {
      try {
        webSocketService.leaveMatchRoom(id);
      } catch (_) {}
    }
    _joinedLiveMatchRooms.clear();
    _wsSubscription?.cancel();
    _wsStatusSubscription?.cancel();
    return super.close();
  }
}
