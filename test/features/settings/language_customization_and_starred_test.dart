import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/core/widgets/starred_button.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:score154/features/news/domain/entities/news_entity.dart';
import 'package:score154/features/news/domain/repositories/news_repository.dart';
import 'package:score154/features/news/presentation/bloc/news_bloc.dart';
import 'package:score154/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:score154/features/settings/presentation/views/language_settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language Customization (App & News Language Separation)', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageServiceImpl(prefs);
    });

    test('default news language is "app"', () {
      expect(storage.getNewsLanguage(), 'app');
      expect(storage.getLanguage(), 'ar');
      expect(storage.getEffectiveNewsLanguage(), 'ar');
    });

    test('effective news language tracks app language when set to "app"', () async {
      await storage.setLanguage('en');
      expect(storage.getNewsLanguage(), 'app');
      expect(storage.getEffectiveNewsLanguage(), 'en');

      await storage.setLanguage('ar');
      expect(storage.getEffectiveNewsLanguage(), 'ar');
    });

    test('effective news language remains independent when set to explicit language', () async {
      await storage.setLanguage('en');
      await storage.setNewsLanguage('ar');

      expect(storage.getLanguage(), 'en');
      expect(storage.getNewsLanguage(), 'ar');
      expect(storage.getEffectiveNewsLanguage(), 'ar');

      await storage.setNewsLanguage('en');
      await storage.setLanguage('ar');

      expect(storage.getLanguage(), 'ar');
      expect(storage.getNewsLanguage(), 'en');
      expect(storage.getEffectiveNewsLanguage(), 'en');
    });

    test('NewsLanguageCubit manages state and persists changes', () async {
      final cubit = NewsLanguageCubit(storage);
      expect(cubit.state, 'app');

      await cubit.setNewsLanguage('ar');
      expect(cubit.state, 'ar');
      expect(storage.getNewsLanguage(), 'ar');

      await cubit.setNewsLanguage('en');
      expect(cubit.state, 'en');
      expect(storage.getNewsLanguage(), 'en');

      await cubit.close();
    });
  });

  group('FavoritesCubit Optimistic State Updates', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;
    late FavoritesCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageServiceImpl(prefs);
      cubit = FavoritesCubit(storage);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('toggleTeam optimistically updates state immediately', () async {
      expect(cubit.isTeamFavorite(name: 'Real Madrid'), isFalse);

      final future = cubit.toggleTeam('Real Madrid', id: '123');
      // Verify optimistic update has already been applied synchronously
      expect(cubit.isTeamFavorite(name: 'Real Madrid', id: '123'), isTrue);

      await future;
      expect(cubit.isTeamFavorite(name: 'Real Madrid', id: '123'), isTrue);

      final unstarFuture = cubit.toggleTeam('Real Madrid', id: '123');
      expect(cubit.isTeamFavorite(name: 'Real Madrid', id: '123'), isFalse);
      await unstarFuture;
      expect(cubit.isTeamFavorite(name: 'Real Madrid', id: '123'), isFalse);
    });

    test('toggleCompetition optimistically updates state immediately', () async {
      expect(cubit.isCompetitionFavorite(name: 'Egyptian League'), isFalse);

      final future = cubit.toggleCompetition(
        name: 'Egyptian League',
        id: 'egy_league_1',
      );
      expect(
        cubit.isCompetitionFavorite(name: 'Egyptian League', id: 'egy_league_1'),
        isTrue,
      );

      await future;
      expect(
        cubit.isCompetitionFavorite(name: 'Egyptian League', id: 'egy_league_1'),
        isTrue,
      );
    });

    test('toggleMatch optimistically updates state immediately', () async {
      expect(cubit.isMatchFavorite('match_999'), isFalse);

      final future = cubit.toggleMatch('match_999');
      expect(cubit.isMatchFavorite('match_999'), isTrue);

      await future;
      expect(cubit.isMatchFavorite('match_999'), isTrue);
    });
  });

  group('StarredButton Widget Tests', () {
    testWidgets('renders outline icon when isStarred is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StarredButton(
              isStarred: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('renders filled icon when isStarred is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StarredButton(
              isStarred: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    });

    testWidgets('triggers onTap callback and animates smoothly on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarredButton(
              isStarred: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StarredButton));
      expect(tapped, isTrue);

      // Advance animation frames to verify no exceptions
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    });
  });

  group('LanguageSettingsView Page Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;
    late MockWebSocketService mockWs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageServiceImpl(prefs);
      mockWs = MockWebSocketService();
    });

    testWidgets('renders both App Interface Language and News Language sections', (tester) async {
      final localeCubit = LocaleCubit(storage, mockWs);
      final newsLangCubit = NewsLanguageCubit(storage);
      final mockNewsBloc = MockNewsBloc();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<NewsLanguageCubit>.value(value: newsLangCubit),
            BlocProvider<NewsBloc>.value(value: mockNewsBloc),
          ],
          child: const MaterialApp(
            localizationsDelegates: [AppLocalizations.delegate],
            supportedLocales: AppLocalizations.supportedLocales,
            home: LanguageSettingsView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('العربية'), findsWidgets);
      expect(find.text('English'), findsWidgets);
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      expect(find.byIcon(Icons.newspaper_rounded), findsOneWidget);

      await localeCubit.close();
      await newsLangCubit.close();
    });
  });
}

class MockWebSocketService extends Mock implements WebSocketService {}
class MockNewsBloc extends Mock implements NewsBloc {}
