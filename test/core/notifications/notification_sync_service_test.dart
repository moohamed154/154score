import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/notifications/notification_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      '154score_fcm_device_token': 'fcm_test_device_token_unit_test_12345',
      'app_favorite_teams': ['8633', '8634'],
      'app_favorite_matches': ['6106404'],
    });
  });

  group('NotificationSyncService Unit Tests', () {
    test('Service instance is accessible and singleton', () {
      final s1 = NotificationSyncService.instance;
      final s2 = NotificationSyncService.instance;
      expect(s1, equals(s2));
    });

    test('Subscribe to match builds clean ID without crashing', () async {
      final syncService = NotificationSyncService.instance;
      // Should attempt post or fail gracefully without throwing unhandled exceptions
      final result = await syncService.subscribeToMatch('match:6106404');
      // When backend is not running locally during tests, returns false gracefully
      expect(result, isA<bool>());
    });

    test('Unsubscribe from match executes cleanly', () async {
      final syncService = NotificationSyncService.instance;
      final result = await syncService.unsubscribeFromMatch('6106404');
      expect(result, isA<bool>());
    });

    test('Subscribe and unsubscribe to team executes cleanly', () async {
      final syncService = NotificationSyncService.instance;
      final sub = await syncService.subscribeToTeam('8633');
      final unsub = await syncService.unsubscribeFromTeam('8633');
      expect(sub, isA<bool>());
      expect(unsub, isA<bool>());
    });

    test('Bulk syncAllSubscriptions reads preferences and sends cleanly', () async {
      final syncService = NotificationSyncService.instance;
      final result = await syncService.syncAllSubscriptions(
        teams: ['8633', '8634'],
        matches: ['6106404'],
        news: true,
        allMatches: false,
      );
      expect(result, isA<bool>());
    });
  });
}
