import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/match_event_helper.dart';
import '../../../../core/utils/realtime_merge_engine.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../domain/entities/match_details_entity.dart';
import '../../domain/repositories/match_details_repository.dart';
import 'match_details_event.dart';
import 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  final MatchDetailsRepository repository;
  final WebSocketService webSocketService;
  final LocalStorageService localStorageService;

  StreamSubscription? _liveMatchSubscription;
  StreamSubscription? _matchRoomSubscription;
  Timer? _debounceRefreshTimer;
  Timer? _liveFallbackTimer;

  static String _cleanId(String? id) =>
      id?.replaceAll('match:', '').trim() ?? '';

  MatchDetailsBloc({
    required this.repository,
    required this.webSocketService,
    required this.localStorageService,
    required String matchId,
  }) : super(MatchDetailsState(matchId: _cleanId(matchId))) {
    on<LoadMatchDetailsEvent>(_onLoadMatchDetails);
    on<ChangeTabEvent>(_onChangeTab);
    on<LiveMatchDetailUpdateEvent>(_onLiveMatchDetailUpdate);
    on<MatchDetailSocketUpdateEvent>(_onMatchDetailSocketUpdate);

    final cleanTarget = _cleanId(matchId);

    // 1. Join room: match:{matchId}
    try {
      webSocketService.connect();
      webSocketService.joinMatchRoom(cleanTarget);
    } catch (_) {}

    // 2. Listen to dedicated match updates stream
    try {
      final stream = webSocketService.matchUpdatesStream(cleanTarget);
      _matchRoomSubscription = stream.listen((update) {
        add(MatchDetailSocketUpdateEvent(update));
      });
    } catch (_) {}

    // 3. Listen to general live matches stream for match updates
    try {
      _liveMatchSubscription = webSocketService.updatesStream.listen((update) {
        if (_cleanId(update.matchId) == cleanTarget) {
          add(LiveMatchDetailUpdateEvent(update));
        }
      });
    } catch (_) {}

    // 4. Background fallback periodic refresh every 25 seconds for live matches
    final isInTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isInTest) {
      _liveFallbackTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (!isClosed) {
          add(LoadMatchDetailsEvent(state.matchId, isRefresh: true));
        }
      });
    }
  }

  Future<void> _onLoadMatchDetails(
    LoadMatchDetailsEvent event,
    Emitter<MatchDetailsState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: MatchDetailsStatus.loading));
    }

    final lang = localStorageService.getLanguage();
    final offset = localStorageService.getTimezoneOffset();

    try {
      final eventsFuture = repository.getEvents(event.matchId, lang: lang);
      final statsFuture = repository.getStats(event.matchId, lang: lang);
      final detailsFuture = repository.getDetails(
        event.matchId,
        lang: lang,
        utcOffset: offset,
      );
      final newsFuture = repository.getNews(event.matchId, lang: lang);
      Future<ApiResult<MatchLineupEntity?>>? lineupsFuture;
      try {
        lineupsFuture = repository.getLineups(event.matchId, lang: lang);
      } catch (_) {
        lineupsFuture = null;
      }

      final eventsRes = (await eventsFuture).dataOrNull ?? [];
      final statsRes = (await statsFuture).dataOrNull ?? [];
      final detailsRes = (await detailsFuture).dataOrNull ?? [];
      final newsRes = (await newsFuture).dataOrNull ?? [];
      MatchLineupEntity? lineupsRes;
      if (lineupsFuture != null) {
        try {
          lineupsRes = (await lineupsFuture).dataOrNull;
        } catch (_) {
          lineupsRes = null;
        }
      }

      emit(
        state.copyWith(
          status: MatchDetailsStatus.success,
          events: eventsRes,
          stats: statsRes,
          details: detailsRes,
          news: newsRes,
          lineup: lineupsRes,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MatchDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<MatchDetailsState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  void _onLiveMatchDetailUpdate(
    LiveMatchDetailUpdateEvent event,
    Emitter<MatchDetailsState> emit,
  ) {
    final update = event.update;
    if (update.matchId != null && _cleanId(update.matchId) == _cleanId(state.matchId)) {
      List<MatchEventEntity> updatedEvents = state.events;
      if (update.eventType != null && update.eventType!.isNotEmpty) {
        final newEvent = MatchEventEntity(
          minute: update.minute ?? '',
          type: update.eventType!,
          playerName: update.playerName ?? '',
          score: (update.score1 != null && update.score2 != null)
              ? '${update.score1} - ${update.score2}'
              : null,
          isHomeTeam:
              update.rawPayload['is_home'] == true ||
              update.rawPayload['team'] == '1' ||
              update.rawPayload['team'] == 'home',
          videoUrl: update.rawPayload['video_url']?.toString() ??
              update.rawPayload['videoUrl']?.toString() ??
              update.rawPayload['video']?.toString(),
        );
        updatedEvents = MatchEventHelper.mergeEvents(
          existingEvents: state.events,
          incomingEvents: [newEvent],
        );
      }

      emit(
        state.copyWith(
          liveScore1: update.score1 ?? state.liveScore1,
          liveScore2: update.score2 ?? state.liveScore2,
          liveStatus: update.status ?? state.liveStatus,
          liveMinute: update.minute ?? state.liveMinute,
          liveExtraTime: update.extraTime ?? state.liveExtraTime,
          livePeriod: update.period ?? state.livePeriod,
          events: updatedEvents,
        ),
      );

      _triggerBackgroundRefresh();
    }
  }

  void _onMatchDetailSocketUpdate(
    MatchDetailSocketUpdateEvent event,
    Emitter<MatchDetailsState> emit,
  ) {
    final update = event.update;
    if (_cleanId(update.matchId) == _cleanId(state.matchId)) {
      final mergeResult = RealtimeMergeEngine.mergeMatchDetailsEvents(
        existingEvents: state.events,
        update: update,
      );

      emit(
        state.copyWith(
          liveScore1: update.score1 ?? state.liveScore1,
          liveScore2: update.score2 ?? state.liveScore2,
          liveStatus: update.status ?? state.liveStatus,
          liveMinute: update.minute ?? state.liveMinute,
          liveExtraTime: update.extraTime ?? state.liveExtraTime,
          livePeriod: update.period ?? state.livePeriod,
          events: mergeResult.isUpdated ? mergeResult.data : state.events,
        ),
      );

      _triggerBackgroundRefresh();
    }
  }

  void _triggerBackgroundRefresh() {
    _debounceRefreshTimer?.cancel();
    _debounceRefreshTimer = Timer(const Duration(milliseconds: 600), () {
      if (!isClosed) {
        add(LoadMatchDetailsEvent(state.matchId, isRefresh: true));
      }
    });
  }

  @override
  Future<void> close() {
    _debounceRefreshTimer?.cancel();
    _liveFallbackTimer?.cancel();
    try {
      webSocketService.leaveMatchRoom(state.matchId);
    } catch (_) {}
    _liveMatchSubscription?.cancel();
    _matchRoomSubscription?.cancel();
    return super.close();
  }
}
