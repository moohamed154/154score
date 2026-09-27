import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';

/// Service responsible for managing Apple Push Notification service (APNs)
/// device token registration and backend synchronization on iOS WITHOUT Firebase.
///
/// Architecture Overview:
/// 1. iOS App requests remote notification authorization via UserNotifications framework.
/// 2. iOS OS contacts Apple APNs servers and receives a unique 64-character APNs device token.
/// 3. AppDelegate passes token to Flutter via the 'com.hamdy.app154score/apns' MethodChannel.
/// 4. This service syncs the token and the user's subscribed teams/matches with your backend.
/// 5. Your backend pushes directly to Apple APNs HTTP/2 API (https://api.push.apple.com)
///    using your Apple Developer Team ID, Key ID, and .p8 private key.
///    Result: ZERO-DELAY (< 1s) delivery directly to iOS devices with NO Firebase SDK!
class ApnsNotificationService {
  static const MethodChannel _channel = MethodChannel('com.hamdy.app154score/apns');
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

      // Query native AppDelegate for token
      final token = await _channel.invokeMethod<String>('getApnsToken');
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        await prefs.setString(_prefApnsTokenKey, token);
        debugPrint('[ApnsNotificationService] Got APNs token: $token');
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
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefApnsTokenKey, token);
        debugPrint('[ApnsNotificationService] Received native APNs token: $token');
        await syncWithBackend();
      }
    }
  }

  /// Syncs the APNs token and user's favorite teams/matches with the backend server.
  Future<bool> syncWithBackend({
    List<String>? favoriteTeamIds,
    List<String>? favoriteMatchIds,
  }) async {
    if (!Platform.isIOS) return false;
    final token = _cachedToken;
    if (token == null || token.isEmpty) {
      debugPrint('[ApnsNotificationService] Token not available yet, skipping backend sync.');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final teams = favoriteTeamIds ?? prefs.getStringList('app_favorite_teams') ?? [];
      final matches = favoriteMatchIds ?? prefs.getStringList('app_favorite_matches') ?? [];
      final lang = prefs.getString('154score_notif_lang') ?? 'ar';

      final payload = {
        'token': token,
        'platform': 'ios',
        'bundle_id': 'com.hamdy.app154score',
        'teams': teams,
        'matches': matches,
        'lang': lang,
      };

      final dio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Attempt to register token with backend endpoint
      final response = await dio.post(
        '/api/notifications/register-token',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[ApnsNotificationService] Successfully registered APNs token with backend.');
        return true;
      }
    } catch (e) {
      // Backend may not have implemented the endpoint yet; non-blocking
      debugPrint('[ApnsNotificationService] Backend sync note (endpoint may be pending): $e');
    }
    return false;
  }
}
