import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router/app_router.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import 'notification_service.dart';

/// Central service managing push notifications, OS permissions,
/// backend device token registration (Section 4.7), and notification tap routing.
/// Native APNs on iOS and native local notifications operate directly without Firebase SDK.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _prefFcmTokenKey = '154score_fcm_device_token';

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize notification permissions, register any stored token,
  /// and prepare routing listeners.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 0. Startup Trigger: If valid token exists in storage, register immediately
      final prefs = await SharedPreferences.getInstance();
      final existingToken = prefs.getString(_prefFcmTokenKey) ??
          prefs.getString('apns_device_token');
      if (existingToken != null && existingToken.trim().isNotEmpty) {
        _fcmToken = existingToken.trim();
        debugPrint(
          '[PushNotificationService] Valid token exists on startup, registering with backend.',
        );
        unawaited(registerTokenWithBackend(_fcmToken!));
      }

      // Initialize local notifications service
      await NotificationService.instance.initialize(
        onNotificationTap: (payload) {
          if (payload != null && payload.isNotEmpty) {
            AppRouter.handleNotificationPayload(payload);
          }
        },
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error: $e');
    }
  }

  /// Sends the device token to: POST /notifications/push_notifications_providers
  /// Expected payload: { "token": "...", "platform": "android|ios", "app_version": "...", "language": "..." }
  /// Triggers: token obtained, token refreshed, app startup.
  /// Rejects empty/null tokens. Falls back to /api/notifications/... ONLY on 404.
  Future<bool> registerTokenWithBackend(
    String token, {
    Dio? dioClient,
    String? platformOverride,
  }) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      debugPrint('[PushNotificationService] Rejecting empty or whitespace token registration.');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_prefFcmTokenKey);
      final lang = prefs.getString('154score_notif_lang') ?? 'ar';
      final platform = platformOverride ??
          (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
      const appVersion = AppConfig.appVersion;

      final payload = {
        'token': cleanToken,
        'platform': platform,
        'app_version': appVersion,
        'language': lang,
        'lang': lang,
        'bundle_id': 'com.hamdy.app154score',
        if (oldToken != null && oldToken != cleanToken) 'old_token': oldToken,
      };

      final requestHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': '154Score-Flutter/1.0',
        'X-API-Key': AppConfig.validateApiKey(),
      };

      final dio = dioClient ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: requestHeaders,
            ),
          );

      // Attempt primary route; fallback to /api prefix ONLY on HTTP 404 (Route Not Found)
      Response response;
      try {
        response = await dio.post(
          ApiEndpoints.pushNotificationsProviders,
          data: payload,
          options: Options(headers: requestHeaders),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint(
            '[PushNotificationService] 404 on ${ApiEndpoints.pushNotificationsProviders}, falling back to ${ApiEndpoints.pushNotificationsProvidersFallback}',
          );
          response = await dio.post(
            ApiEndpoints.pushNotificationsProvidersFallback,
            data: payload,
            options: Options(headers: requestHeaders),
          );
        } else {
          rethrow;
        }
      }

      final status = response.statusCode;
      if (status == 200 || status == 201) {
        await prefs.setString(_prefFcmTokenKey, cleanToken);
        _fcmToken = cleanToken;
        debugPrint(
          '[FCM_TOKEN_REGISTERED] Registered with backend: ${cleanToken.substring(0, cleanToken.length > 10 ? 10 : cleanToken.length)}...',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to register token with backend: $e');
    }
    return false;
  }

  /// Displays an in-app heads-up notification when received while the app is active in foreground.
  Future<void> handleForegroundPayload(Map<String, dynamic> data) async {
    final title = data['title']?.toString();
    final body = data['body']?.toString();
    final matchId = data['match_id']?.toString();
    final eventType = data['event_type']?.toString();

    if (title == null || body == null) return;

    // Cross-channel deduplication with in-app tracker
    final score = data['score']?.toString() ?? '';
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
      'type': data['type'] ?? 'match',
      if (matchId != null) 'match_id': matchId,
      if (data['article_id'] != null)
        'article_id': data['article_id'],
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
        articleId: data['article_id']?.toString() ?? 'alert',
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  /// Handles payload navigation to Match Details or News Details.
  void handleNotificationTap(Map<String, dynamic> data) {
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
