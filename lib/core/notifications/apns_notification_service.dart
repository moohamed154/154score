import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import 'push_notification_service.dart';

/// Service responsible for managing Apple Push Notification service (APNs)
/// device token registration and backend synchronization on iOS WITHOUT Firebase.
///
/// Architecture Overview:
/// 1. iOS App requests remote notification authorization via UserNotifications framework.
/// 2. iOS OS contacts Apple APNs servers and receives a unique 64-character APNs device token.
/// 3. AppDelegate passes token to Flutter via the 'com.hamdy.app154score/apns' MethodChannel.
/// 4. This service registers the token with POST /notifications/push_notifications_providers
///    and syncs subscriptions with POST /notifications/notification_post_service.
/// 5. Your backend pushes directly to Apple APNs HTTP/2 API (https://api.push.apple.com)
///    using your Apple Developer Team ID, Key ID, and .p8 private key.
///    Result: ZERO-DELAY (< 1s) delivery directly to iOS devices with NO Firebase SDK!
/// Local notifications work directly via UserNotifications and do not require Firebase.
class ApnsNotificationService {
  static const MethodChannel _channel = MethodChannel(
    'com.hamdy.app154score/apns',
  );
  static const String _prefApnsTokenKey = 'apns_device_token';

  static final ApnsNotificationService instance = ApnsNotificationService._();
  ApnsNotificationService._() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  String? _cachedToken;

  /// Retrieve the cached or active APNs device token.
  String? get apnsToken => _cachedToken;

  /// Initialize and query native iOS APNs token.
  Future<void> initialize() async {
    if (!Platform.isIOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_prefApnsTokenKey);

      // Startup trigger: if cached APNs token exists, register with backend
      if (_cachedToken != null && _cachedToken!.trim().isNotEmpty) {
        debugPrint(
            '[ApnsNotificationService] Startup: registering cached APNs token.');
        await PushNotificationService.instance.registerTokenWithBackend(
          _cachedToken!.trim(),
          platformOverride: 'ios',
        );
      }

      // Query native AppDelegate for token
      final token = await _channel.invokeMethod<String>('getApnsToken');
      if (token != null && token.trim().isNotEmpty) {
        final cleanToken = token.trim();
        _cachedToken = cleanToken;
        await prefs.setString(_prefApnsTokenKey, cleanToken);
        debugPrint('[ApnsNotificationService] Got APNs token: $cleanToken');
        await PushNotificationService.instance.registerTokenWithBackend(
          cleanToken,
          platformOverride: 'ios',
        );
        await syncWithBackend();
      } else {
        // Request registration if not yet registered
        await _channel.invokeMethod('registerForRemoteNotifications');
      }
    } catch (e) {
      debugPrint('[ApnsNotificationService] initialize error: $e');
    }
  }

  /// Handle incoming calls from native AppDelegate (e.g. token received asynchronously).
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onTokenReceived') {
      final token = call.arguments?.toString();
      if (token == null || token.trim().isEmpty) {
        debugPrint(
            '[ApnsNotificationService] Empty or null native APNs token received, rejecting.');
        return;
      }
      final cleanToken = token.trim();
      _cachedToken = cleanToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefApnsTokenKey, cleanToken);
      debugPrint(
        '[ApnsNotificationService] Received native APNs token: $cleanToken',
      );
      // Section 4.7 Endpoint 1: Register APNs device token
      await PushNotificationService.instance.registerTokenWithBackend(
        cleanToken,
        platformOverride: 'ios',
      );
      // Section 4.7 Endpoint 2: Sync subscriptions
      await syncWithBackend();
    }
  }

  /// Syncs the APNs token and user's favorite teams/matches with Section 4.7 endpoint:
  /// POST /notifications/notification_post_service (with fallback to /api/notifications/... ONLY on 404).
  Future<bool> syncWithBackend({
    List<String>? favoriteTeamIds,
    List<String>? favoriteMatchIds,
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    final token = tokenOverride ?? _cachedToken;
    if (token == null || token.trim().isEmpty) {
      debugPrint(
        '[ApnsNotificationService] Token not available or empty, skipping backend sync.',
      );
      return false;
    }
    final cleanToken = token.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final teams =
          favoriteTeamIds ?? prefs.getStringList('app_favorite_teams') ?? [];
      final matches =
          favoriteMatchIds ?? prefs.getStringList('app_favorite_matches') ?? [];
      final lang = prefs.getString('154score_notif_lang') ?? 'ar';

      final payload = {
        'device_token': cleanToken,
        'token': cleanToken,
        'platform': 'ios',
        'action': 'subscribe',
        'target_type': 'all',
        'teams': teams,
        'matches': matches,
        'language': lang,
        'lang': lang,
        'bundle_id': 'com.hamdy.app154score',
      };

      final dio = dioClient ??
          Dio(
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

      Response? response;
      try {
        response = await dio.post(
          ApiEndpoints.notificationPostService,
          data: payload,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint(
            '[ApnsNotificationService] 404 on ${ApiEndpoints.notificationPostService}, falling back to ${ApiEndpoints.notificationPostServiceFallback}',
          );
          response = await dio.post(
            ApiEndpoints.notificationPostServiceFallback,
            data: payload,
          );
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[ApnsNotificationService] Successfully registered APNs subscriptions with backend.',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[ApnsNotificationService] Backend sync note: $e');
    }
    return false;
  }
}
