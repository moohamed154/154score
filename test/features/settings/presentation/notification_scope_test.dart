import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/di/injection_container.dart';
import 'package:score154/core/notifications/match_notification_tracker.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorageService storage;
  late MatchNotificationTracker tracker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorageServiceImpl(prefs);
    if (sl.isRegistered<LocalStorageService>()) {
      await sl.unregister<LocalStorageService>();
    }
    sl.registerSingleton<LocalStorageService>(storage);
    tracker = MatchNotificationTracker.instance;
  });

  tearDown(() async {
    if (sl.isRegistered<LocalStorageService>()) {
      await sl.unregister<LocalStorageService>();
    }
  });

  group('Match Notification Scope Tests: Starred Only vs All Matches', () {
    const unstarredMatch = MatchEntity(
      id: 'match_1001',
      team1: 'Arsenal',
      team2: 'Chelsea',
      team1Id: '5001',
      team2Id: '5002',
      score1: '0',
      score2: '0',
      status: 'مباشر',
      statusCode: 'LIVE',
    );

    const starredMatch = MatchEntity(
      id: 'match_1002',
      team1: 'Real Madrid',
      team2: 'Barcelona',
      team1Id: '8633',
      team2Id: '8634',
      score1: '0',
      score2: '0',
      status: 'مباشر',
      statusCode: 'LIVE',
    );

    test('Mode 1: Starred Teams & Matches Only (Default)', () async {
      // Set to Starred Only
      await storage.setMatchNotificationScope(LocalStorageService.matchNotifScopeStarred);
      expect(storage.getMatchNotificationScope(), equals(LocalStorageService.matchNotifScopeStarred));

      // Star Real Madrid
      await storage.toggleFavoriteTeam('Real Madrid');
      expect(storage.isFavoriteTeam('Real Madrid'), isTrue);

      // Verify Unstarred Match (Arsenal vs Chelsea) is NOT tracked
      expect(tracker.isMatchTracked(unstarredMatch), isFalse);

      // Verify Starred Match (Real Madrid vs Barcelona) IS tracked
      expect(tracker.isMatchTracked(starredMatch), isTrue);
    });

    test('Mode 2: All Matches (جميع المباريات)', () async {
      // Set to All Matches
      await storage.setMatchNotificationScope(LocalStorageService.matchNotifScopeAll);
      expect(storage.getMatchNotificationScope(), equals(LocalStorageService.matchNotifScopeAll));

      // Verify BOTH Starred and Unstarred Matches ARE tracked
      expect(tracker.isMatchTracked(unstarredMatch), isTrue);
      expect(tracker.isMatchTracked(starredMatch), isTrue);
    });

    test('Dynamic Switching between Starred Only and All Matches', () async {
      // Star Arsenal
      await storage.toggleFavoriteTeam('Arsenal');

      // 1. Start with Starred Only
      await storage.setMatchNotificationScope(LocalStorageService.matchNotifScopeStarred);
      expect(tracker.isMatchTracked(unstarredMatch), isTrue); // Arsenal is starred
      expect(tracker.isMatchTracked(starredMatch), isFalse); // Real Madrid is not starred

      // 2. Switch to All Matches
      await storage.setMatchNotificationScope(LocalStorageService.matchNotifScopeAll);
      expect(tracker.isMatchTracked(unstarredMatch), isTrue);
      expect(tracker.isMatchTracked(starredMatch), isTrue);

      // 3. Switch back to Starred Only
      await storage.setMatchNotificationScope(LocalStorageService.matchNotifScopeStarred);
      expect(tracker.isMatchTracked(unstarredMatch), isTrue);
      expect(tracker.isMatchTracked(starredMatch), isFalse);
    });
  });
}
