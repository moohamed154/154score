import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unified Favorite Competitions Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;
    late FavoritesCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageServiceImpl(prefs);
      cubit = FavoritesCubit(storage);
    });

    tearDown(() {
      cubit.close();
    });

    test('1. Default state: Featured competitions are returned before custom changes', () {
      expect(storage.hasCustomFavoriteCompetitions(), isFalse);
      final defaultFavs = storage.getFavoriteCompetitions();
      expect(defaultFavs, contains('الدوري الإسباني'));
      expect(defaultFavs, contains('دوري أبطال أوروبا'));
      expect(defaultFavs, contains('الدوري الإنجليزي الممتاز'));

      // Both name and ID for La Liga match out of the box
      expect(storage.isFavoriteCompetition(name: 'الدوري الإسباني'), isTrue);
      expect(storage.isFavoriteCompetition(id: '1933'), isTrue);
      expect(storage.isFavoriteCompetition(id: '938652'), isTrue);
      expect(cubit.isCompetitionFavorite(name: 'الدوري الإسباني'), isTrue);
      expect(cubit.isCompetitionFavorite(id: '1933'), isTrue);
    });

    test('2. Unfavoriting a league from LeagueView (by title or ID) removes it completely', () async {
      // Initially favorite
      expect(storage.isFavoriteCompetition(id: '938652', name: 'الدوري الإسباني'), isTrue);

      // User taps star in LeagueView (calling toggleCompetition with id & name)
      await cubit.toggleCompetition(id: '938652', name: 'الدوري الإسباني');

      // Must be false everywhere
      expect(storage.hasCustomFavoriteCompetitions(), isTrue);
      expect(cubit.isCompetitionFavorite(name: 'الدوري الإسباني'), isFalse);
      expect(cubit.isCompetitionFavorite(id: '938652'), isFalse);
      expect(cubit.isCompetitionFavorite(id: '1933'), isFalse);
      expect(storage.isFavoriteCompetition(name: 'الدوري الإسباني'), isFalse);
      expect(storage.isFavoriteCompetition(id: '938652'), isFalse);
      expect(storage.getFavoriteCompetitions(), isNot(contains('الدوري الإسباني')));
    });

    test('3. Favoriting a new league from Matches or Standings works across all screens', () async {
      const newLeagueId = '5555';
      const newLeagueName = 'كأس مصر';

      expect(cubit.isCompetitionFavorite(id: newLeagueId, name: newLeagueName), isFalse);

      // Favorited from Matches screen via LeagueSectionWidget
      await cubit.toggleCompetition(id: newLeagueId, name: newLeagueName);

      // Must be true everywhere
      expect(cubit.isCompetitionFavorite(id: newLeagueId, name: newLeagueName), isTrue);
      expect(cubit.isCompetitionFavorite(name: newLeagueName), isTrue);
      expect(cubit.isCompetitionFavorite(id: newLeagueId), isTrue);
      expect(storage.isFavoriteCompetition(id: newLeagueId, name: newLeagueName), isTrue);
      expect(storage.resolveCompetitionTitle(newLeagueId), equals(newLeagueName));

      // Now unfavorite it from StandingsView (by id only or id+name)
      await cubit.toggleCompetition(id: newLeagueId);

      expect(cubit.isCompetitionFavorite(id: newLeagueId, name: newLeagueName), isFalse);
      expect(cubit.isCompetitionFavorite(name: newLeagueName), isFalse);
      expect(storage.isFavoriteCompetition(id: newLeagueId, name: newLeagueName), isFalse);
    });

    test('4. Dynamic title registration resolves IDs to human-readable names for FavoritesView', () async {
      await storage.registerCompetitionTitles({
        '7777': 'دوري روشن للمحترفين',
        '8888': 'كأس ملك إسبانيا',
      });

      expect(storage.resolveCompetitionTitle('7777'), equals('دوري روشن للمحترفين'));
      expect(storage.resolveCompetitionTitle('8888'), equals('كأس ملك إسبانيا'));
      expect(storage.resolveCompetitionTitle('9999'), equals('9999')); // fallback
    });

    test('5. Reordering favorites in StandingsView updates order across cubit and storage', () async {
      final initialFavs = cubit.state.favoriteCompetitions;
      expect(initialFavs.length, greaterThanOrEqualTo(2));

      final first = initialFavs[0];
      final second = initialFavs[1];

      await cubit.reorderFavoriteCompetitions(0, 2);

      expect(cubit.state.favoriteCompetitions[0], equals(second));
      expect(cubit.state.favoriteCompetitions[1], equals(first));
      expect(storage.getFavoriteCompetitions()[0], equals(second));
    });
  });
}
