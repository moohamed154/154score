import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';

/// Handles all OS-level local notification display.
/// Works in foreground, background, and when the app is fully closed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Android Notification Channels ──────────────────────────────────────────
  static const _channelMatchId = 'match_notifications_v3';
  static const _channelMatchName = 'Match Events';
  static const _channelMatchDesc = 'Instant goal alerts, match start and end';

  static const _channelNewsId = 'news_notifications_v2';
  static const _channelNewsName = 'News';
  static const _channelNewsDesc = 'Breaking news alerts';

  bool _initialized = false;
  void Function(String? payload)? _onNotificationTap;

  /// Call once in [main] before [runApp].
  Future<void> initialize({
    /// Called when user taps a notification while app is running / background.
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (onNotificationTap != null) {
      _onNotificationTap = onNotificationTap;
    }
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          _onNotificationTap?.call(response.payload);
        },
        onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
      );

      // Create Android channels with highest importance for heads-up alerts
      await _createChannel(
        id: _channelMatchId,
        name: _channelMatchName,
        description: _channelMatchDesc,
        importance: Importance.max,
      );
      await _createChannel(
        id: _channelNewsId,
        name: _channelNewsName,
        description: _channelNewsDesc,
        importance: Importance.max,
      );
    } catch (e) {
      debugPrint('[NotificationService] initialize platform error: $e');
    }

    // Request permission on Android 13+ (safe in background isolates)
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    // Request permission on iOS
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (_) {}
  }

  /// Explicitly requests notification permissions on both Android and iOS.
  /// Returns `true` if granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    try {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          final granted = await androidPlugin.requestNotificationsPermission();
          return granted ?? false;
        } catch (e) {
          debugPrint(
              '[NotificationService] androidPlugin.requestNotificationsPermission error: $e');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermissions error: $e');
    }
    return true;
  }

  /// Checks if notifications are currently enabled in the OS settings.
  Future<bool> areNotificationsEnabled() async {
    try {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final settings = await iosPlugin.checkPermissions();
        return settings?.isEnabled ?? false;
      }

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          final enabled = await androidPlugin.areNotificationsEnabled();
          return enabled ?? false;
        } catch (e) {
          debugPrint(
              '[NotificationService] androidPlugin.areNotificationsEnabled error: $e');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] areNotificationsEnabled error: $e');
    }
    return true;
  }

  Future<void> _createChannel({
    required String id,
    required String name,
    required String description,
    required Importance importance,
  }) async {
    final channel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: importance,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Public show helpers ────────────────────────────────────────────────────

  Future<void> showGoalNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    await _show(
      id: notificationId ?? _stableId('goal_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showLineupNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('lineup_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showMatchStartNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('start_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showHalfTimeNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('halftime_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showSecondHalfStartNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('secondhalf_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showMatchEndNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('end_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showRedCardNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    await _show(
      id: notificationId ??
          _stableId(
              'redcard_${matchId}_${DateTime.now().millisecondsSinceEpoch % 100000}'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showYellowCardNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    await _show(
      id: notificationId ??
          _stableId(
              'yellowcard_${matchId}_${DateTime.now().millisecondsSinceEpoch % 100000}'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showSubstitutionNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    await _show(
      id: notificationId ??
          _stableId(
              'sub_${matchId}_${DateTime.now().millisecondsSinceEpoch % 100000}'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showPenaltyMissNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    await _show(
      id: notificationId ??
          _stableId(
              'penmiss_${matchId}_${DateTime.now().millisecondsSinceEpoch % 100000}'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  Future<void> showNewsNotification({
    required String articleId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('news_$articleId'),
      title: title,
      body: body,
      channelId: _channelNewsId,
      payload: payload,
      priority: Priority.max,
      importance: Importance.max,
    );
  }

  // ── Generic show ───────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
    Priority priority = Priority.max,
    Importance importance = Importance.max,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final isMatch = channelId == _channelMatchId;
    final androidDetails = AndroidNotificationDetails(
      channelId,
      isMatch ? _channelMatchName : _channelNewsName,
      channelDescription: isMatch ? _channelMatchDesc : _channelNewsDesc,
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      ticker: body,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: isMatch ? '154Score' : 'News',
      ),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[NotificationService] _show error: $e');
    }
  }

  /// Converts a string key to a stable int ID (avoids duplicates for same event).
  static int stableId(String key) {
    return key.hashCode.abs() % 100000;
  }

  int _stableId(String key) => stableId(key);

  /// Returns the launch payload if the app was opened from a tapped notification.
  Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}

/// Top-level function required by flutter_local_notifications for background taps.
@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse response) {
  // Navigate / handle payload when tapped from terminated state.
  // Navigation must happen via shared_preferences flag since no BuildContext.
  debugPrint('[NotificationService] background tap: ${response.payload}');
}

/// Helper to build a JSON payload string for a notification.
String buildNotificationPayload({
  required String type, // 'news' | 'match'
  String? matchId,
  String? articleId,
}) {
  return jsonEncode({
    'type': type,
    if (matchId != null) 'match_id': matchId,
    if (articleId != null) 'article_id': articleId,
  });
}
