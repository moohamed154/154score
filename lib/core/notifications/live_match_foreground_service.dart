import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/matches/data/models/match_dto.dart';
import '../../features/matches/domain/entities/match_entity.dart';
import '../constants/api_endpoints.dart';
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

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ));
      _prefs = await SharedPreferences.getInstance();
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('[LiveMatchTaskHandler] onStart error: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _checkLiveMatches();
  }

  Future<void> _checkLiveMatches() async {
    try {
      _dio ??= Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ));
      _prefs ??= await SharedPreferences.getInstance();

      final lang = _prefs?.getString('154score_notif_lang') ?? 'ar';
      final res = await _dio!.get(
        ApiEndpoints.matchesLive,
        queryParameters: {'lang': lang},
      );

      if (res.statusCode == 200 && res.data != null) {
        final matches = _parseMatches(res.data);
        if (matches.isNotEmpty) {
          // Process events (goals, match start/finish, red cards) with instant alerts
          await MatchNotificationTracker.instance.processMatches(matches);

          // Update foreground notification display
          _updateNotificationStatus(matches, lang);
        }
      }
    } catch (e) {
      debugPrint('[LiveMatchTaskHandler] repeat check error: $e');
    }
  }

  void _updateNotificationStatus(List<MatchEntity> matches, String lang) {
    final liveMatches = matches.where(isMatchLive).toList();
    if (liveMatches.isNotEmpty) {
      final isAr = lang == 'ar';
      final text = isAr
          ? 'جارٍ متابعة ${liveMatches.length} مباريات مباشرة بدون أي تأخير...'
          : 'Tracking ${liveMatches.length} live matches with zero delay...';
      FlutterForegroundTask.updateService(
        notificationTitle: isAr ? '154Score • المتابعة المباشرة نشطة' : '154Score • Live Match Mode Active',
        notificationText: text,
      );
    }
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
                    result.add(MatchDto.fromJson(Map<String, dynamic>.from(m)).toEntity());
                  } catch (_) {}
                }
              }
            } else {
              try {
                result.add(MatchDto.fromJson(Map<String, dynamic>.from(item)).toEntity());
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
        eventAction: ForegroundTaskEventAction.repeat(5000), // Poll every 5s for zero-delay
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _isInitialized = true;
  }

  static Future<bool> startService({String? customTitle, String? customText}) async {
    if (!Platform.isAndroid) return false;
    await init();

    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 154,
      notificationTitle: customTitle ?? '154Score • المتابعة المباشرة نشطة',
      notificationText: customText ?? 'متابعة حية للأهداف وأحداث المباريات المباشرة لحظياً',
      notificationButtons: [
        const NotificationButton(id: 'btn_stop_tracking', text: 'إيقاف المتابعة'),
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

  /// Intelligent synchronization with matches list:
  /// Starts service if user has live match mode enabled and there are live tracked matches.
  static Future<void> syncWithMatches({
    required List<MatchEntity> matches,
    required bool isLiveMatchModeEnabled,
    required List<String> favoriteTeamIds,
    required List<String> favoriteMatchIds,
  }) async {
    if (!Platform.isAndroid) return;
    if (!isLiveMatchModeEnabled) {
      if (await isRunning()) {
        await stopService();
      }
      return;
    }

    // Check if any tracked match is currently live
    final hasLiveTrackedMatch = matches.any((m) {
      if (!isMatchLive(m)) return false;
      if (favoriteMatchIds.contains(m.id)) return true;
      if (m.team1Id != null && favoriteTeamIds.contains(m.team1Id)) return true;
      if (m.team2Id != null && favoriteTeamIds.contains(m.team2Id)) return true;
      if (favoriteTeamIds.contains(m.team1.trim().toLowerCase())) return true;
      if (favoriteTeamIds.contains(m.team2.trim().toLowerCase())) return true;
      return false;
    });

    if (hasLiveTrackedMatch) {
      if (!await isRunning()) {
        await startService();
      }
    }
  }
}
