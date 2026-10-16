import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/notifications/notification_service.dart';
import 'package:score154/core/notifications/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      '154score_fcm_device_token': 'fcm_test_token_sample_123',
    });
  });

  group('PushNotificationService Unit Tests', () {
    test('PushNotificationService instance is accessible and singleton', () {
      final p1 = PushNotificationService.instance;
      final p2 = PushNotificationService.instance;
      expect(p1, equals(p2));
    });

    test('buildNotificationPayload produces valid JSON string', () {
      final payload = buildNotificationPayload(
        type: 'match',
        matchId: '6106404',
      );
      expect(payload, contains('"type":"match"'));
      expect(payload, contains('"match_id":"6106404"'));
    });

    test('buildNotificationPayload with news produces valid JSON string', () {
      final payload = buildNotificationPayload(
        type: 'news',
        articleId: '14040707',
      );
      expect(payload, contains('"type":"news"'));
      expect(payload, contains('"article_id":"14040707"'));
    });

    test('Stable notification ID generation is deterministic and non-negative',
        () {
      final id1 = NotificationService.stableId('goal_6106404_1_1');
      final id2 = NotificationService.stableId('goal_6106404_1_1');
      final id3 = NotificationService.stableId('start_6106404');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1, isNonNegative);
    });
  });
}
