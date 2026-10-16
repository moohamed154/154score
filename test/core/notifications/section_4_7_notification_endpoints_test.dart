import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/config/app_config.dart';
import 'package:score154/core/constants/api_endpoints.dart';
import 'package:score154/core/notifications/apns_notification_service.dart';
import 'package:score154/core/notifications/background_notification_task.dart';
import 'package:score154/core/notifications/notification_sync_service.dart';
import 'package:score154/core/notifications/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock interceptor to inspect requests, simulate responses (200, 404, 500),
/// or simulate network timeouts without hitting real backend servers.
class MockDioInterceptor extends Interceptor {
  final List<RequestOptions> recordedRequests = [];
  FutureOr<Response> Function(RequestOptions options)? onIntercept;

  MockDioInterceptor([this.onIntercept]);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    recordedRequests.add(options);
    if (onIntercept != null) {
      try {
        final res = await onIntercept!(options);
        handler.resolve(res);
      } on DioException catch (e) {
        handler.reject(e);
      } catch (e) {
        handler.reject(DioException(requestOptions: options, error: e));
      }
    } else {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'success', 'code': 200},
        ),
      );
    }
  }
}

Dio createMockDio(MockDioInterceptor interceptor) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  dio.interceptors.add(interceptor);
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      '154score_fcm_device_token': 'initial_fcm_token_123',
      '154score_notif_lang': 'ar',
      'app_favorite_teams': ['8633'],
      'app_favorite_matches': ['6106404'],
    });
  });

  group('Section 4.7 Mobile Notification Endpoints Integration Tests', () {
    // -------------------------------------------------------------------------
    // Test 1: Successful token registration
    // -------------------------------------------------------------------------
    test(
        '1. Successful token registration sends valid payload to /notifications/push_notifications_providers',
        () async {
      final interceptor = MockDioInterceptor();
      final dio = createMockDio(interceptor);

      final result =
          await PushNotificationService.instance.registerTokenWithBackend(
        'valid_device_token_abc',
        dioClient: dio,
        platformOverride: 'android',
      );

      expect(result, isTrue);
      expect(interceptor.recordedRequests.length, equals(1));

      final req = interceptor.recordedRequests.first;
      expect(req.path, equals(ApiEndpoints.pushNotificationsProviders));
      expect(req.method, equals('POST'));

      final payload = req.data as Map<String, dynamic>;
      expect(payload['token'], equals('valid_device_token_abc'));
      expect(payload['platform'], equals('android'));
      expect(payload['app_version'], equals(AppConfig.appVersion));
      expect(payload['language'], equals('ar'));
      expect(req.headers['X-API-Key'], isNotEmpty);
      expect(req.headers['Accept'], equals('application/json'));
    });

    // -------------------------------------------------------------------------
    // Test 2: Token refresh registration
    // -------------------------------------------------------------------------
    test('2. Token refresh registration updates stored token and sends request',
        () async {
      final interceptor = MockDioInterceptor();
      final dio = createMockDio(interceptor);

      final result =
          await PushNotificationService.instance.registerTokenWithBackend(
        'refreshed_device_token_xyz',
        dioClient: dio,
        platformOverride: 'ios',
      );

      expect(result, isTrue);
      expect(interceptor.recordedRequests.length, equals(1));

      final req = interceptor.recordedRequests.first;
      final payload = req.data as Map<String, dynamic>;
      expect(payload['token'], equals('refreshed_device_token_xyz'));
      expect(payload['platform'], equals('ios'));
      expect(payload['app_version'], isNotEmpty);
      expect(payload['old_token'], equals('initial_fcm_token_123'));

      // Check SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('154score_fcm_device_token'),
          equals('refreshed_device_token_xyz'));
    });

    // -------------------------------------------------------------------------
    // Test 3: Successful subscribe request
    // -------------------------------------------------------------------------
    test(
        '3. Successful subscribe request sends device_token, action, target_type, target_id',
        () async {
      final interceptor = MockDioInterceptor();
      final dio = createMockDio(interceptor);

      final result = await NotificationSyncService.instance.subscribeToTeam(
        '8633',
        dioClient: dio,
        tokenOverride: 'valid_token_123',
      );

      expect(result, isTrue);
      expect(interceptor.recordedRequests.length, equals(1));

      final req = interceptor.recordedRequests.first;
      expect(req.path, equals(ApiEndpoints.notificationPostService));
      expect(req.method, equals('POST'));

      final payload = req.data as Map<String, dynamic>;
      expect(payload['device_token'], equals('valid_token_123'));
      expect(payload['action'], equals('subscribe'));
      expect(payload['target_type'], equals('team'));
      expect(payload['target_id'], equals('8633'));
    });

    // -------------------------------------------------------------------------
    // Test 4: Successful unsubscribe request
    // -------------------------------------------------------------------------
    test('4. Successful unsubscribe request sends correct action and payload',
        () async {
      final interceptor = MockDioInterceptor();
      final dio = createMockDio(interceptor);

      final result =
          await NotificationSyncService.instance.unsubscribeFromMatch(
        '6106404',
        dioClient: dio,
        tokenOverride: 'valid_token_123',
      );

      expect(result, isTrue);
      expect(interceptor.recordedRequests.length, equals(1));

      final req = interceptor.recordedRequests.first;
      expect(req.path, equals(ApiEndpoints.notificationPostService));

      final payload = req.data as Map<String, dynamic>;
      expect(payload['device_token'], equals('valid_token_123'));
      expect(payload['action'], equals('unsubscribe'));
      expect(payload['target_type'], equals('match'));
      expect(payload['target_id'], equals('6106404'));
    });

    // -------------------------------------------------------------------------
    // Test 5: 404 fallback from /notifications/... to /api/notifications/...
    // -------------------------------------------------------------------------
    test(
        '5. 404 fallback from /notifications/... to /api/notifications/... triggers on 404 only',
        () async {
      final interceptor = MockDioInterceptor((options) {
        if (options.path == ApiEndpoints.pushNotificationsProviders) {
          // Primary route returns 404 Route Not Found
          throw DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 404),
          );
        }
        // Fallback route returns 200 OK
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'success'},
        );
      });
      final dio = createMockDio(interceptor);

      final result =
          await PushNotificationService.instance.registerTokenWithBackend(
        'token_for_fallback_test',
        dioClient: dio,
      );

      expect(result, isTrue);
      expect(interceptor.recordedRequests.length, equals(2));
      expect(interceptor.recordedRequests[0].path,
          equals(ApiEndpoints.pushNotificationsProviders));
      expect(interceptor.recordedRequests[1].path,
          equals(ApiEndpoints.pushNotificationsProvidersFallback));
    });

    // -------------------------------------------------------------------------
    // Test 6: No duplicate request after a successful response
    // -------------------------------------------------------------------------
    test('6. No duplicate request sent when the primary request succeeds',
        () async {
      final interceptor = MockDioInterceptor((options) {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true},
        );
      });
      final dio = createMockDio(interceptor);

      // A. Token registration
      await PushNotificationService.instance.registerTokenWithBackend(
        'token_single_call',
        dioClient: dio,
      );
      expect(interceptor.recordedRequests.length, equals(1));
      expect(interceptor.recordedRequests.first.path,
          equals(ApiEndpoints.pushNotificationsProviders));

      // B. Notification sync service
      interceptor.recordedRequests.clear();
      await NotificationSyncService.instance.subscribeToMatch(
        '12345',
        dioClient: dio,
        tokenOverride: 'token_single_call',
      );
      expect(interceptor.recordedRequests.length, equals(1));
      expect(interceptor.recordedRequests.first.path,
          equals(ApiEndpoints.notificationPostService));

      // C. Background task
      interceptor.recordedRequests.clear();
      await triggerMatchReminderBackgroundTask(dioClient: dio);
      expect(interceptor.recordedRequests.length, equals(1));
      expect(interceptor.recordedRequests.first.path,
          equals(ApiEndpoints.matchReminderBackgroundTask));
    });

    // -------------------------------------------------------------------------
    // Test 7: Empty token rejection
    // -------------------------------------------------------------------------
    test(
        '7. Empty and whitespace tokens are rejected without making network calls',
        () async {
      final interceptor = MockDioInterceptor();
      final dio = createMockDio(interceptor);

      // A. Empty string
      final resEmpty =
          await PushNotificationService.instance.registerTokenWithBackend(
        '',
        dioClient: dio,
      );
      expect(resEmpty, isFalse);

      // B. Whitespace string
      final resWhitespace =
          await PushNotificationService.instance.registerTokenWithBackend(
        '     ',
        dioClient: dio,
      );
      expect(resWhitespace, isFalse);

      // C. Sync service with empty token
      final resSync =
          await NotificationSyncService.instance.sendSubscriptionAction(
        action: 'subscribe',
        targetType: 'team',
        targetId: '8633',
        dioClient: dio,
        tokenOverride: '   ',
      );
      expect(resSync, isFalse);

      // Ensure no HTTP request was transmitted
      expect(interceptor.recordedRequests, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 8: Network timeout and retry behavior
    // -------------------------------------------------------------------------
    test(
        '8. Network timeout does not trigger 404 fallback and preserves offline action in queue',
        () async {
      int requestCount = 0;
      final interceptor = MockDioInterceptor((options) {
        requestCount++;
        // Simulate a network connection timeout
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout error',
        );
      });
      final dio = createMockDio(interceptor);

      final result = await NotificationSyncService.instance.subscribeToTeam(
        '9999',
        dioClient: dio,
        tokenOverride: 'offline_token_test',
      );

      expect(result, isFalse);
      // Fallback MUST NOT trigger on connection timeout (only on 404)
      expect(requestCount, equals(1));

      // Verify action was enqueued into SharedPreferences for offline recovery
      final prefs = await SharedPreferences.getInstance();
      final queued =
          prefs.getStringList('154score_pending_notification_actions');
      expect(queued, isNotNull);
      expect(queued!.isNotEmpty, isTrue);
      expect(queued.first, contains('9999'));
      expect(queued.first, contains('team'));
      expect(queued.first, contains('subscribe'));

      // Test recovery: when connection is restored, processPendingActions drains the queue
      final recoveryInterceptor = MockDioInterceptor();
      final recoveryDio = createMockDio(recoveryInterceptor);

      await NotificationSyncService.instance.processPendingActions(
        dioClient: recoveryDio,
        tokenOverride: 'offline_token_test',
      );

      expect(recoveryInterceptor.recordedRequests.length, equals(1));
      final remainingQueue =
          prefs.getStringList('154score_pending_notification_actions');
      expect(remainingQueue, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 9: Background task execution
    // -------------------------------------------------------------------------
    test(
        '9. Background task sends POST /notifications/match_reminder_background_task with source',
        () async {
      final interceptor = MockDioInterceptor();
      final dio = createMockDio(interceptor);

      final success = await triggerMatchReminderBackgroundTask(dioClient: dio);

      expect(success, isTrue);
      expect(interceptor.recordedRequests.length, equals(1));

      final req = interceptor.recordedRequests.first;
      expect(req.path, equals(ApiEndpoints.matchReminderBackgroundTask));
      expect(req.method, equals('POST'));

      final payload = req.data as Map<String, dynamic>;
      expect(payload['source'], equals('mobile_background_task'));
      expect(payload['timestamp'], isNotNull);
      expect(req.headers['X-API-Key'], isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 10: Background task failure handling
    // -------------------------------------------------------------------------
    test(
        '10. Background task handles HTTP 500 and network errors safely without uncaught exceptions',
        () async {
      final interceptor = MockDioInterceptor((options) {
        throw DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 500),
          type: DioExceptionType.badResponse,
        );
      });
      final dio = createMockDio(interceptor);

      // Must catch safely and return false without throwing
      final success = await triggerMatchReminderBackgroundTask(dioClient: dio);
      expect(success, isFalse);

      // Verify runNotificationPoll also executes and swallows errors without unhandled exceptions
      await expectLater(
        runNotificationPoll(dioClient: dio),
        completes,
      );
    });

    // -------------------------------------------------------------------------
    // Extra Test: ApnsNotificationService syncWithBackend
    // -------------------------------------------------------------------------
    test(
        '11. ApnsNotificationService uses Section 4.7 notificationPostService route with strict 404 fallback',
        () async {
      final interceptor = MockDioInterceptor((options) {
        if (options.path == ApiEndpoints.notificationPostService) {
          throw DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 404),
          );
        }
        return Response(requestOptions: options, statusCode: 200);
      });
      final dio = createMockDio(interceptor);

      final success = await ApnsNotificationService.instance.syncWithBackend(
        favoriteTeamIds: ['8633'],
        favoriteMatchIds: ['6106404'],
        dioClient: dio,
        tokenOverride: 'apns_hex_token_123',
      );

      expect(success, isTrue);
      expect(interceptor.recordedRequests.length, equals(2));
      expect(interceptor.recordedRequests[0].path,
          equals(ApiEndpoints.notificationPostService));
      expect(interceptor.recordedRequests[1].path,
          equals(ApiEndpoints.notificationPostServiceFallback));
    });
  });
}
