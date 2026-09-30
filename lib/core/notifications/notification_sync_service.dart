import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import 'push_notification_service.dart';

/// Service responsible for synchronizing user notification subscriptions
/// (matches, favorite teams, news) with the 154Score backend using:
/// POST /notifications/notification_post_service
class NotificationSyncService {
  NotificationSyncService._();
  static final NotificationSyncService instance = NotificationSyncService._();

  Dio? _dio;

  Dio _getDio() {
    _dio ??= Dio(
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
    return _dio!;
  }

  Future<String?> _getToken() async {
    final liveToken = PushNotificationService.instance.fcmToken;
    if (liveToken != null && liveToken.isNotEmpty) return liveToken;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('154score_fcm_device_token');
  }

  /// Bulk syncs all favorite teams and matches with the backend server.
  Future<bool> syncAllSubscriptions({
    List<String>? teams,
    List<String>? matches,
    bool news = true,
    bool allMatches = false,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[NotificationSyncService] Token not available yet, queuing sync.');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final targetTeams =
          teams ?? prefs.getStringList('app_favorite_teams') ?? [];
      final targetMatches =
          matches ?? prefs.getStringList('app_favorite_matches') ?? [];

      final payload = {
        'token': token,
        'teams': targetTeams,
        'matches': targetMatches.map((m) => m.replaceAll('match:', '').trim()).toList(),
        'news': news,
        'all_matches': allMatches,
      };

      final dio = _getDio();
      Response? response;
      try {
        response = await dio.post(
          '/notifications/notification_post_service',
          data: payload,
        );
      } catch (_) {
        try {
          response = await dio.post(
            '/api/notifications/notification_post_service',
            data: payload,
          );
        } catch (_) {}
      }

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        debugPrint(
          '[NotificationSyncService] Subscriptions synchronized with backend (${targetTeams.length} teams, ${targetMatches.length} matches)',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[NotificationSyncService] syncAllSubscriptions error: $e');
    }
    return false;
  }

  /// Subscribes the current device to a specific match.
  Future<bool> subscribeToMatch(String matchId) async {
    return _sendSubscriptionAction(
      action: 'subscribe',
      type: 'match',
      targetId: matchId.replaceAll('match:', '').trim(),
    );
  }

  /// Unsubscribes the current device from a specific match.
  Future<bool> unsubscribeFromMatch(String matchId) async {
    return _sendSubscriptionAction(
      action: 'unsubscribe',
      type: 'match',
      targetId: matchId.replaceAll('match:', '').trim(),
    );
  }

  /// Subscribes the current device to a specific team.
  Future<bool> subscribeToTeam(String teamId) async {
    return _sendSubscriptionAction(
      action: 'subscribe',
      type: 'team',
      targetId: teamId.trim(),
    );
  }

  /// Unsubscribes the current device from a specific team.
  Future<bool> unsubscribeFromTeam(String teamId) async {
    return _sendSubscriptionAction(
      action: 'unsubscribe',
      type: 'team',
      targetId: teamId.trim(),
    );
  }

  Future<bool> _sendSubscriptionAction({
    required String action,
    required String type,
    required String targetId,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final payload = {
        'token': token,
        'action': action,
        'type': type,
        'target_id': targetId,
      };

      final dio = _getDio();
      Response? response;
      try {
        response = await dio.post(
          '/notifications/notification_post_service',
          data: payload,
        );
      } catch (_) {
        try {
          response = await dio.post(
            '/api/notifications/notification_post_service',
            data: payload,
          );
        } catch (_) {}
      }

      return response != null &&
          (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('[NotificationSyncService] _sendSubscriptionAction error: $e');
      return false;
    }
  }
}
