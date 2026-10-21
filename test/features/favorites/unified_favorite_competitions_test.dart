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

    test(
        '1. Default state: Favorite competitions are empty before user selection',
        () {
      expect(storage.hasCustomFavoriteCompetitions(), isFalse);
      final defaultFavs = storage.getFavoriteCompetitions();
      expect(defaultFavs, isEmpty);

      // Initially not favorited
      expect(storage.isFavoriteCompetition(name: 'الدوري الإسباني'), isFalse);
      expect(storage.isFavoriteCompetition(id: '1933'), isFalse);
      expect(cubit.isCompetitionFavorite(name: 'الدوري الإسباني'), isFalse);
    });

    test(
        '2. Toggling a league from LeagueView (by title or ID) adds and removes it completely',
        () async {
      expect(
        storage.isFavoriteCompetition(id: '938652', name: 'الدوري الإسباني'),
        isFalse,
      );

      // User taps star in LeagueView (calling toggleCompetition with id & name)
      await cubit.toggleCompetition(id: '938652', name: 'الدوري الإسباني');

      expect(storage.hasCustomFavoriteCompetitions(), isTrue);
      expect(cubit.isCompetitionFavorite(name: 'الدوري الإسباني'), isTrue);
      expect(cubit.isCompetitionFavorite(id: '938652'), isTrue);
      expect(cubit.isCompetitionFavorite(id: '1933'), isTrue);
      expect(storage.isFavoriteCompetition(name: 'الدوري الإسباني'), isTrue);
      expect(storage.isFavoriteCompetition(id: '938652'), isTrue);
      expect(
        storage.getFavoriteCompetitions().any((k) => k == '938652' || k == 'الدوري الإسباني'),
        isTrue,
      );

      // Unfavorite
      await cubit.toggleCompetition(id: '938652', name: 'الدوري الإسباني');

      expect(cubit.isCompetitionFavorite(name: 'الدوري الإسباني'), isFalse);
      expect(cubit.isCompetitionFavorite(id: '938652'), isFalse);
      expect(cubit.isCompetitionFavorite(id: '1933'), isFalse);
      expect(storage.isFavoriteCompetition(name: 'الدوري الإسباني'), isFalse);
      expect(storage.isFavoriteCompetition(id: '938652'), isFalse);
      expect(
        storage.getFavoriteCompetitions().any((k) => k == '938652' || k == 'الدوري الإسباني'),
        isFalse,
      );
    });

    test(
        '3. Favoriting a new league from Matches or Standings works across all screens',
        () async {
      const newLeagueId = '5555';
      const newLeagueName = 'كأس مصر';

      expect(
        cubit.isCompetitionFavorite(id: newLeagueId, name: newLeagueName),
        isFalse,
      );

      // Favorited from Matches screen via LeagueSectionWidget
      await cubit.toggleCompetition(id: newLeagueId, name: newLeagueName);

      // Must be true everywhere
      expect(
        cubit.isCompetitionFavorite(id: newLeagueId, name: newLeagueName),
        isTrue,
      );
      expect(cubit.isCompetitionFavorite(name: newLeagueName), isTrue);
      expect(cubit.isCompetitionFavorite(id: newLeagueId), isTrue);
      expect(
        storage.isFavoriteCompetition(id: newLeagueId, name: newLeagueName),
        isTrue,
      );
      expect(
        storage.resolveCompetitionTitle(newLeagueId),
        equals(newLeagueName),
      );

      // Now unfavorite it from StandingsView (by id only or id+name)
      await cubit.toggleCompetition(id: newLeagueId);

      expect(
        cubit.isCompetitionFavorite(id: newLeagueId, name: newLeagueName),
        isFalse,
      );
      expect(cubit.isCompetitionFavorite(name: newLeagueName), isFalse);
      expect(
        storage.isFavoriteCompetition(id: newLeagueId, name: newLeagueName),
        isFalse,
      );
    });

    test(
        '4. Dynamic title registration resolves IDs to human-readable names for FavoritesView',
        () async {
      await storage.registerCompetitionTitles({
        '7777': 'دوري روشن للمحترفين',
        '8888': 'كأس ملك إسبانيا',
      });

      expect(
        storage.resolveCompetitionTitle('7777'),
        equals('دوري روشن للمحترفين'),
      );
      expect(
        storage.resolveCompetitionTitle('8888'),
        equals('كأس ملك إسبانيا'),
      );
      expect(
        storage.resolveCompetitionTitle('9999'),
        equals('9999'),
      ); // fallback
    });

    test(
        '5. Reordering favorites in StandingsView updates order across cubit and storage',
        () async {
      await cubit.toggleCompetition(id: '12048', name: 'دوري أبطال أوروبا');
      await cubit.toggleCompetition(id: '6811', name: 'الدوري الإنجليزي الممتاز');

      final initialFavs = cubit.state.favoriteCompetitions;
      expect(initialFavs.length, greaterThanOrEqualTo(2));

      final first = initialFavs[0];
      final second = initialFavs[1];

      await cubit.reorderFavoriteCompetitions(0, 2);

      expect(cubit.state.favoriteCompetitions[0], equals(second));
      expect(cubit.state.favoriteCompetitions[1], equals(first));
      expect(storage.getFavoriteCompetitions()[0], equals(second));
    });

    test(
        '6. Stage variations match by name when ID is not provided, and ID discriminates stages',
        () async {
      await cubit.toggleCompetition(id: '943487', name: 'دوري أبطال أفريقيا');

      // Matches by name when no conflicting ID is present
      expect(
        cubit.isCompetitionFavorite(
          name: 'دوري أبطال أفريقيا | الأدوار الإقصائية',
        ),
        isTrue,
      );

      // By seasonId
      expect(
        cubit.isCompetitionFavorite(id: '943487'),
        isTrue,
      );

      // 7. Unfavoriting removes the tournament completely
      await cubit.toggleCompetition(
        id: '943487',
        name: 'دوري أبطال أفريقيا',
      );

      expect(
        cubit.isCompetitionFavorite(name: 'دوري أبطال أفريقيا'),
        isFalse,
      );
      expect(
        cubit.isCompetitionFavorite(id: '943487'),
        isFalse,
      );
      expect(
        storage.getFavoriteCompetitions(),
        isNot(contains('943487')),
      );
    });

    test(
        '8. Cross-lingual unfavoriting ("Serie A" removing "الدوري الإيطالي") works smoothly',
        () async {
      await cubit.toggleCompetition(id: '3734', name: 'الدوري الإيطالي');
      expect(cubit.isCompetitionFavorite(name: 'Serie A'), isTrue);

      // Now user unstars from English UI (sending 'Serie A')
      await cubit.toggleCompetition(id: '3734', name: 'Serie A');

      expect(cubit.isCompetitionFavorite(name: 'الدوري الإيطالي'), isFalse);
      expect(cubit.isCompetitionFavorite(name: 'Serie A'), isFalse);
      expect(cubit.state.favoriteCompetitions, isEmpty);
      expect(storage.getFavoriteCompetitions(), isEmpty);
    });

    test(
        '9. Name and ID discrimination prevents collisions between German and Austrian Bundesliga',
        () async {
      // 1. Favorite German Bundesliga (id: 2606)
      await cubit.toggleCompetition(id: '2606', name: 'Bundesliga');

      expect(
        cubit.isCompetitionFavorite(id: '2606', name: 'Bundesliga'),
        isTrue,
      );
      // Austrian Bundesliga (id: 544491) MUST NOT be marked favorite!
      expect(
        cubit.isCompetitionFavorite(id: '544491', name: 'Bundesliga'),
        isFalse,
      );

      // 2. Favorite Austrian Bundesliga as well
      await cubit.toggleCompetition(id: '544491', name: 'Bundesliga');

      expect(
        cubit.isCompetitionFavorite(id: '2606', name: 'Bundesliga'),
        isTrue,
      );
      expect(
        cubit.isCompetitionFavorite(id: '544491', name: 'Bundesliga'),
        isTrue,
      );

      // 3. Unfavorite Austrian Bundesliga -> German Bundesliga must remain favorite!
      await cubit.toggleCompetition(id: '544491', name: 'Bundesliga');

      expect(
        cubit.isCompetitionFavorite(id: '544491', name: 'Bundesliga'),
        isFalse,
      );
      expect(
        cubit.isCompetitionFavorite(id: '2606', name: 'Bundesliga'),
        isTrue,
      );
    });

    test(
        '10. Favoriting CAF Champions League | Qualification adds it even when CAF Champions League is in favorites',
        () async {
      // 1. Favorite CAF Champions League (id: 943487)
      await cubit.toggleCompetition(
        id: '943487',
        name: 'CAF Champions League',
      );

      expect(
        cubit.isCompetitionFavorite(
          id: '943487',
          name: 'CAF Champions League',
        ),
        isTrue,
      );
      // Qualification (id: 97533) MUST NOT be considered favorite yet!
      expect(
        cubit.isCompetitionFavorite(
          id: '97533',
          name: 'CAF Champions League | Qualification',
        ),
        isFalse,
      );

      // 2. Favorite Qualification as well (using forceFavorite: true from Hidden tab)
      await cubit.toggleCompetition(
        id: '97533',
        name: 'CAF Champions League | Qualification',
        forceFavorite: true,
      );

      expect(
        cubit.isCompetitionFavorite(
          id: '97533',
          name: 'CAF Champions League | Qualification',
        ),
        isTrue,
      );
      expect(
        cubit.isCompetitionFavorite(
          id: '943487',
          name: 'CAF Champions League',
        ),
        isTrue,
      );

      // 3. Unfavorite Qualification -> Main tournament must remain favorite
      await cubit.toggleCompetition(
        id: '97533',
        name: 'CAF Champions League | Qualification',
        forceFavorite: false,
      );

      expect(
        cubit.isCompetitionFavorite(
          id: '97533',
          name: 'CAF Champions League | Qualification',
        ),
        isFalse,
      );
      expect(
        cubit.isCompetitionFavorite(
          id: '943487',
          name: 'CAF Champions League',
        ),
        isTrue,
      );
    });

    test(
        '11. Unfavoriting UEFA Champions League from LeagueView (using season ID 943230) removes championship ID (12048)',
        () async {
      // 1. Initially user selected UEFA Champions League from Onboarding or Standings (stored as '12048')
      await storage.setFavoriteCompetitions(['12048']);
      cubit.loadFavorites();

      expect(
        cubit.isCompetitionFavorite(
          id: '943230',
          name: 'UEFA Champions League',
        ),
        isTrue,
      );
      expect(
        cubit.isCompetitionFavorite(
          id: '12048',
          name: 'UEFA Champions League',
        ),
        isTrue,
      );

      // 2. User navigates to LeagueView where widget.leagueId is '943230' and taps star to unfavorite
      await cubit.toggleCompetition(
        id: '943230',
        name: 'UEFA Champions League',
      );

      // Must be completely unfavorited across all IDs and storage
      expect(
        cubit.isCompetitionFavorite(
          id: '943230',
          name: 'UEFA Champions League',
        ),
        isFalse,
      );
      expect(
        cubit.isCompetitionFavorite(
          id: '12048',
          name: 'UEFA Champions League',
        ),
        isFalse,
      );
      expect(
        cubit.isCompetitionFavorite(
          name: 'دوري أبطال أوروبا',
        ),
        isFalse,
      );
      expect(
        storage.isFavoriteCompetition(
          id: '943230',
          name: 'UEFA Champions League',
        ),
        isFalse,
      );
      expect(
        storage.isFavoriteCompetition(
          id: '12048',
          name: 'UEFA Champions League',
        ),
        isFalse,
      );
      expect(storage.getFavoriteCompetitions(), isEmpty);
    });
  });
}

