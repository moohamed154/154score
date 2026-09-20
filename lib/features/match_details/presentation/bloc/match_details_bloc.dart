import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/match_event_helper.dart';
import '../../../../core/utils/realtime_merge_engine.dart';
import '../../../../core/utils/score_helper.dart';
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
    final cleanTarget = _cleanId(event.matchId.isNotEmpty ? event.matchId : state.matchId);

    if (!event.isRefresh) {
      emit(state.copyWith(
        status: MatchDetailsStatus.loading,
        matchId: cleanTarget,
        videos: const MatchVideosEntity(),
      ));
    }

    final lang = localStorageService.getLanguage();
    final offset = localStorageService.getTimezoneOffset();

    try {
      Future<ApiResult<MatchEventsPayload>>? eventsFuture;
      try {
        eventsFuture = repository.getEventsPayload(cleanTarget, lang: lang);
      } catch (_) {
        eventsFuture = null;
      }

      final statsFuture = repository.getStats(cleanTarget, lang: lang);
      Future<ApiResult<MatchDetailsPayload>>? detailsFuture;
      try {
        detailsFuture = repository.getDetailsPayload(
          cleanTarget,
          lang: lang,
          utcOffset: offset,
        );
      } catch (_) {
        detailsFuture = null;
      }

      final newsFuture = repository.getNews(cleanTarget, lang: lang);
      Future<ApiResult<MatchLineupEntity?>>? lineupsFuture;
      try {
        lineupsFuture = repository.getLineups(cleanTarget, lang: lang);
      } catch (_) {
        lineupsFuture = null;
      }

      MatchEventsPayload? eventsPayloadRes;
      if (eventsFuture != null) {
        try {
          eventsPayloadRes = (await eventsFuture).dataOrNull;
        } catch (_) {
          eventsPayloadRes = null;
        }
      }

      if (eventsPayloadRes == null) {
        try {
          final fallbackEvents = (await repository.getEvents(
            cleanTarget,
            lang: lang,
          )).dataOrNull ?? [];
          eventsPayloadRes = MatchEventsPayload(events: fallbackEvents);
        } catch (_) {
          eventsPayloadRes = const MatchEventsPayload();
        }
      }

      final eventsRes = eventsPayloadRes.events;
      final videosRes = eventsPayloadRes.videos;
      final statsRes = (await statsFuture).dataOrNull ?? [];

      MatchDetailsPayload? detailsPayload;
      if (detailsFuture != null) {
        try {
          detailsPayload = (await detailsFuture).dataOrNull;
        } catch (_) {
          detailsPayload = null;
        }
      }

      if (detailsPayload == null) {
        try {
          final fallbackSections = (await repository.getDetails(
            cleanTarget,
            lang: lang,
            utcOffset: offset,
          )).dataOrNull ?? [];
          detailsPayload = MatchDetailsPayload(sections: fallbackSections);
        } catch (_) {
          detailsPayload = const MatchDetailsPayload();
        }
      }

      final detailsRes = detailsPayload.sections;
      final overviewRes = detailsPayload.overview;
      final newsRes = (await newsFuture).dataOrNull ?? [];
      MatchLineupEntity? lineupsRes;
      if (lineupsFuture != null) {
        try {
          lineupsRes = (await lineupsFuture).dataOrNull;
        } catch (_) {
          lineupsRes = null;
        }
      }

      final resolvedHalfScores =
          eventsPayloadRes.halfScores ?? state.halfScores;
      final rawEvents = eventsRes.isNotEmpty ? eventsRes : state.events;
      final resolvedEvents = MatchEventHelper.normalizeEvents(
        rawEvents,
        hasExtraTime: MatchEventHelper.hasExtraTimeInHalfScores(resolvedHalfScores),
      );
      final resolvedVideos = videosRes.isNotEmpty ? videosRes : state.videos;
      final resolvedStats = statsRes.isNotEmpty ? statsRes : state.stats;
      final resolvedDetails = detailsRes.isNotEmpty ? detailsRes : state.details;
      final resolvedOverview = overviewRes ?? state.overview;
      final resolvedNews = newsRes.isNotEmpty ? newsRes : state.news;
      final rawLineup = lineupsRes ?? state.lineup;
      final resolvedLineup = _enrichLineupWithEvents(rawLineup, resolvedEvents);
      final resolvedChampionshipId =
          eventsPayloadRes.championshipId ??
          resolvedOverview?.championshipId ??
          state.championshipId;

      String? calculatedScore1 = state.liveScore1;
      String? calculatedScore2 = state.liveScore2;
      if ((calculatedScore1 == null || calculatedScore2 == null) && resolvedEvents.isNotEmpty) {
        int g1 = 0;
        int g2 = 0;
        bool hasGoals = false;
        for (final ev in resolvedEvents) {
          if (ev.type.toLowerCase().contains('goal')) {
            hasGoals = true;
            if (ev.isHomeTeam) {
              g1++;
            } else {
              g2++;
            }
          }
        }
        if (hasGoals) {
          calculatedScore1 ??= g1.toString();
          calculatedScore2 ??= g2.toString();
        }
      }
      calculatedScore1 ??= resolvedOverview?.score1;
      calculatedScore2 ??= resolvedOverview?.score2;

      String? resolvedStatus = state.liveStatus ?? resolvedOverview?.status;
      String? resolvedStatusCode = state.liveStatusCode;

      final hasFinishedEvent = resolvedEvents.any((e) {
        if (!e.isPeriodMarker) return false;
        final name = e.playerName.trim().toLowerCase();
        // Exclude first half, half time, or start markers
        if (name.contains('الأول') ||
            name.contains('اول') ||
            name.contains('1st') ||
            name.contains('half time') ||
            name.contains('halftime') ||
            name.contains('ht') ||
            name.contains('استراحة') ||
            name.contains('بداية')) {
          return false;
        }
        return name == 'نهاية المباراة' ||
            name == 'نهاية اللقاء' ||
            name.contains('نهاية المباراة') ||
            name.contains('نهاية اللقاء') ||
            name.contains('نهاية الوقت الأصلي واللقاء') ||
            name.contains('نهاية الشوط الإضافي الثاني') ||
            name == 'full time' ||
            name == 'ft' ||
            name.contains('full time') ||
            name.contains('full-time') ||
            name == 'match finished' ||
            name.contains('match finished');
      });

      final isCurrentlyLive = ScoreHelper.isLiveStatus(resolvedStatus) ||
          ScoreHelper.isLiveStatus(state.liveStatus) ||
          (resolvedStatusCode != null &&
              (resolvedStatusCode == 'LIVE' ||
               resolvedStatusCode.startsWith('IN_PLAY') ||
               resolvedStatusCode == 'HALF_TIME' ||
               resolvedStatusCode == 'HT'));

      final effectiveDate = resolvedOverview?.date;
      final isPastMatch = effectiveDate != null &&
          DateTime.tryParse(effectiveDate)?.isBefore(
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
          ) == true;

      if (!isCurrentlyLive &&
          (hasFinishedEvent || (isPastMatch && (calculatedScore1 != null || resolvedEvents.isNotEmpty)))) {
        if (resolvedStatus == null ||
            resolvedStatus.isEmpty ||
            !ScoreHelper.isFinishedStatus(resolvedStatus)) {
          resolvedStatus = 'انتهت';
          resolvedStatusCode = 'FINISHED';
        }
      }

      emit(
        state.copyWith(
          status: MatchDetailsStatus.success,
          matchId: cleanTarget,
          events: resolvedEvents,
          videos: resolvedVideos,
          stats: resolvedStats,
          details: resolvedDetails,
          overview: resolvedOverview,
          news: resolvedNews,
          lineup: resolvedLineup,
          championshipId: resolvedChampionshipId,
          halfScores: resolvedHalfScores,
          liveScore1: calculatedScore1,
          liveScore2: calculatedScore2,
          liveStatus: resolvedStatus,
          liveStatusCode: resolvedStatusCode,
          errorMessage: null,
        ),
      );

      // If initial load yielded empty events and stats, schedule a fast background re-check
      // to capture freshly warmed SWR cache from upstream without manual pull-to-refresh
      if (!event.isRefresh && resolvedEvents.isEmpty && resolvedStats.isEmpty) {
        _debounceRefreshTimer?.cancel();
        _debounceRefreshTimer = Timer(const Duration(milliseconds: 1600), () {
          if (!isClosed) {
            add(LoadMatchDetailsEvent(cleanTarget, isRefresh: true));
          }
        });
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: MatchDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
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
          liveScore1: update.score1 ??
              update.rawPayload['score_1']?.toString() ??
              update.rawPayload['score1']?.toString() ??
              update.rawPayload['home_score']?.toString() ??
              state.liveScore1,
          liveScore2: update.score2 ??
              update.rawPayload['score_2']?.toString() ??
              update.rawPayload['score2']?.toString() ??
              update.rawPayload['away_score']?.toString() ??
              state.liveScore2,
          livePenaltyScore1: update.penaltyScore1 ??
              update.rawPayload['penalty_score_1']?.toString() ??
              update.rawPayload['penalties_1']?.toString() ??
              (update.rawPayload['penalties'] is Map ? update.rawPayload['penalties']['home']?.toString() : null) ??
              state.livePenaltyScore1,
          livePenaltyScore2: update.penaltyScore2 ??
              update.rawPayload['penalty_score_2']?.toString() ??
              update.rawPayload['penalties_2']?.toString() ??
              (update.rawPayload['penalties'] is Map ? update.rawPayload['penalties']['away']?.toString() : null) ??
              state.livePenaltyScore2,
          liveStatus: update.status ?? state.liveStatus,
          liveStatusCode: update.statusCode ??
              update.rawPayload['status_code']?.toString() ??
              state.liveStatusCode,
          liveMinute: update.minute ?? state.liveMinute,
          liveExtraTime: update.extraTime ?? state.liveExtraTime,
          livePeriod: update.period ?? state.livePeriod,
          events: updatedEvents,
          lineup: _enrichLineupWithEvents(state.lineup, updatedEvents),
        ),
      );

      if (update.eventType != null && update.eventType!.isNotEmpty) {
        _triggerBackgroundRefresh();
      }
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
      final effectiveEvents =
          mergeResult.isUpdated ? mergeResult.data : state.events;

      emit(
        state.copyWith(
          liveScore1: update.score1 ??
              update.rawPayload['score_1']?.toString() ??
              update.rawPayload['score1']?.toString() ??
              update.rawPayload['home_score']?.toString() ??
              state.liveScore1,
          liveScore2: update.score2 ??
              update.rawPayload['score_2']?.toString() ??
              update.rawPayload['score2']?.toString() ??
              update.rawPayload['away_score']?.toString() ??
              state.liveScore2,
          livePenaltyScore1: update.penaltyScore1 ??
              update.rawPayload['penalty_score_1']?.toString() ??
              update.rawPayload['penalties_1']?.toString() ??
              (update.rawPayload['penalties'] is Map ? update.rawPayload['penalties']['home']?.toString() : null) ??
              state.livePenaltyScore1,
          livePenaltyScore2: update.penaltyScore2 ??
              update.rawPayload['penalty_score_2']?.toString() ??
              update.rawPayload['penalties_2']?.toString() ??
              (update.rawPayload['penalties'] is Map ? update.rawPayload['penalties']['away']?.toString() : null) ??
              state.livePenaltyScore2,
          liveStatus: update.status ?? state.liveStatus,
          liveStatusCode: update.statusCode ??
              update.rawPayload['status_code']?.toString() ??
              state.liveStatusCode,
          liveMinute: update.minute ?? state.liveMinute,
          liveExtraTime: update.extraTime ?? state.liveExtraTime,
          livePeriod: update.period ?? state.livePeriod,
          events: effectiveEvents,
          lineup: _enrichLineupWithEvents(state.lineup, effectiveEvents),
        ),
      );

      if (mergeResult.isUpdated ||
          (update.eventType != null && update.eventType!.isNotEmpty)) {
        _triggerBackgroundRefresh();
      }
    }
  }

  static MatchLineupEntity? _enrichLineupWithEvents(
    MatchLineupEntity? lineup,
    List<MatchEventEntity> events,
  ) {
    if (lineup == null || events.isEmpty) return lineup;

    TeamLineupEntity? enrichTeam(TeamLineupEntity? team, bool isHome) {
      if (team == null) return null;

      LineupPlayerEntity enrichPlayer(LineupPlayerEntity player) {
        int goalCount = player.goals;
        int assistCount = player.assists;
        int yellowCount = player.yellowCards;
        int redCount = player.redCards;
        bool subOut = player.substituteOut;
        bool subIn = player.substituteIn;

        final pName = player.name.trim().toLowerCase();
        final pShort = (player.shortName ?? '').trim().toLowerCase();
        final pNum = player.number;

        bool matchesEvent(String eventName, int? eventNum, bool eventIsHome) {
          if (eventIsHome != isHome) return false;
          if (pNum != null && eventNum != null && pNum == eventNum) return true;
          final eClean = eventName.trim().toLowerCase();
          if (eClean.isEmpty) return false;
          return pName == eClean ||
              (pShort.isNotEmpty && pShort == eClean) ||
              pName.contains(eClean) ||
              eClean.contains(pName) ||
              (pShort.isNotEmpty &&
                  (pShort.contains(eClean) || eClean.contains(pShort)));
        }

        int evGoals = 0;
        int evAssists = 0;
        int evYellows = 0;
        int evReds = 0;

        for (final e in events) {
          if (e.isPeriodMarker) continue;
          final t = e.type.toLowerCase();
          final isGoal = t.contains('goal') && !t.contains('own');
          if (isGoal) {
            if (matchesEvent(e.playerName, e.playerNumber, e.isHomeTeam)) {
              evGoals++;
            }
            if (e.secondaryPlayerName != null &&
                matchesEvent(
                  e.secondaryPlayerName!,
                  e.secondaryPlayerNumber,
                  e.isHomeTeam,
                )) {
              evAssists++;
            }
          } else if (t.contains('yellow')) {
            if (matchesEvent(e.playerName, e.playerNumber, e.isHomeTeam)) {
              evYellows++;
            }
          } else if (t.contains('red')) {
            if (matchesEvent(e.playerName, e.playerNumber, e.isHomeTeam)) {
              evReds++;
            }
          } else if (t.contains('sub')) {
            if (matchesEvent(e.playerName, e.playerNumber, e.isHomeTeam)) {
              subIn = true;
            }
            if (e.secondaryPlayerName != null &&
                matchesEvent(
                  e.secondaryPlayerName!,
                  e.secondaryPlayerNumber,
                  e.isHomeTeam,
                )) {
              subOut = true;
            }
          }
        }

        if (evGoals > goalCount) goalCount = evGoals;
        if (evAssists > assistCount) assistCount = evAssists;
        if (evYellows > yellowCount) yellowCount = evYellows;
        if (evReds > redCount) redCount = evReds;

        if (goalCount != player.goals ||
            assistCount != player.assists ||
            yellowCount != player.yellowCards ||
            redCount != player.redCards ||
            subOut != player.substituteOut ||
            subIn != player.substituteIn) {
          return player.copyWith(
            goals: goalCount,
            assists: assistCount,
            yellowCards: yellowCount,
            redCards: redCount,
            substituteOut: subOut,
            substituteIn: subIn,
          );
        }
        return player;
      }

      return team.copyWith(
        startingXi: team.startingXi.map(enrichPlayer).toList(),
        substitutes: team.substitutes.map(enrichPlayer).toList(),
      );
    }

    return lineup.copyWith(
      home: enrichTeam(lineup.home, true),
      away: enrichTeam(lineup.away, false),
    );
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
