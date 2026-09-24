import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/errors/failures.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/domain/repositories/matches_repository.dart';
import 'package:score154/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:score154/features/matches/presentation/bloc/matches_event.dart';
import 'package:score154/features/matches/presentation/bloc/matches_state.dart';
import 'package:score154/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:score154/features/standings/presentation/views/standings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockMatchesRepository extends Mock implements MatchesRepository {}

void main() {
  late MockLocalStorageService mockStorage;
  late MockSharedPreferences mockPrefs;
  late MockWebSocketService mockWebSocketService;
  late MockMatchesRepository mockRepository;

  setUp(() {
    mockStorage = MockLocalStorageService();
    mockWebSocketService = MockWebSocketService();
    mockRepository = MockMatchesRepository();

    when(() => mockStorage.getLanguage()).thenReturn('ar');
    when(() => mockStorage.setLanguage(any())).thenAnswer((_) async => true);
    when(() => mockStorage.getTimezoneOffset()).thenReturn(3);
    when(() => mockStorage.getTimeFormat()).thenReturn('24h');
    when(() => mockStorage.getFavoriteMatches()).thenReturn([]);
    when(() => mockStorage.getFavoriteCompetitions()).thenReturn([]);
    when(() => mockStorage.getFavoriteTeams()).thenReturn([]);
    when(() => mockStorage.getFavoriteCompetitionTitles()).thenReturn({});
    when(
      () => mockStorage.isFavoriteCompetition(
        compName: any(named: 'compName'),
        id: any(named: 'id'),
        name: any(named: 'name'),
        slug: any(named: 'slug'),
      ),
    ).thenReturn(false);
    when(() => mockStorage.getMatchesFilter()).thenReturn(null);
    when(() => mockStorage.getMatchesSortOrder()).thenReturn(null);
    when(() => mockWebSocketService.switchLanguageChannel(any()))
        .thenReturn(null);
    when(() => mockWebSocketService.updatesStream)
        .thenAnswer((_) => const Stream<LiveMatchUpdate>.empty());
    when(() => mockWebSocketService.statusStream)
        .thenAnswer((_) => const Stream<SocketConnectionState>.empty());
    when(() => mockWebSocketService.connect()).thenReturn(null);
    when(
      () => mockWebSocketService.recordRestFallback(
        isActive: any(named: 'isActive'),
        refreshedAt: any(named: 'refreshedAt'),
      ),
    ).thenReturn(null);
  });

  group('LocaleCubit Instant Switching & Loading Threshold Tests', () {
    test('setLocale emits immediately (0ms) without waiting for storage', () async {
      final cubit = LocaleCubit(mockStorage, mockWebSocketService);

      expect(cubit.state.locale, const Locale('ar'));
      expect(cubit.state.isRefreshing, false);
      expect(cubit.state.showIndicator, false);

      cubit.setLocale(const Locale('en'));

      // Instant update (0ms)
      expect(cubit.state.locale, const Locale('en'));
      expect(cubit.state.isRefreshing, true);
      expect(cubit.state.showIndicator, false);

      verify(() => mockStorage.setLanguage('en')).called(1);
      verify(() => mockWebSocketService.switchLanguageChannel('en')).called(1);

      await cubit.close();
    });

    test(
      '300ms indicator threshold: hidden before 300ms, visible after 300ms',
      () async {
        final cubit = LocaleCubit(mockStorage, mockWebSocketService);

        cubit.setLocale(const Locale('en'));
        expect(cubit.state.showIndicator, false);

        // Advance by 150ms -> still false
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(cubit.state.showIndicator, false);

        // Advance past 300ms -> showIndicator becomes true
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(cubit.state.showIndicator, true);

        // Notify completion -> indicator hides immediately
        cubit.notifyRefreshCompleted();
        expect(cubit.state.isRefreshing, false);
        expect(cubit.state.showIndicator, false);

        await cubit.close();
      },
    );

    test('Quick refresh (<300ms) never shows the indicator', () async {
      final cubit = LocaleCubit(mockStorage, mockWebSocketService);

      cubit.setLocale(const Locale('en'));
      expect(cubit.state.showIndicator, false);

      // Finishes in 100ms
      await Future<void>.delayed(const Duration(milliseconds: 100));
      cubit.notifyRefreshCompleted();

      expect(cubit.state.isRefreshing, false);
      expect(cubit.state.showIndicator, false);

      // Even after 350ms, indicator never fires
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(cubit.state.showIndicator, false);

      await cubit.close();
    });

    test('Race condition: stale completion tokens are discarded', () async {
      final cubit = LocaleCubit(mockStorage, mockWebSocketService);

      cubit.setLocale(const Locale('en'));
      final token1 = cubit.state.requestToken;

      cubit.setLocale(const Locale('ar'));
      final token2 = cubit.state.requestToken;
      expect(token2, greaterThan(token1));

      // Stale token1 completes -> ignored
      cubit.notifyRefreshCompleted(token: token1);
      expect(cubit.state.isRefreshing, true);
      expect(cubit.state.locale, const Locale('ar'));

      // Token2 completes -> applied
      cubit.notifyRefreshCompleted(token: token2);
      expect(cubit.state.isRefreshing, false);

      await cubit.close();
    });
  });

  group('MatchesBloc Language-Aware Caching & Refresh Tests', () {
    const arabicLeagues = [
      LeagueGroupEntity(
        leagueTitle: 'الدوري الإنجليزي',
        matches: [
          MatchEntity(
            id: 'm1',
            team1: 'أرسنال',
            team2: 'تشيلسي',
            score1: '1',
            score2: '0',
            status: 'مباشر',
          ),
        ],
      ),
    ];

    const englishLeagues = [
      LeagueGroupEntity(
        leagueTitle: 'Premier League',
        matches: [
          MatchEntity(
            id: 'm1',
            team1: 'Arsenal',
            team2: 'Chelsea',
            score1: '1',
            score2: '0',
            status: 'Live',
          ),
        ],
      ),
    ];

    test('Scenario C: Uncached language keeps existing data visible during background fetch', () async {
      final bloc = MatchesBloc(
        repository: mockRepository,
        webSocketService: mockWebSocketService,
        localStorageService: mockStorage,
      );

      // Pre-populate Arabic matches in state
      when(
        () => mockRepository.getMatchesByDate(
          date: any(named: 'date'),
          lang: 'ar',
          utcOffset: any(named: 'utcOffset'),
        ),
      ).thenAnswer((_) async => const ApiSuccess(arabicLeagues));

      bloc.add(LoadMatchesEvent(date: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, MatchesStatus.success);
      expect(bloc.state.allLeagues.first.leagueTitle, 'الدوري الإنجليزي');

      // Now switch language to English (uncached initially)
      final englishCompleter = Completer<ApiResult<List<LeagueGroupEntity>>>();
      when(
        () => mockRepository.getMatchesByDate(
          date: any(named: 'date'),
          lang: 'en',
          utcOffset: any(named: 'utcOffset'),
        ),
      ).thenAnswer((_) => englishCompleter.future);

      when(() => mockStorage.getLanguage()).thenReturn('en');

      bloc.add(const ChangeMatchesLanguageEvent('en'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // CRITICAL CHECK: Existing Arabic content MUST stay visible, NEVER cleared, NO full-screen loading!
      expect(bloc.state.status, MatchesStatus.success);
      expect(bloc.state.allLeagues.first.leagueTitle, 'الدوري الإنجليزي');
      expect(bloc.state.isLanguageRefreshing, true);

      // English response arrives
      englishCompleter.complete(const ApiSuccess(englishLeagues));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Now content updates to English
      expect(bloc.state.status, MatchesStatus.success);
      expect(bloc.state.allLeagues.first.leagueTitle, 'Premier League');
      expect(bloc.state.isLanguageRefreshing, false);

      await bloc.close();
    });

    test('Scenario D: Cached language displays immediately (0ms)', () async {
      final bloc = MatchesBloc(
        repository: mockRepository,
        webSocketService: mockWebSocketService,
        localStorageService: mockStorage,
      );

      // Load English data once to warm the cache
      when(
        () => mockRepository.getMatchesByDate(
          date: any(named: 'date'),
          lang: 'en',
          utcOffset: any(named: 'utcOffset'),
        ),
      ).thenAnswer((_) async => const ApiSuccess(englishLeagues));

      when(() => mockStorage.getLanguage()).thenReturn('en');
      bloc.add(LoadMatchesEvent(date: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.allLeagues.first.leagueTitle, 'Premier League');

      // Switch to Arabic
      when(
        () => mockRepository.getMatchesByDate(
          date: any(named: 'date'),
          lang: 'ar',
          utcOffset: any(named: 'utcOffset'),
        ),
      ).thenAnswer((_) async => const ApiSuccess(arabicLeagues));
      when(() => mockStorage.getLanguage()).thenReturn('ar');
      bloc.add(const ChangeMatchesLanguageEvent('ar'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.allLeagues.first.leagueTitle, 'الدوري الإنجليزي');

      // Now switch back to English (which is now in cache!)
      when(() => mockStorage.getLanguage()).thenReturn('en');
      bloc.add(const ChangeMatchesLanguageEvent('en'));

      // Instant 0ms emission from cache!
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(bloc.state.allLeagues.first.leagueTitle, 'Premier League');
      expect(bloc.state.isLanguageRefreshing, false);

      await bloc.close();
    });

    test('Scenario E: API failure keeps existing visible data intact and does not show full-screen error', () async {
      final bloc = MatchesBloc(
        repository: mockRepository,
        webSocketService: mockWebSocketService,
        localStorageService: mockStorage,
      );

      // Pre-populate Arabic matches
      when(
        () => mockRepository.getMatchesByDate(
          date: any(named: 'date'),
          lang: 'ar',
          utcOffset: any(named: 'utcOffset'),
        ),
      ).thenAnswer((_) async => const ApiSuccess(arabicLeagues));

      bloc.add(LoadMatchesEvent(date: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // English request fails
      when(
        () => mockRepository.getMatchesByDate(
          date: any(named: 'date'),
          lang: 'en',
          utcOffset: any(named: 'utcOffset'),
        ),
      ).thenAnswer(
        (_) async => const ApiFailure(ServerFailure('Server error')),
      );

      when(() => mockStorage.getLanguage()).thenReturn('en');
      bloc.add(const ChangeMatchesLanguageEvent('en'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // UI still has content, no full-screen error
      expect(bloc.state.status, MatchesStatus.success);
      expect(bloc.state.allLeagues.isNotEmpty, true);
      expect(bloc.state.isLanguageRefreshing, false);

      await bloc.close();
    });

    test(
      'Scenario F: Rapid switching discards outdated API responses',
      () async {
        final bloc = MatchesBloc(
          repository: mockRepository,
          webSocketService: mockWebSocketService,
          localStorageService: mockStorage,
        );

        final englishCompleter =
            Completer<ApiResult<List<LeagueGroupEntity>>>();
        final arabicCompleter = Completer<ApiResult<List<LeagueGroupEntity>>>();

        when(
          () => mockRepository.getMatchesByDate(
            date: any(named: 'date'),
            lang: 'en',
            utcOffset: any(named: 'utcOffset'),
          ),
        ).thenAnswer((_) => englishCompleter.future);

        when(
          () => mockRepository.getMatchesByDate(
            date: any(named: 'date'),
            lang: 'ar',
            utcOffset: any(named: 'utcOffset'),
          ),
        ).thenAnswer((_) => arabicCompleter.future);

        // User switches to English
        when(() => mockStorage.getLanguage()).thenReturn('en');
        bloc.add(const ChangeMatchesLanguageEvent('en'));

        // User immediately switches back to Arabic
        when(() => mockStorage.getLanguage()).thenReturn('ar');
        bloc.add(const ChangeMatchesLanguageEvent('ar'));

        // Delayed English response arrives first
        englishCompleter.complete(const ApiSuccess(englishLeagues));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should NOT apply English because current language is Arabic!
        expect(
          bloc.state.allLeagues.isEmpty ||
              bloc.state.allLeagues.first.leagueTitle != 'Premier League',
          true,
        );

        // Arabic response arrives
        arabicCompleter.complete(const ApiSuccess(arabicLeagues));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.allLeagues.first.leagueTitle, 'الدوري الإنجليزي');

        await bloc.close();
      },
    );
  });

  group('Standings Page Localization & Cross-Language Resolution Tests', () {
    test('getCachedRankings never bleeds Arabic cache into English', () {
      mockPrefs = MockSharedPreferences();
      final storage = LocalStorageServiceImpl(mockPrefs);
      // Even if legacy unkeyed cache has Arabic, requesting English must return null when no en cache exists
      when(() => mockPrefs.getString('app_cached_rankings_en')).thenReturn(null);
      when(() => mockPrefs.getString('app_cached_rankings')).thenReturn('{"leagues": [{"name": "الدوري الإنجليزي"}]}');
      when(() => mockPrefs.getString('app_language')).thenReturn('en');

      final cached = storage.getCachedRankings(lang: 'en');
      expect(cached, isNull);
    });

    test('Favorites cross-lingual resolution matches Arabic saved favorites to English championship', () {
      const state = FavoritesState(
        favoriteCompetitions: ['دوري أبطال أوروبا', 'الدوري الإنجليزي الممتاز'],
        competitionTitles: {
          '12048': 'UEFA Champions League',
          '6811': 'Premier League',
        },
      );

      // Matches by ID
      expect(state.isFavoriteCompetition(id: '12048', name: 'UEFA Champions League'), isTrue);
      expect(state.isFavoriteCompetition(id: '6811', name: 'Premier League'), isTrue);

      // Matches by English name via defaultNameToId
      expect(state.isFavoriteCompetition(name: 'UEFA Champions League'), isTrue);
      expect(state.isFavoriteCompetition(name: 'Premier League'), isTrue);
    });

    test('getDefaultFallbackChampionships returns localized titles for en and ar', () {
      final enFallbacks = getDefaultFallbackChampionships('en');
      final arFallbacks = getDefaultFallbackChampionships('ar');

      expect(enFallbacks.first.name, 'UEFA Champions League');
      expect(arFallbacks.first.name, 'دوري أبطال أوروبا');
      expect(enFallbacks[1].name, 'Premier League');
      expect(arFallbacks[1].name, 'الدوري الإنجليزي الممتاز');
    });
  });
}
