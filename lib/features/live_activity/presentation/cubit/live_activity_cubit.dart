import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/domain/repositories/matches_repository.dart';
import '../../domain/repositories/live_activity_repository.dart';
import 'live_activity_state.dart';

class LiveActivityCubit extends Cubit<LiveActivityState> {
  final LiveActivityRepository _repository;
  final MatchesRepository? _matchesRepository;
  final LocalStorageService? _localStorage;
  final WebSocketService? _webSocketService;

  StreamSubscription<String>? _trackingStoppedSubscription;
  StreamSubscription<LiveMatchUpdate>? _wsSubscription;
  Timer? _autoRefreshTimer;
  final Map<String, MatchEntity> _trackedMatchesCache = {};

  LiveActivityCubit({
    required LiveActivityRepository repository,
    MatchesRepository? matchesRepository,
    LocalStorageService? localStorage,
    WebSocketService? webSocketService,
  })  : _repository = repository,
        _matchesRepository = matchesRepository,
        _localStorage = localStorage,
        _webSocketService = webSocketService,
        super(const LiveActivityState()) {
    _init();
  }

  Future<void> _init() async {
    final supported = await _repository.areActivitiesSupported();
    final activeIds = await _repository.getActiveTrackedMatchIds();
    final savedIds = _localStorage?.getTrackedLiveMatchIds() ?? [];
    final combinedIds = {...activeIds, ...savedIds};

    emit(state.copyWith(
      isSupported: supported,
      trackedMatchIds: combinedIds,
    ));

    _trackingStoppedSubscription =
        _repository.onTrackingStoppedStream.listen((matchId) {
      final clean = matchId.replaceAll('match:', '').trim();
      final updated = Set<String>.from(state.trackedMatchIds)..remove(clean);
      _trackedMatchesCache.remove(clean);
      _localStorage?.setTrackedLiveMatchIds(updated.toList());
      emit(state.copyWith(trackedMatchIds: updated));
      if (updated.isEmpty) {
        _stopAutoRefreshTimer();
      }
    });

    if (_webSocketService != null) {
      _wsSubscription = _webSocketService.liveMatchesStream.listen(_onWebSocketUpdate);
    }
    if (Platform.isAndroid) {
      try {
        FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
      } catch (_) {}
    }

    if (combinedIds.isNotEmpty) {
      _startAutoRefreshTimer();
    }
  }

  Future<void> checkSupport() async {
    final supported = await _repository.areActivitiesSupported();
    emit(state.copyWith(isSupported: supported));
  }

  Future<void> loadActiveActivities() async {
    final activeIds = await _repository.getActiveTrackedMatchIds();
    emit(state.copyWith(trackedMatchIds: activeIds.toSet()));
  }

  Future<bool> startTracking({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
  }) async {
    emit(state.copyWith(status: LiveActivityStatus.loading));
    final cleanId = match.id.replaceAll('match:', '').trim();
    _trackedMatchesCache[cleanId] = match;

    final result = await _repository.startTrackingMatch(
      match: match,
      liveScore1: liveScore1,
      liveScore2: liveScore2,
      liveMinute: liveMinute,
      liveStatus: liveStatus,
      liveStatusCode: liveStatusCode,
      livePeriod: livePeriod,
    );

    if (result is ApiSuccess) {
      final updated = Set<String>.from(state.trackedMatchIds)..add(cleanId);
      await _localStorage?.setTrackedLiveMatchIds(updated.toList());
      emit(state.copyWith(
        status: LiveActivityStatus.success,
        trackedMatchIds: updated,
      ));
      _startAutoRefreshTimer();
      return true;
    } else if (result is ApiFailure) {
      emit(state.copyWith(
        status: LiveActivityStatus.failure,
        errorMessage: (result as ApiFailure).failure.message,
      ));
      return false;
    }
    return false;
  }

  Future<void> updateTracking({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
    String? penaltyScore1,
    String? penaltyScore2,
  }) async {
    final cleanId = match.id.replaceAll('match:', '').trim();
    if (!state.trackedMatchIds.contains(cleanId)) return;
    _trackedMatchesCache[cleanId] = match;

    await _repository.updateTrackingMatch(
      match: match,
      liveScore1: liveScore1,
      liveScore2: liveScore2,
      liveMinute: liveMinute,
      liveStatus: liveStatus,
      liveStatusCode: liveStatusCode,
      livePeriod: livePeriod,
      penaltyScore1: penaltyScore1,
      penaltyScore2: penaltyScore2,
    );
  }

  Future<bool> stopTracking(String matchId) async {
    emit(state.copyWith(status: LiveActivityStatus.loading));
    final cleanId = matchId.replaceAll('match:', '').trim();
    _trackedMatchesCache.remove(cleanId);

    final result = await _repository.stopTrackingMatch(cleanId);
    if (result is ApiSuccess) {
      final updated = Set<String>.from(state.trackedMatchIds)..remove(cleanId);
      await _localStorage?.setTrackedLiveMatchIds(updated.toList());
      emit(state.copyWith(
        status: LiveActivityStatus.success,
        trackedMatchIds: updated,
      ));
      if (updated.isEmpty) {
        _stopAutoRefreshTimer();
      }
      return true;
    } else if (result is ApiFailure) {
      emit(state.copyWith(
        status: LiveActivityStatus.failure,
        errorMessage: (result as ApiFailure).failure.message,
      ));
      return false;
    }
    return false;
  }

  Future<bool> toggleTracking({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
  }) async {
    final cleanId = match.id.replaceAll('match:', '').trim();
    if (state.isTracking(cleanId)) {
      return await stopTracking(cleanId);
    } else {
      return await startTracking(
        match: match,
        liveScore1: liveScore1,
        liveScore2: liveScore2,
        liveMinute: liveMinute,
        liveStatus: liveStatus,
        liveStatusCode: liveStatusCode,
        livePeriod: livePeriod,
      );
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshTrackedMatches();
    });
  }

  void _stopAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _refreshTrackedMatches() async {
    if (state.trackedMatchIds.isEmpty || _matchesRepository == null) {
      _stopAutoRefreshTimer();
      return;
    }

    try {
      final lang = _localStorage?.getLanguage() ?? 'ar';
      final liveResult = await _matchesRepository.getLiveMatchesFlat(lang: lang);

      final liveMatchesMap = <String, MatchEntity>{};
      if (liveResult is ApiSuccess<List<MatchEntity>>) {
        for (final m in liveResult.data) {
          final cid = m.id.replaceAll('match:', '').trim();
          liveMatchesMap[cid] = m;
        }
      }

      for (final trackedId in state.trackedMatchIds) {
        if (liveMatchesMap.containsKey(trackedId)) {
          final liveMatch = liveMatchesMap[trackedId]!;
          _trackedMatchesCache[trackedId] = liveMatch;
          await updateTracking(
            match: liveMatch,
            liveScore1: liveMatch.score1,
            liveScore2: liveMatch.score2,
            liveMinute: liveMatch.minute,
            liveStatus: liveMatch.status,
            liveStatusCode: liveMatch.statusCode,
            livePeriod: liveMatch.period,
            penaltyScore1: liveMatch.penaltyScore1,
            penaltyScore2: liveMatch.penaltyScore2,
          );
        } else {
          // If match is not in live flat list (e.g. upcoming or just finished), query by today's date
          final now = DateTime.now();
          final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final todayResult = await _matchesRepository.getMatchesByDate(
            date: dateStr,
            lang: lang,
          );
          if (todayResult is ApiSuccess<List<LeagueGroupEntity>>) {
            for (final group in todayResult.data) {
              for (final m in group.matches) {
                if (m.id.replaceAll('match:', '').trim() == trackedId) {
                  _trackedMatchesCache[trackedId] = m;
                  await updateTracking(
                    match: m,
                    liveScore1: m.score1,
                    liveScore2: m.score2,
                    liveMinute: m.minute,
                    liveStatus: m.status,
                    liveStatusCode: m.statusCode,
                    livePeriod: m.period,
                    penaltyScore1: m.penaltyScore1,
                    penaltyScore2: m.penaltyScore2,
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  void _onWebSocketUpdate(LiveMatchUpdate event) {
    if (state.trackedMatchIds.isEmpty) return;
    final matchId = event.matchId?.replaceAll('match:', '').trim();
    if (matchId == null || !state.trackedMatchIds.contains(matchId)) return;

    final cached = _trackedMatchesCache[matchId];
    if (cached != null) {
      final updated = cached.copyWith(
        score1: event.score1 ?? cached.score1,
        score2: event.score2 ?? cached.score2,
        minute: event.minute ?? cached.minute,
        status: event.status ?? cached.status,
        statusCode: event.statusCode ?? cached.statusCode,
        period: event.period ?? cached.period,
      );
      _trackedMatchesCache[matchId] = updated;
      updateTracking(
        match: updated,
        liveScore1: event.score1,
        liveScore2: event.score2,
        liveMinute: event.minute,
        liveStatus: event.status,
        liveStatusCode: event.statusCode,
        livePeriod: event.period,
      );
    }
  }

  void _onForegroundTaskData(dynamic data) {
    if (data is Map && data['type'] == 'tracked_matches_update') {
      final list = data['matches'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            final id = item['id']?.toString().replaceAll('match:', '').trim();
            if (id != null && state.trackedMatchIds.contains(id)) {
              final cached = _trackedMatchesCache[id];
              if (cached != null) {
                final updated = cached.copyWith(
                  score1: item['score1']?.toString() ?? cached.score1,
                  score2: item['score2']?.toString() ?? cached.score2,
                  minute: item['minute']?.toString() ?? cached.minute,
                  status: item['status']?.toString() ?? cached.status,
                  statusCode: item['statusCode']?.toString() ?? cached.statusCode,
                  period: item['period']?.toString() ?? cached.period,
                  penaltyScore1: item['penaltyScore1']?.toString() ?? cached.penaltyScore1,
                  penaltyScore2: item['penaltyScore2']?.toString() ?? cached.penaltyScore2,
                );
                _trackedMatchesCache[id] = updated;
                updateTracking(
                  match: updated,
                  liveScore1: item['score1']?.toString(),
                  liveScore2: item['score2']?.toString(),
                  liveMinute: item['minute']?.toString(),
                  liveStatus: item['status']?.toString(),
                  liveStatusCode: item['statusCode']?.toString(),
                  livePeriod: item['period']?.toString(),
                  penaltyScore1: item['penaltyScore1']?.toString(),
                  penaltyScore2: item['penaltyScore2']?.toString(),
                );
              }
            }
          }
        }
      }
    }
  }

  @override
  Future<void> close() {
    _stopAutoRefreshTimer();
    _trackingStoppedSubscription?.cancel();
    _wsSubscription?.cancel();
    if (Platform.isAndroid) {
      try {
        FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
      } catch (_) {}
    }
    return super.close();
  }
}
