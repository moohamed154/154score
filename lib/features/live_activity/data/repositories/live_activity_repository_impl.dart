import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../domain/entities/live_activity_entity.dart';
import '../../domain/repositories/live_activity_repository.dart';
import '../datasources/live_activity_platform_datasource.dart';
import '../datasources/live_activity_remote_datasource.dart';

class LiveActivityRepositoryImpl implements LiveActivityRepository {
  static final Map<String, String> _logoBase64Cache = {};
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

  Future<String> _getLogoBase64(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return '';
    if (_logoBase64Cache.containsKey(clean)) return _logoBase64Cache[clean]!;
    try {
      return await _fetchLogoBase64Internal(clean).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => '',
      );
    } catch (_) {
      return '';
    }
  }

  Future<String> _fetchLogoBase64Internal(String clean) async {
    try {
      Uint8List? bytes;
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(milliseconds: 1500),
            receiveTimeout: const Duration(milliseconds: 1500),
            headers: {'User-Agent': 'Mozilla/5.0 (Mobile; 154Score)'},
          ),
        );
        final res = await dio.get<List<int>>(clean, options: Options(responseType: ResponseType.bytes));
        if (res.data != null) bytes = Uint8List.fromList(res.data!);
      } catch (_) {}

      if (bytes == null || bytes.isEmpty) return '';

      final codec = await instantiateImageCodec(bytes, targetWidth: 28, targetHeight: 28);
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return '';
      final b64 = base64Encode(byteData.buffer.asUint8List());
      if (b64.isNotEmpty && b64.length <= 1400) {
        _logoBase64Cache[clean] = b64;
        return b64;
      }
      return '';
    } catch (_) {
      return '';
    }
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

      String effectiveClock = (match.time ?? '').trim();
      if (effectiveClock.isEmpty && match.timestamp != null && match.timestamp! > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(match.timestamp! * 1000);
        final hour = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        effectiveClock = '$hour:$min';
      }
      if (effectiveClock.contains(':')) {
        final parts = effectiveClock.split(':');
        if (parts.length >= 2) {
          effectiveClock = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      if (effectiveClock.isEmpty && effectiveMinute.isNotEmpty) {
        effectiveClock = "$effectiveMinute'";
      }

      final resolvedHomeLogo = UrlHelper.normalizeImageUrl(match.team1Logo) ??
          UrlHelper.resolveTeamLogo(match.team1Id, teamName: match.team1) ??
          match.team1Logo ??
          '';
      final resolvedAwayLogo = UrlHelper.normalizeImageUrl(match.team2Logo) ??
          UrlHelper.resolveTeamLogo(match.team2Id, teamName: match.team2) ??
          match.team2Logo ??
          '';

      final homeBase64 = await _getLogoBase64(resolvedHomeLogo);
      final awayBase64 = await _getLogoBase64(resolvedAwayLogo);

      double startTimestamp = 0.0;
      final minuteDigits = effectiveMinute.replaceAll(RegExp(r'[^0-9]'), '');
      final minuteNum = int.tryParse(minuteDigits) ?? 0;
      if (ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode) && minuteNum > 0) {
        startTimestamp = DateTime.now().subtract(Duration(minutes: minuteNum)).millisecondsSinceEpoch / 1000.0;
      }

      bool isArabic = true;
      try {
        isArabic = localStorage.getLanguage() != 'en';
      } catch (_) {}

      final payload = {
        'matchId': cleanMatchId,
        'homeTeam': match.team1,
        'awayTeam': match.team2,
        'homeLogo': resolvedHomeLogo,
        'awayLogo': resolvedAwayLogo,
        'homeLogoBase64': homeBase64,
        'awayLogoBase64': awayBase64,
        'homeScore': ScoreHelper.normalizeScore(effectiveScore1),
        'awayScore': ScoreHelper.normalizeScore(effectiveScore2),
        'status': effectiveStatus,
        'statusCode': effectiveStatusCode,
        'period': effectivePeriod,
        'minute': effectiveMinute,
        'clock': effectiveClock,
        'leagueName': match.leagueTitle ?? '',
        'leagueLogo': match.leagueLogo ?? '',
        'penaltyHome': match.penaltyScore1 ?? '',
        'penaltyAway': match.penaltyScore2 ?? '',
        'hasPenalties': (match.penaltyScore1 != null && match.penaltyScore1!.isNotEmpty),
        'isLive': ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode),
        'isFinished': ScoreHelper.isFinishedStatus(effectiveStatus, effectiveStatusCode),
        'isHalftime': ScoreHelper.isHalftimeStatus(effectiveStatus, effectiveStatusCode),
        'isExtraTime': ScoreHelper.isExtraTimeStatus(effectiveStatus, effectiveStatusCode),
        'isArabic': isArabic,
        'startTimestamp': startTimestamp,
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

      String effectiveClock = (match.time ?? '').trim();
      if (effectiveClock.isEmpty && match.timestamp != null && match.timestamp! > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(match.timestamp! * 1000);
        final hour = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        effectiveClock = '$hour:$min';
      }
      if (effectiveClock.contains(':')) {
        final parts = effectiveClock.split(':');
        if (parts.length >= 2) {
          effectiveClock = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      if (effectiveClock.isEmpty && effectiveMinute.isNotEmpty) {
        effectiveClock = "$effectiveMinute'";
      }

      final resolvedHomeLogo = UrlHelper.normalizeImageUrl(match.team1Logo) ??
          UrlHelper.resolveTeamLogo(match.team1Id, teamName: match.team1) ??
          match.team1Logo ??
          '';
      final resolvedAwayLogo = UrlHelper.normalizeImageUrl(match.team2Logo) ??
          UrlHelper.resolveTeamLogo(match.team2Id, teamName: match.team2) ??
          match.team2Logo ??
          '';

      final homeBase64 = await _getLogoBase64(resolvedHomeLogo);
      final awayBase64 = await _getLogoBase64(resolvedAwayLogo);

      double startTimestamp = 0.0;
      final minuteDigits = effectiveMinute.replaceAll(RegExp(r'[^0-9]'), '');
      final minuteNum = int.tryParse(minuteDigits) ?? 0;
      if (ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode) && minuteNum > 0) {
        startTimestamp = DateTime.now().subtract(Duration(minutes: minuteNum)).millisecondsSinceEpoch / 1000.0;
      }

      bool isArabic = true;
      try {
        isArabic = localStorage.getLanguage() != 'en';
      } catch (_) {}

      final payload = {
        'matchId': cleanMatchId,
        'homeTeam': match.team1,
        'awayTeam': match.team2,
        'homeLogo': resolvedHomeLogo,
        'awayLogo': resolvedAwayLogo,
        'homeLogoBase64': homeBase64,
        'awayLogoBase64': awayBase64,
        'homeScore': ScoreHelper.normalizeScore(effectiveScore1),
        'awayScore': ScoreHelper.normalizeScore(effectiveScore2),
        'status': effectiveStatus,
        'statusCode': effectiveStatusCode,
        'period': effectivePeriod,
        'minute': effectiveMinute,
        'clock': effectiveClock,
        'leagueName': match.leagueTitle ?? '',
        'leagueLogo': match.leagueLogo ?? '',
        'penaltyHome': p1,
        'penaltyAway': p2,
        'hasPenalties': p1.isNotEmpty && p2.isNotEmpty,
        'isLive': ScoreHelper.isLiveStatus(effectiveStatus, effectiveStatusCode),
        'isFinished': ScoreHelper.isFinishedStatus(effectiveStatus, effectiveStatusCode),
        'isHalftime': ScoreHelper.isHalftimeStatus(effectiveStatus, effectiveStatusCode),
        'isExtraTime': ScoreHelper.isExtraTimeStatus(effectiveStatus, effectiveStatusCode),
        'isArabic': isArabic,
        'startTimestamp': startTimestamp,
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
