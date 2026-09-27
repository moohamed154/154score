import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/notifications/match_notification_tracker.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_favorite_teams': ['فيجي'],
      'app_notif_match_scope': 'starred_only',
      'notif_goals_enabled': true,
      'notif_start_end_enabled': true,
    });
  });

  group('MatchNotificationTracker Tests', () {
    test('Correctly identifies favorited team Fiji as tracked for notifications', () async {
      final tracker = MatchNotificationTracker.instance;

      const fijiMatch = MatchEntity(
        id: '5868020',
        team1: 'فيجي',
        team2: 'بابوا غينيا الجديدة',
        score1: '0',
        score2: '0',
        status: 'مباشر',
      );

      // Trigger ensurePrefs by processing initial baseline
      await tracker.processMatchUpdate(fijiMatch);

      expect(tracker.isMatchTracked(fijiMatch), isTrue);
    });

    test('Does not track matches when neither team is favorited', () async {
      final tracker = MatchNotificationTracker.instance;

      const otherMatch = MatchEntity(
        id: '999999',
        team1: 'تشيلي',
        team2: 'بيرو',
        score1: '0',
        score2: '0',
        status: 'مباشر',
      );

      await tracker.processMatchUpdate(otherMatch);

      expect(tracker.isMatchTracked(otherMatch), isFalse);
    });

    test('Goal score progression is detected without throwing errors', () async {
      final tracker = MatchNotificationTracker.instance;

      const initialMatch = MatchEntity(
        id: '5868021',
        team1: 'فيجي',
        team2: 'بابوا غينيا الجديدة',
        score1: '0',
        score2: '0',
        status: 'مباشر',
      );

      // Baseline
      await tracker.processMatchUpdate(initialMatch);

      // Goal 1: 1 - 0
      const goalMatch = MatchEntity(
        id: '5868021',
        team1: 'فيجي',
        team2: 'بابوا غينيا الجديدة',
        score1: '1',
        score2: '0',
        status: 'مباشر',
        minute: '23',
      );

      // Process update - should handle goal detection safely
      await tracker.processMatchUpdate(goalMatch);

      // Goal 2: 2 - 0
      const goal2Match = MatchEntity(
        id: '5868021',
        team1: 'فيجي',
        team2: 'بابوا غينيا الجديدة',
        score1: '2',
        score2: '0',
        status: 'مباشر',
        minute: '40',
      );

      await tracker.processMatchUpdate(goal2Match);
    });
  });
}
