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
  static const _channelMatchId = 'match_notifications';
  static const _channelMatchName = 'Match Events';
  static const _channelMatchDesc = 'Goals, lineups, match start & end';

  static const _channelNewsId = 'news_notifications';
  static const _channelNewsName = 'News';
  static const _channelNewsDesc = 'Breaking news alerts';

  bool _initialized = false;

  /// Call once in [main] before [runApp].
  Future<void> initialize({
    /// Called when user taps a notification while app is running / background.
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // use app icon; replace with custom later
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );

    // Create Android channels
    await _createChannel(
      id: _channelMatchId,
      name: _channelMatchName,
      description: _channelMatchDesc,
      importance: Importance.high,
    );
    await _createChannel(
      id: _channelNewsId,
      name: _channelNewsName,
      description: _channelNewsDesc,
      importance: Importance.defaultImportance,
    );

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
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
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // ── Public show helpers ────────────────────────────────────────────────────

  Future<void> showGoalNotification({
    required String matchId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(
      id: _stableId('goal_$matchId'),
      title: title,
      body: body,
      channelId: _channelMatchId,
      payload: payload,
      priority: Priority.high,
      importance: Importance.high,
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
      priority: Priority.high,
      importance: Importance.high,
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
    );
  }

  // ── Generic show ───────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
    Priority priority = Priority.defaultPriority,
    Importance importance = Importance.defaultImportance,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _channelMatchId ? _channelMatchName : _channelNewsName,
      importance: importance,
      priority: priority,
      ticker: body,
      styleInformation: BigTextStyleInformation(body),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Converts a string key to a stable int ID (avoids duplicates for same event).
  int _stableId(String key) {
    return key.hashCode.abs() % 100000;
  }

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
