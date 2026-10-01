import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router/app_router.dart';
import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import 'notification_service.dart';

/// Top-level background message handler required by Firebase Messaging.
/// Executes when a notification / data message arrives while app is terminated or in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint(
    '[PushNotificationService] Background message received: ${message.messageId} | ${message.data}',
  );
}

/// Central service managing Firebase Cloud Messaging (FCM), OS permissions,
/// backend device token registration, foreground heads-up alerts, and notification tap routing.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _prefFcmTokenKey = '154score_fcm_device_token';

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging, request OS permissions, obtain FCM token,
  /// register with backend, and attach message listeners.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Initialize Firebase Core
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 2. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Foreground Presentation Options (iOS / macOS)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Request OS Permissions
      await requestPermissions();

      // 5. Retrieve and Register FCM Device Token
      await _retrieveAndRegisterToken();

      // 6. Listen for Token Refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM_TOKEN_REFRESHED] New token received from Firebase');
        _registerTokenWithBackend(newToken);
      });

      // 7. Setup Message Listeners (Foreground, Background Tap, Terminated Launch)
      _setupMessageListeners();
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error: $e');
    }
  }

  /// Explicitly requests notification permissions on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint(
        '[PushNotificationService] Notification permission status: ${settings.authorizationStatus}',
      );
      return isAuthorized;
    } catch (e) {
      debugPrint('[PushNotificationService] requestPermissions error: $e');
      return false;
    }
  }

  /// Obtains current token and registers with the canonical 154Score backend.
  Future<void> _retrieveAndRegisterToken() async {
    try {
      if (Platform.isIOS) {
        // On iOS, FCM requires the APNs device token. Allow APNs token negotiation if needed.
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('[PushNotificationService] Waiting briefly for iOS APNs token...');
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        debugPrint(
          '[FCM_TOKEN_RECEIVED] FCM Token: ${token.substring(0, token.length > 12 ? 12 : token.length)}...',
        );
        await _registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('[PushNotificationService] getToken error: $e');
    }
  }

  /// Sends the device token to: POST /notifications/push_notifications_providers
  Future<bool> _registerTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_prefFcmTokenKey);
      final lang = prefs.getString('154score_notif_lang') ?? 'ar';

      final payload = {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'lang': lang,
        'bundle_id': 'com.hamdy.app154score',
        if (oldToken != null && oldToken != token) 'old_token': oldToken,
      };

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': '154Score-Flutter/1.0',
            'X-API-Key': AppConfig.validateApiKey(),
          },
        ),
      );

      // Support canonical endpoint (try with and without /api prefix)
      Response? response;
      try {
        response = await dio.post(
          '/notifications/push_notifications_providers',
          data: payload,
        );
      } catch (_) {
        try {
          response = await dio.post(
            '/api/notifications/push_notifications_providers',
            data: payload,
          );
        } catch (_) {}
      }

      final status = response?.statusCode;
      if (status == 200 || status == 201) {
        await prefs.setString(_prefFcmTokenKey, token);
        debugPrint(
          '[FCM_TOKEN_REGISTERED] Registered with backend: ${token.substring(0, 10)}...',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to register token with backend: $e');
    }
    return false;
  }

  /// Configures message streams: Foreground, Background Tap, and Terminated App Launch.
  void _setupMessageListeners() {
    // A. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[NOTIFICATION_RECEIVED_FOREGROUND] Message: ${message.messageId} | ${message.notification?.title}',
      );
      _handleForegroundMessage(message);
    });

    // B. Background App Open (User clicked notification from notification center)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[NOTIFICATION_OPENED] User opened app from notification: ${message.data}',
      );
      _handleNotificationTap(message.data);
    });

    // C. Terminated App Launch (App opened from dead state via notification tap)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          '[INITIAL_NOTIFICATION_RECEIVED] Launched from terminated state via: ${message.data}',
        );
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Displays an in-app heads-up notification when received while the app is active in foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    final matchId = message.data['match_id']?.toString();
    final eventType = message.data['event_type']?.toString();

    if (title == null || body == null) return;

    // Cross-channel deduplication with in-app tracker
    final score = message.data['score']?.toString() ?? '';
    final dedupKey = '${eventType}_${matchId}_$score';
    try {
      final prefs = await SharedPreferences.getInstance();
      final sentKeys = (prefs.getStringList('154score_sent_alert_keys') ?? []).toSet();
      if (sentKeys.contains(dedupKey)) {
        debugPrint('[PushNotificationService] Deduplicated already shown alert: $dedupKey');
        return;
      }
      sentKeys.add(dedupKey);
      final list = sentKeys.toList();
      if (list.length > 300) list.removeRange(0, list.length - 300);
      await prefs.setStringList('154score_sent_alert_keys', list);
    } catch (_) {}

    final payload = jsonEncode({
      'type': message.data['type'] ?? 'match',
      if (matchId != null) 'match_id': matchId,
      if (message.data['article_id'] != null)
        'article_id': message.data['article_id'],
    });

    final notifService = NotificationService.instance;

    if (eventType == 'goal') {
      await notifService.showGoalNotification(
        matchId: matchId ?? 'live',
        title: title,
        body: body,
        payload: payload,
      );
    } else if (eventType == 'match_start') {
      await notifService.showMatchStartNotification(
        matchId: matchId ?? 'live',
        title: title,
        body: body,
        payload: payload,
      );
    } else if (eventType == 'match_end') {
      await notifService.showMatchEndNotification(
        matchId: matchId ?? 'live',
        title: title,
        body: body,
        payload: payload,
      );
    } else if (eventType == 'lineup') {
      await notifService.showLineupNotification(
        matchId: matchId ?? 'live',
        title: title,
        body: body,
        payload: payload,
      );
    } else {
      await notifService.showNewsNotification(
        articleId: message.data['article_id']?.toString() ?? 'alert',
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  /// Handles payload navigation to Match Details or News Details.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final matchId = data['match_id']?.toString();
    if (matchId != null && matchId.isNotEmpty) {
      AppRouter.navigateToMatch(matchId);
      return;
    }

    final articleId = data['article_id']?.toString();
    if (articleId != null && articleId.isNotEmpty) {
      AppRouter.navigateToNews(articleId);
    }
  }
}
