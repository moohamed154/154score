import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/utils/team_resolver.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Lingual Team Favorites Tests', () {
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

    test('1. TeamResolver correctly matches Arabic and English names for Egypt', () {
      expect(TeamResolver.areSameTeam('مصر', 'Egypt'), isTrue);
      expect(TeamResolver.areSameTeam('منتخب مصر', 'Egypt'), isTrue);
      expect(TeamResolver.areSameTeam('Egypt', 'مصر'), isTrue);
      expect(TeamResolver.areSameTeam('مصر', 'Angola'), isFalse);
      expect(TeamResolver.areSameTeam('أنغولا', 'Angola'), isTrue);
    });

    test('2. Team favorited in Arabic is recognized as favorite when viewed in English (User Scenario)', () async {
      // User favorites team in Arabic (display name 'مصر', teamId '967')
      await cubit.toggleTeam('مصر', id: '967');

      // Verify favorite is active in Arabic
      expect(cubit.isTeamFavorite(name: 'مصر', id: '967'), isTrue);
      expect(storage.isFavoriteTeam('مصر', id: '967'), isTrue);

      // Now user changes language to English:
      // Screen asks: isFavoriteTeam(name: 'Egypt', id: '967')
      expect(cubit.isTeamFavorite(name: 'Egypt', id: '967'), isTrue);
      expect(cubit.isTeamFavorite(name: 'Egypt'), isTrue);
      expect(storage.isFavoriteTeam('Egypt', id: '967'), isTrue);
      expect(storage.isFavoriteTeam('Egypt'), isTrue);
    });

    test('3. Team favorited with only Arabic text (pre-existing SharedPreferences) resolves in English', () {
      // Simulate existing SharedPreferences where only 'مصر' was stored
      const state = FavoritesState(
        favoriteTeams: ['مصر'],
      );

      // In English view:
      expect(state.isFavoriteTeam(name: 'Egypt'), isTrue);
      expect(state.isFavoriteTeam(id: '967', name: 'Egypt'), isTrue);
      expect(state.isFavoriteTeam(name: 'Angola'), isFalse);
    });

    test('4. Club teams (e.g. Real Madrid, Al Ahly) work cross-lingually between Arabic and English', () async {
      // Real Madrid favorited in Arabic
      await cubit.toggleTeam('ريال مدريد', id: '86');
      expect(cubit.isTeamFavorite(name: 'Real Madrid'), isTrue);
      expect(cubit.isTeamFavorite(name: 'ريال مدريد'), isTrue);
      expect(cubit.isTeamFavorite(id: '86', name: 'Real Madrid'), isTrue);

      // Al Ahly favorited in English
      await cubit.toggleTeam('Al Ahly', id: '103');
      expect(cubit.isTeamFavorite(name: 'الأهلي'), isTrue);
      expect(cubit.isTeamFavorite(name: 'Al Ahly'), isTrue);
      expect(cubit.isTeamFavorite(id: '103', name: 'الأهلي'), isTrue);
    });

    test('5. Toggling favorite off in English removes team originally favorited in Arabic', () async {
      // Favorited in Arabic
      await cubit.toggleTeam('مصر', id: '967');
      expect(cubit.isTeamFavorite(name: 'Egypt', id: '967'), isTrue);

      // Unfavorited in English
      await cubit.toggleTeam('Egypt', id: '967');

      // Should be removed in both languages
      expect(cubit.isTeamFavorite(name: 'Egypt', id: '967'), isFalse);
      expect(cubit.isTeamFavorite(name: 'مصر', id: '967'), isFalse);
      expect(storage.getFavoriteTeams(), isEmpty);
    });

    test('6. Dynamic team title registration maps custom team IDs to names', () async {
      await cubit.registerTeamTitles({'999': 'Zamalek'});

      expect(cubit.state.teamTitles['999'], 'Zamalek');
      expect(cubit.state.teamTitles['zamalek'], '999');
    });

    test('7. TeamResolver localized name provides proper title per language', () {
      expect(TeamResolver.getLocalizedName('مصر', isArabic: false), 'Egypt');
      expect(TeamResolver.getLocalizedName('Egypt', isArabic: true), 'مصر');
      expect(TeamResolver.getLocalizedName('ريال مدريد', isArabic: false), 'Real Madrid');
      expect(TeamResolver.getLocalizedName('Real Madrid', isArabic: true), 'ريال مدريد');
    });
  });
}
