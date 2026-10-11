import 'dart:async';
import 'dart:io';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../domain/entities/live_activity_entity.dart';
import '../../domain/repositories/live_activity_repository.dart';
import '../datasources/live_activity_platform_datasource.dart';
import '../datasources/live_activity_remote_datasource.dart';

class LiveActivityRepositoryImpl implements LiveActivityRepository {
  final LiveActivityPlatformDataSource platformDataSource;
  final LiveActivityRemoteDataSource remoteDataSource;
  final LocalStorageService localStorage;

  StreamSubscription? _tokenRotationSub;
  StreamSubscription? _trackingStoppedSub;

  LiveActivityRepositoryImpl({
    required this.platformDataSource,
    required this.remoteDataSource,
    required this.localStorage,
  }) {
    _initListeners();
  }

  void _initListeners() {
    _tokenRotationSub = platformDataSource.onPushTokenRotatedStream.listen((data) {
      final actId = data['activityId']?.toString() ?? '';
      final matchId = data['matchId']?.toString() ?? '';
      final pushToken = data['pushToken']?.toString() ?? '';
      if (actId.isNotEmpty && matchId.isNotEmpty && pushToken.isNotEmpty) {
        remoteDataSource.updateToken(
          activityId: actId,
          matchId: matchId,
          pushToken: pushToken,
        );
      }
    });

    _trackingStoppedSub = platformDataSource.onTrackingStoppedStream.listen((matchId) {
      stopTrackingMatch(matchId);
    });
  }

  @override
  Future<bool> areActivitiesSupported() async {
    return await platformDataSource.areActivitiesEnabled();
  }

  @override
  Future<List<String>> getActiveTrackedMatchIds() async {
    return await platformDataSource.getActiveActivities();
  }

  @override
  Future<ApiResult<LiveActivityEntity>> startTrackingMatch({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
  }) async {
    try {
      final cleanMatchId = match.id.replaceAll('match:', '').trim();
      final effectiveScore1 = liveScore1 ?? match.score1 ?? '0';
      final effectiveScore2 = liveScore2 ?? match.score2 ?? '0';
      final effectiveStatus = liveStatus ?? match.status ?? 'مباشر';
      final effectiveStatusCode = liveStatusCode ?? match.statusCode ?? 'LIVE';
      final effectiveMinute = (liveMinute ?? match.minute ?? '').replaceAll("'", '').trim();
      final effectivePeriod = livePeriod ?? match.period ?? 'live';

      final payload = {
        'matchId': cleanMatchId,
        'homeTeam': match.team1,
        'awayTeam': match.team2,
        'homeLogo': match.team1Logo ?? '',
        'awayLogo': match.team2Logo ?? '',
        'homeScore': ScoreHelper.normalizeScore(effectiveScore1),
        'awayScore': ScoreHelper.normalizeScore(effectiveScore2),
        'status': effectiveStatus,
        'statusCode': effectiveStatusCode,
        'period': effectivePeriod,
        'minute': effectiveMinute,
        'clock': match.time ?? (effectiveMinute.isNotEmpty ? "$effectiveMinute'" : ''),
        'leagueName': match.leagueTitle ?? '',
        'leagueLogo': match.leagueLogo ?? '',
        'penaltyHome': match.penaltyScore1 ?? '',
        'penaltyAway': match.penaltyScore2 ?? '',
        'hasPenalties': (match.penaltyScore1 != null && match.penaltyScore1!.isNotEmpty),
        'isLive': ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode),
        'isFinished': ScoreHelper.isFinishedStatus(effectiveStatus, effectiveStatusCode),
        'isHalftime': ScoreHelper.isHalftimeStatus(effectiveStatus, effectiveStatusCode),
        'isExtraTime': ScoreHelper.isExtraTimeStatus(effectiveStatus, effectiveStatusCode),
      };

      final nativeResult = await platformDataSource.startLiveActivity(payload);
      final activityId = nativeResult['activityId']?.toString() ?? 'act_$cleanMatchId';
      final pushToken = nativeResult['pushToken']?.toString();

      final entity = LiveActivityEntity(
        activityId: activityId,
        matchId: cleanMatchId,
        pushToken: pushToken,
        isTracking: true,
      );

      // Register with backend for server-driven APNs / FCM updates
      if (pushToken != null && pushToken.isNotEmpty) {
        unawaited(remoteDataSource.registerActivity(
          activityId: activityId,
          matchId: cleanMatchId,
          pushToken: pushToken,
          platform: Platform.isIOS ? 'ios' : 'android',
        ));
      }

      return ApiSuccess(entity);
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to start Live Activity: $e'));
    }
  }

  @override
  Future<void> updateTrackingMatch({
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
    try {
      final cleanMatchId = match.id.replaceAll('match:', '').trim();
      final effectiveScore1 = liveScore1 ?? match.score1 ?? '0';
      final effectiveScore2 = liveScore2 ?? match.score2 ?? '0';
      final effectiveStatus = liveStatus ?? match.status ?? 'مباشر';
      final effectiveStatusCode = liveStatusCode ?? match.statusCode ?? 'LIVE';
      final effectiveMinute = (liveMinute ?? match.minute ?? '').replaceAll("'", '').trim();
      final effectivePeriod = livePeriod ?? match.period ?? 'live';
      final p1 = penaltyScore1 ?? match.penaltyScore1 ?? '';
      final p2 = penaltyScore2 ?? match.penaltyScore2 ?? '';

      final payload = {
        'matchId': cleanMatchId,
        'homeTeam': match.team1,
        'awayTeam': match.team2,
        'homeLogo': match.team1Logo ?? '',
        'awayLogo': match.team2Logo ?? '',
        'homeScore': ScoreHelper.normalizeScore(effectiveScore1),
        'awayScore': ScoreHelper.normalizeScore(effectiveScore2),
        'status': effectiveStatus,
        'statusCode': effectiveStatusCode,
        'period': effectivePeriod,
        'minute': effectiveMinute,
        'clock': match.time ?? (effectiveMinute.isNotEmpty ? "$effectiveMinute'" : ''),
        'leagueName': match.leagueTitle ?? '',
        'leagueLogo': match.leagueLogo ?? '',
        'penaltyHome': p1,
        'penaltyAway': p2,
        'hasPenalties': p1.isNotEmpty && p2.isNotEmpty,
        'isLive': ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode),
        'isFinished': ScoreHelper.isFinishedStatus(effectiveStatus, effectiveStatusCode),
        'isHalftime': ScoreHelper.isHalftimeStatus(effectiveStatus, effectiveStatusCode),
        'isExtraTime': ScoreHelper.isExtraTimeStatus(effectiveStatus, effectiveStatusCode),
      };

      await platformDataSource.updateLiveActivity(payload);
    } catch (_) {}
  }

  @override
  Future<ApiResult<bool>> stopTrackingMatch(String matchId) async {
    try {
      final cleanMatchId = matchId.replaceAll('match:', '').trim();
      await platformDataSource.stopLiveActivity(matchId: cleanMatchId);
      unawaited(remoteDataSource.stopActivity(matchId: cleanMatchId));
      return const ApiSuccess(true);
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to stop Live Activity: $e'));
    }
  }

  @override
  Stream<String> get onTrackingStoppedStream =>
      platformDataSource.onTrackingStoppedStream;

  void dispose() {
    _tokenRotationSub?.cancel();
    _trackingStoppedSub?.cancel();
  }
}
