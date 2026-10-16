import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../security/security_signer.dart';
import 'push_notification_service.dart';

/// Service responsible for synchronizing user notification subscriptions
/// (matches, favorite teams, news) with the 154Score backend using:
/// POST /notifications/notification_post_service (with fallback to /api/notifications/... ONLY on 404)
class NotificationSyncService {
  NotificationSyncService._();
  static final NotificationSyncService instance = NotificationSyncService._();

  static const String _prefPendingActionsKey =
      '154score_pending_notification_actions';

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
    if (liveToken != null && liveToken.trim().isNotEmpty)
      return liveToken.trim();

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('154score_fcm_device_token') ??
        prefs.getString('apns_device_token');
    return (cached != null && cached.trim().isNotEmpty) ? cached.trim() : null;
  }

  /// Bulk syncs all favorite teams and matches with the backend server.
  /// Also drains any pending offline subscription actions.
  Future<bool> syncAllSubscriptions({
    List<String>? teams,
    List<String>? matches,
    bool news = true,
    bool allMatches = false,
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    final token = tokenOverride ?? await _getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint(
          '[NotificationSyncService] Token not available yet, queuing sync.');
      return false;
    }
    final cleanToken = token.trim();

    final dio = dioClient ?? _getDio();

    // First, drain any pending actions that were queued while offline
    await processPendingActions(dioClient: dio, tokenOverride: cleanToken);

    try {
      final prefs = await SharedPreferences.getInstance();
      final targetTeams =
          teams ?? prefs.getStringList('app_favorite_teams') ?? [];
      final targetMatches =
          matches ?? prefs.getStringList('app_favorite_matches') ?? [];
      final scope = prefs.getString('app_notif_match_scope');
      final isAllMatches = allMatches || scope == 'all_matches';
      final lang = prefs.getString('app_language') ??
          prefs.getString('154score_notif_lang') ??
          'ar';

      final payload = {
        'device_token': cleanToken,
        'token': cleanToken,
        'teams': targetTeams,
        'matches': targetMatches
            .map((m) => m.replaceAll('match:', '').trim())
            .where((m) => m.isNotEmpty)
            .toList(),
        'news': news,
        'all_matches': isAllMatches,
        'lang': lang,
        'language': lang,
      };

      final response = await _postWithFallback(
        dio,
        ApiEndpoints.notificationPostService,
        ApiEndpoints.notificationPostServiceFallback,
        payload,
      );

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
  Future<bool> subscribeToMatch(
    String matchId, {
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    return sendSubscriptionAction(
      action: 'subscribe',
      targetType: 'match',
      targetId: matchId.replaceAll('match:', '').trim(),
      dioClient: dioClient,
      tokenOverride: tokenOverride,
    );
  }

  /// Unsubscribes the current device from a specific match.
  Future<bool> unsubscribeFromMatch(
    String matchId, {
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    return sendSubscriptionAction(
      action: 'unsubscribe',
      targetType: 'match',
      targetId: matchId.replaceAll('match:', '').trim(),
      dioClient: dioClient,
      tokenOverride: tokenOverride,
    );
  }

  /// Subscribes the current device to a specific team.
  Future<bool> subscribeToTeam(
    String teamId, {
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    return sendSubscriptionAction(
      action: 'subscribe',
      targetType: 'team',
      targetId: teamId.trim(),
      dioClient: dioClient,
      tokenOverride: tokenOverride,
    );
  }

  /// Unsubscribes the current device from a specific team.
  Future<bool> unsubscribeFromTeam(
    String teamId, {
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    return sendSubscriptionAction(
      action: 'unsubscribe',
      targetType: 'team',
      targetId: teamId.trim(),
      dioClient: dioClient,
      tokenOverride: tokenOverride,
    );
  }

  /// Sends a single subscription action to POST /notifications/notification_post_service.
  /// Expected payload:
  /// {
  ///   "device_token": "...",
  ///   "action": "subscribe|unsubscribe",
  ///   "target_type": "...",
  ///   "target_id": "..."
  /// }
  /// Rejects empty tokens. Falls back to /api/notifications/... ONLY on 404.
  /// If offline/network failure occurs, action is persisted to SharedPreferences queue so it is not lost.
  Future<bool> sendSubscriptionAction({
    required String action,
    required String targetType,
    required String targetId,
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    final cleanTargetId = targetId.trim();
    if (cleanTargetId.isEmpty) return false;

    final token = tokenOverride ?? await _getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint(
          '[NotificationSyncService] Empty or null device token rejected.');
      // Enqueue action without token for later retry when token becomes available
      await _enqueuePendingAction({
        'action': action,
        'target_type': targetType,
        'target_id': cleanTargetId,
      });
      return false;
    }
    final cleanToken = token.trim();

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ??
        prefs.getString('154score_notif_lang') ??
        'ar';

    final payload = {
      'device_token': cleanToken,
      'token': cleanToken,
      'action': action,
      'target_type': targetType,
      'type': targetType,
      'target_id': cleanTargetId,
      'lang': lang,
      'language': lang,
    };

    final dio = dioClient ?? _getDio();

    try {
      final response = await _postWithFallback(
        dio,
        ApiEndpoints.notificationPostService,
        ApiEndpoints.notificationPostServiceFallback,
        payload,
      );

      final status = response?.statusCode;
      if (status == 200 || status == 201) {
        return true;
      }
    } on DioException catch (e) {
      debugPrint(
          '[NotificationSyncService] Network error during $action $targetType: $e');
      // If it's a network error (offline/timeout), enqueue so changes are not lost
      if (_isNetworkOrOfflineError(e)) {
        await _enqueuePendingAction(payload);
      }
    } catch (e) {
      debugPrint('[NotificationSyncService] _sendSubscriptionAction error: $e');
    }

    return false;
  }

  /// Fallback occurs ONLY for HTTP 404 (Route Not Found), NOT for every error.
  /// Does not send duplicate requests when the first request succeeds.
  Future<Response?> _postWithFallback(
    Dio dio,
    String primaryRoute,
    String fallbackRoute,
    Map<String, dynamic> payload,
  ) async {
    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': '154Score-Flutter/1.0',
      'X-API-Key': AppConfig.validateApiKey(),
    };
    try {
      final sigHeaders = SecuritySigner.buildSecurityHeaders(
        method: 'POST',
        path: primaryRoute,
      );
      return await dio.post(
        primaryRoute,
        data: payload,
        options: Options(headers: {...requestHeaders, ...sigHeaders}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint(
          '[NotificationSyncService] 404 on $primaryRoute, falling back to $fallbackRoute',
        );
        final fallbackSig = SecuritySigner.buildSecurityHeaders(
          method: 'POST',
          path: fallbackRoute,
        );
        return await dio.post(
          fallbackRoute,
          data: payload,
          options: Options(headers: {...requestHeaders, ...fallbackSig}),
        );
      }
      rethrow;
    }
  }

  bool _isNetworkOrOfflineError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  /// Enqueues pending action to SharedPreferences so offline actions are not lost.
  Future<void> _enqueuePendingAction(Map<String, dynamic> action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefPendingActionsKey) ?? [];
      list.add(jsonEncode(action));
      await prefs.setStringList(_prefPendingActionsKey, list);
      debugPrint(
        '[NotificationSyncService] Enqueued pending action for offline resilience: ${action['action']} ${action['target_type']} ${action['target_id']}',
      );
    } catch (_) {}
  }

  /// Replays and drains pending subscription actions.
  Future<void> processPendingActions({
    Dio? dioClient,
    String? tokenOverride,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefPendingActionsKey);
      if (list == null || list.isEmpty) return;

      final token = tokenOverride ?? await _getToken();
      if (token == null || token.trim().isEmpty) return;
      final cleanToken = token.trim();

      final dio = dioClient ?? _getDio();
      final remaining = <String>[];

      for (final raw in list) {
        try {
          final action = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          action['device_token'] = cleanToken;
          action['token'] = cleanToken;
          final res = await _postWithFallback(
            dio,
            ApiEndpoints.notificationPostService,
            ApiEndpoints.notificationPostServiceFallback,
            action,
          );
          if (res?.statusCode != 200 && res?.statusCode != 201) {
            remaining.add(raw);
          }
        } catch (_) {
          remaining.add(raw);
        }
      }

      await prefs.setStringList(_prefPendingActionsKey, remaining);
    } catch (_) {}
  }
}
