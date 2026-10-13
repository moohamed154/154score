import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/matches/data/models/match_dto.dart';
import '../../features/matches/domain/entities/match_entity.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../security/security_signer.dart';
import '../storage/local_storage_service.dart';
import '../utils/match_status_helper.dart';
import 'match_notification_tracker.dart';
import 'notification_service.dart';

/// Top-level callback entrypoint for the Android foreground task isolate.
@pragma('vm:entry-point')
void startLiveMatchCallback() {
  FlutterForegroundTask.setTaskHandler(LiveMatchTaskHandler());
}

/// Helper to check if a match is actively live.
bool isMatchLive(MatchEntity m) {
  final phase = MatchStatusHelper.parseStatus(
    m.status,
    statusCode: m.statusCode,
    period: m.period,
    minute: m.minute,
  );
  return phase == MatchPhase.live ||
      phase == MatchPhase.halfTime ||
      phase == MatchPhase.extraTime ||
      phase == MatchPhase.penalties;
}

/// TaskHandler running in the foreground service isolate on Android.
/// Keeps network active without Doze mode interference for zero-delay delivery.
class LiveMatchTaskHandler extends TaskHandler {
  Dio? _dio;
  SharedPreferences? _prefs;
  int _newsTickCount = 0;
  int _todayPollTickCount = 0;

  Dio _buildSecureDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'User-Agent': '154Score-Flutter/1.0',
          'X-API-Key': AppConfig.validateApiKey(),
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final signPath =
              options.uri.path.isNotEmpty ? options.uri.path : options.path;
          final sig = SecuritySigner.buildSecurityHeaders(
            method: options.method,
            path: signPath,
          );
          options.headers.addAll(sig);
          return handler.next(options);
        },
      ),
    );
    return dio;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    try {
      _dio = _buildSecureDio();
      _prefs = await SharedPreferences.getInstance();
      try {
        await _prefs?.reload();
      } catch (_) {}
      await NotificationService.instance.initialize();
      debugPrint('[LiveMatchTaskHandler] onStart initialized successfully');
    } catch (e) {
      debugPrint('[LiveMatchTaskHandler] onStart error: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    await _checkLiveMatches();
    _newsTickCount++;
    if (_newsTickCount >= 2) {
      // Check for breaking news & backend notifications every ~10 seconds
      _newsTickCount = 0;
      await _checkNotificationsFeed();
    }
  }

  Future<void> _checkLiveMatches() async {
    try {
      _dio ??= _buildSecureDio();
      _prefs ??= await SharedPreferences.getInstance();
      try {
        await _prefs?.reload();
      } catch (_) {}

      final lang = _prefs?.getString('154score_notif_lang') ?? 'ar';
      final res = await _dio!.get(
        ApiEndpoints.matchesLive,
        queryParameters: {'lang': lang},
      );

      List<MatchEntity> matches = [];
      if (res.statusCode == 200 && res.data != null) {
        matches = _parseMatches(res.data);
      }

      // Periodically (every ~30s) or when no live matches, check today's fixtures
      // so upcoming matches that kick off or finish are instantly detected
      _todayPollTickCount++;
      if (matches.isEmpty || _todayPollTickCount >= 6) {
        _todayPollTickCount = 0;
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        try {
          final todayRes = await _dio!.get(
            ApiEndpoints.matchesByDate(dateStr),
            queryParameters: {'lang': lang},
          );
          if (todayRes.statusCode == 200 && todayRes.data != null) {
            final todayMatches = _parseMatches(todayRes.data);
            if (todayMatches.isNotEmpty) {
              await MatchNotificationTracker.instance.processMatches(
                todayMatches,
              );
            }
          }
        } catch (_) {}
      }

      if (matches.isNotEmpty) {
        await MatchNotificationTracker.instance.processMatches(matches);
        _updateNotificationStatus(matches, lang);

        final trackedIds = _prefs?.getStringList('154score_tracked_live_matches') ?? [];
        if (trackedIds.isNotEmpty) {
          final trackedMatches = matches
              .where((m) => trackedIds.contains(m.id.replaceAll('match:', '').trim()))
              .toList();
          if (trackedMatches.isNotEmpty) {
            FlutterForegroundTask.sendDataToMain({
              'type': 'tracked_matches_update',
              'matches': trackedMatches.map((m) => {
                'id': m.id,
                'score1': m.score1,
                'score2': m.score2,
                'minute': m.minute,
                'status': m.status,
                'statusCode': m.statusCode,
                'period': m.period,
                'penaltyScore1': m.penaltyScore1,
                'penaltyScore2': m.penaltyScore2,
              }).toList(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[LiveMatchTaskHandler] checkLiveMatches error: $e');
    }
  }

  void _updateNotificationStatus(List<MatchEntity> matches, String lang) {
    final liveMatches = matches.where(isMatchLive).toList();
    final isAr = lang == 'ar';
    if (liveMatches.isNotEmpty) {
      final text = isAr
          ? 'جارٍ متابعة ${liveMatches.length} مباريات مباشرة بدون أي تأخير...'
          : 'Tracking ${liveMatches.length} live matches with zero delay...';
      FlutterForegroundTask.updateService(
        notificationTitle: isAr
            ? '154Score • المتابعة المباشرة نشطة'
            : '154Score • Live Alerts Active',
        notificationText: text,
      );
    } else {
      final text = isAr
          ? 'متابعة حية للأهداف والأخبار العاجلة لحظياً'
          : 'Live tracking of goals & breaking news in real-time';
      FlutterForegroundTask.updateService(
        notificationTitle: isAr
            ? '154Score • خدمة التنبيهات الفورية نشطة'
            : '154Score • Instant Alerts Active',
        notificationText: text,
      );
    }
  }

  Future<void> _checkNotificationsFeed() async {
    try {
      _dio ??= _buildSecureDio();
      _prefs ??= await SharedPreferences.getInstance();
      try {
        await _prefs?.reload();
      } catch (_) {}

      final lang = _prefs?.getString('154score_notif_lang') ?? 'ar';
      final res = await _dio!.get(
        ApiEndpoints.notifications,
        queryParameters: {'lang': lang},
      );

      if (res.statusCode == 200 && res.data != null) {
        final body = res.data;
        List<dynamic> items = [];
        if (body is Map && body['data'] != null) {
          final inner = body['data'];
          if (inner is Map && inner['notifications'] is List) {
            items = inner['notifications'] as List;
          } else if (inner is List) {
            items = inner;
          }
        } else if (body is List) {
          items = body;
        }

        if (items.isEmpty) return;

        final seenSet = (_prefs?.getStringList('154score_seen_notif_ids') ?? [])
            .toSet();
        final isFirstRun =
            !(_prefs?.containsKey('154score_seen_notif_ids') ?? false);

        // On cold first launch, seed existing IDs so we only alert on NEW incoming items
        if (isFirstRun) {
          final initialIds = items
              .map((r) => r is Map ? r['id']?.toString() ?? '' : '')
              .where((id) => id.isNotEmpty)
              .toList();
          await _prefs?.setStringList('154score_seen_notif_ids', initialIds);
          return;
        }

        final storage = LocalStorageServiceImpl(_prefs!);
        final newsEnabled = storage.isNewsNotificationEnabled();
        final goalsEnabled = storage.isMatchGoalsNotificationEnabled();
        final startEndEnabled = storage.isMatchStartEndNotificationEnabled();
        final lineupEnabled = storage.isMatchLineupNotificationEnabled();

        final notifService = NotificationService.instance;
        final List<String> newlySeenIds = [];

        for (final raw in items) {
          if (raw is! Map<String, dynamic>) continue;
          final id = raw['id']?.toString() ?? '';
          if (id.isEmpty || seenSet.contains(id)) continue;

          final title = raw['title']?.toString() ?? '';
          final notifBody = raw['body']?.toString() ?? '';
          final type = raw['type']?.toString() ?? '';
          final matchId = raw['match_id']?.toString() ?? '';
          final data = raw['data'] as Map<String, dynamic>?;
          final articleId = data?['article_id']?.toString() ?? '';

          // Brand safety
          if (_containsBrandWord(title) || _containsBrandWord(notifBody)) {
            newlySeenIds.add(id);
            continue;
          }

          final payload = jsonEncode({
            'type': type == 'news' ? 'news' : 'match',
            if (matchId.isNotEmpty) 'match_id': matchId,
            if (articleId.isNotEmpty) 'article_id': articleId,
          });

          // Check if match event is tracked
          bool isTrackedEvent() {
            final scope = storage.getMatchNotificationScope();
            if (scope == LocalStorageService.matchNotifScopeAll) return true;
            return storage.isNotificationMatchingStarredTeams(
              title: title,
              body: notifBody,
              matchId: matchId.isNotEmpty ? matchId : null,
              data: data,
            );
          }

          switch (type) {
            case 'news':
              if (newsEnabled) {
                await notifService.showNewsNotification(
                  articleId: articleId.isNotEmpty ? articleId : id,
                  title: title,
                  body: notifBody,
                  payload: payload,
                );
              }
            case 'goal':
              if (goalsEnabled && isTrackedEvent()) {
                await notifService.showGoalNotification(
                  matchId: matchId.isNotEmpty ? matchId : id,
                  title: title,
                  body: notifBody,
                  payload: payload,
                );
              }
            case 'match_start':
              if (startEndEnabled && isTrackedEvent()) {
                await notifService.showMatchStartNotification(
                  matchId: matchId.isNotEmpty ? matchId : id,
                  title: title,
                  body: notifBody,
                  payload: payload,
                );
              }
            case 'match_end':
              if (startEndEnabled && isTrackedEvent()) {
                await notifService.showMatchEndNotification(
                  matchId: matchId.isNotEmpty ? matchId : id,
                  title: title,
                  body: notifBody,
                  payload: payload,
                );
              }
            case 'lineup':
              if (lineupEnabled && isTrackedEvent()) {
                await notifService.showLineupNotification(
                  matchId: matchId.isNotEmpty ? matchId : id,
                  title: title,
                  body: notifBody,
                  payload: payload,
                );
              }
            default:
              break;
          }

          newlySeenIds.add(id);
        }

        if (newlySeenIds.isNotEmpty) {
          seenSet.addAll(newlySeenIds);
          final trimmed = seenSet.toList();
          if (trimmed.length > 500) {
            trimmed.removeRange(0, trimmed.length - 500);
          }
          await _prefs?.setStringList('154score_seen_notif_ids', trimmed);
        }
      }
    } catch (e) {
      debugPrint('[LiveMatchTaskHandler] checkNotificationsFeed error: $e');
    }
  }

  bool _containsBrandWord(String text) {
    final lower = text.toLowerCase();
    return lower.contains('yallashoot') ||
        lower.contains('yalla shoot') ||
        lower.contains('يلا شوت') ||
        lower.contains('يلاشوت') ||
        lower.contains('ysscores');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _dio?.close(force: true);
    _dio = null;
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_stop_tracking') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}

  List<MatchEntity> _parseMatches(dynamic data) {
    final result = <MatchEntity>[];
    if (data is Map && data['data'] != null) {
      final inner = data['data'];
      if (inner is List) {
        for (final item in inner) {
          if (item is Map) {
            if (item['matches'] is List) {
              for (final m in item['matches']) {
                if (m is Map) {
                  try {
                    result.add(
                      MatchDto.fromJson(Map<String, dynamic>.from(m))
                          .toEntity(),
                    );
                  } catch (_) {}
                }
              }
            } else {
              try {
                result.add(
                  MatchDto.fromJson(Map<String, dynamic>.from(item)).toEntity(),
                );
              } catch (_) {}
            }
          }
        }
      }
    }
    return result;
  }
}

/// Helper service for starting, stopping, and managing the Live Match Foreground Service.
class LiveMatchForegroundService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'match_foreground_service',
        channelName: '154Score خدمة المتابعة المباشرة',
        channelDescription: 'إشعار متابعة أهداف وأحداث المباريات المباشرة لحظة بلحظة بدون تأخير',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          5000,
        ), // Poll every 5s for zero-delay
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: true,
        stopWithTask: false,
      ),
    );
    _isInitialized = true;
  }

  static Future<bool> startService({
    String? customTitle,
    String? customText,
  }) async {
    if (!Platform.isAndroid) return false;
    await init();

    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 154,
      serviceTypes: [
        ForegroundServiceTypes.dataSync,
        ForegroundServiceTypes.remoteMessaging,
      ],
      notificationTitle:
          customTitle ?? '154Score • خدمة التنبيهات والأخبار نشطة',
      notificationText:
          customText ?? 'متابعة حية للأهداف والأخبار العاجلة لحظة بلحظة',
      notificationButtons: [
        const NotificationButton(
          id: 'btn_stop_tracking',
          text: 'إيقاف المتابعة',
        ),
      ],
      notificationInitialRoute: '/',
      callback: startLiveMatchCallback,
    );

    return result is ServiceRequestSuccess;
  }

  static Future<bool> stopService() async {
    if (!Platform.isAndroid) return false;
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  static Future<bool> isRunning() async {
    if (!Platform.isAndroid) return false;
    return await FlutterForegroundTask.isRunningService;
  }

  /// Request battery optimization exemption for uninterrupted zero-delay delivery
  static Future<void> requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    try {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (e) {
      debugPrint('[LiveMatchForegroundService] battery exemption error: $e');
    }
  }

  /// Synchronization with user preferences:
  /// Keeps foreground service active continuously for ALWAYS zero-delay match and news alerts.
  static Future<void> syncWithMatches({
    required List<MatchEntity> matches,
    required bool isLiveMatchModeEnabled,
    required List<String> favoriteTeamIds,
    required List<String> favoriteMatchIds,
  }) async {
    if (!Platform.isAndroid) return;
    if (isLiveMatchModeEnabled) {
      if (!await isRunning()) {
        await startService();
      }
    } else {
      if (await isRunning()) {
        await stopService();
      }
    }
  }
}
