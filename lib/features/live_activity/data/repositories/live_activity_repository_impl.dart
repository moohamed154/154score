import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/live_clock_sync.dart';
import '../../../../core/utils/match_status_helper.dart';
import '../../../../core/utils/score_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../domain/entities/live_activity_entity.dart';
import '../../domain/repositories/live_activity_repository.dart';
import '../datasources/live_activity_platform_datasource.dart';
import '../datasources/live_activity_remote_datasource.dart';

class LiveActivityRepositoryImpl implements LiveActivityRepository {
  static final Map<String, String> _logoBase64Cache = {};
  static final Map<String, ({int minute, double startTimestamp})> _matchTimestamps = {};
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
      final payload = await _buildPayload(
        match: match,
        liveScore1: liveScore1,
        liveScore2: liveScore2,
        liveMinute: liveMinute,
        liveStatus: liveStatus,
        liveStatusCode: liveStatusCode,
        livePeriod: livePeriod,
      );

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
      final payload = await _buildPayload(
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

      await platformDataSource.updateLiveActivity(payload);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _buildPayload({
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
    final cleanMatchId = match.id.replaceAll('match:', '').trim();
    final effectiveScore1 = liveScore1 ?? match.score1 ?? '0';
    final effectiveScore2 = liveScore2 ?? match.score2 ?? '0';
    final effectiveStatus = liveStatus ?? match.status ?? 'مباشر';
    final effectiveStatusCode = liveStatusCode ?? match.statusCode ?? 'LIVE';
    final effectiveMinute = (liveMinute ?? match.minute ?? '').replaceAll("'", '').trim();
    final effectivePeriod = livePeriod ?? match.period ?? 'live';
    final p1 = penaltyScore1 ?? match.penaltyScore1 ?? '';
    final p2 = penaltyScore2 ?? match.penaltyScore2 ?? '';

    bool isArabic = true;
    try {
      isArabic = localStorage.getLanguage() != 'en';
    } catch (_) {}

    final clockData = _resolveMatchCardData(
      match: match,
      effectiveScore1: effectiveScore1,
      effectiveScore2: effectiveScore2,
      effectiveStatus: effectiveStatus,
      effectiveStatusCode: effectiveStatusCode,
      effectiveMinute: effectiveMinute,
      effectivePeriod: effectivePeriod,
      isArabic: isArabic,
    );

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

    return {
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
      'minute': clockData.displayMinute,
      'clock': clockData.displayClock,
      'matchClock': clockData.matchClock,
      'leagueName': match.leagueTitle ?? '',
      'leagueLogo': match.leagueLogo ?? '',
      'penaltyHome': p1,
      'penaltyAway': p2,
      'hasPenalties': (p1.isNotEmpty && p2.isNotEmpty),
      'isLive': clockData.isLive,
      'isFinished': clockData.isFinished,
      'isHalftime': clockData.isHalftime,
      'isExtraTime': clockData.isExtraTime,
      'isArabic': isArabic,
      'startTimestamp': clockData.startTimestamp,
    };
  }

  ({
    int minute,
    int second,
    String displayMinute,
    String displayClock,
    String matchClock,
    bool isLive,
    bool isFinished,
    bool isHalftime,
    bool isExtraTime,
    double startTimestamp,
  }) _resolveMatchCardData({
    required MatchEntity match,
    required String effectiveScore1,
    required String effectiveScore2,
    required String effectiveStatus,
    required String effectiveStatusCode,
    required String effectiveMinute,
    required String effectivePeriod,
    required bool isArabic,
  }) {
    final cleanMatchId = match.id.replaceAll('match:', '').trim();

    // 1. Resolve phase matching MatchCard exactly
    final phase = MatchStatusHelper.parseStatus(
      effectiveStatus,
      statusCode: effectiveStatusCode,
      period: effectivePeriod,
      minute: effectiveMinute,
      extraTime: match.extraTime,
      time: match.time,
      date: match.date,
      score1: effectiveScore1,
      score2: effectiveScore2,
      timestamp: match.timestamp,
    );
    final isLive = MatchStatusHelper.isLive(phase);
    final isFinished = MatchStatusHelper.isFinished(phase);
    final isHalftime = phase == MatchPhase.halfTime;
    final isExtraTime = phase == MatchPhase.extraTime;

    // 2. Parse raw minute and seconds if present
    int minNum = 0;
    int secNum = 0;
    if (effectiveMinute.isNotEmpty && effectiveMinute != 'null') {
      final clean = effectiveMinute.replaceAll("'", '').trim();
      if (clean.contains('+')) {
        final parts = clean.split('+');
        minNum = int.tryParse(parts[0].trim()) ?? 0;
      } else if (clean.contains(':')) {
        final parts = clean.split(':');
        minNum = int.tryParse(parts[0].trim()) ?? 0;
        if (parts.length > 1) {
          secNum = int.tryParse(parts[1].trim()) ?? 0;
        }
      } else {
        minNum = int.tryParse(clean) ?? 0;
      }
    }

    // 3. Consult LiveClockSync (in-memory sync registry used by MatchCard and MatchHeaderBanner)
    final syncedClock = LiveClockSync.getLiveClock(cleanMatchId);
    if (syncedClock != null) {
      if (syncedClock.minute >= minNum && minNum > 0) {
        minNum = syncedClock.minute;
        secNum = syncedClock.second;
      } else if (minNum == 0 && (syncedClock.minute > 0 || syncedClock.second > 0)) {
        minNum = syncedClock.minute;
        secNum = syncedClock.second;
      }
    } else if (minNum == 0 && isLive) {
      // Calculate live clock from kickoff timestamp / time (same as CircularLiveClock)
      final estimated = MatchStatusHelper.calculateLiveClock(
        time: match.time,
        status: effectiveStatus,
        period: effectivePeriod,
        timestamp: match.timestamp,
        htTime: match.htTime,
      );
      minNum = estimated.minute;
      secNum = estimated.second;
    }

    // 4. Resolve Kickoff / Display clock (matching MatchCard upcoming formatting)
    String activeFormat = '24h';
    try {
      activeFormat = localStorage.getTimeFormat();
    } catch (_) {}

    String displayClock = '';
    if (match.time != null && match.time!.isNotEmpty && match.time != '-') {
      displayClock = DateFormatter.formatDisplayTime(
        match.time!,
        timeFormat: activeFormat,
        isArabic: isArabic,
      );
    } else if (match.timestamp != null && match.timestamp! > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(match.timestamp! * 1000);
      final raw = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      displayClock = DateFormatter.formatDisplayTime(
        raw,
        timeFormat: activeFormat,
        isArabic: isArabic,
      );
    }
    if (displayClock == '-' || displayClock.isEmpty) {
      displayClock = match.time ?? '--:--';
    }

    // 5. Calculate anchor startTimestamp with exact seconds precision
    double startTimestamp = 0.0;
    if (isLive && !isHalftime && !isFinished && (minNum > 0 || secNum > 0)) {
      final totalElapsedSec = minNum * 60 + secNum;
      final cached = _matchTimestamps[cleanMatchId];
      if (cached != null && cached.minute == minNum && cached.startTimestamp > 0) {
        startTimestamp = cached.startTimestamp;
      } else {
        startTimestamp = DateTime.now().subtract(Duration(seconds: totalElapsedSec)).millisecondsSinceEpoch / 1000.0;
        _matchTimestamps[cleanMatchId] = (minute: minNum, startTimestamp: startTimestamp);
      }
    } else {
      _matchTimestamps.remove(cleanMatchId);
    }

    final displayMinute = minNum > 0 ? '$minNum' : effectiveMinute;

    final mm = minNum.toString().padLeft(2, '0');
    final ss = secNum.toString().padLeft(2, '0');
    final matchClock = minNum > 0 ? '$mm:$ss' : (secNum > 0 ? '00:$ss' : '');

    return (
      minute: minNum,
      second: secNum,
      displayMinute: displayMinute,
      displayClock: displayClock,
      matchClock: matchClock,
      isLive: isLive,
      isFinished: isFinished,
      isHalftime: isHalftime,
      isExtraTime: isExtraTime,
      startTimestamp: startTimestamp,
    );
  }

  @override
  Future<ApiResult<bool>> stopTrackingMatch(String matchId) async {
    try {
      final cleanMatchId = matchId.replaceAll('match:', '').trim();
      _matchTimestamps.remove(cleanMatchId);
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
