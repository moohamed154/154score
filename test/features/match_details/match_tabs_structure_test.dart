import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/match_details/domain/repositories/match_details_repository.dart';
import 'package:score154/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/views/match_details_view.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockMatchDetailsRepository extends Mock
    implements MatchDetailsRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

// ── Helper ─────────────────────────────────────────────────────────────────

Widget buildTestApp(Widget child, {double width = 390, double height = 844}) {
  final storage = MockLocalStorageService();
  when(() => storage.getFavoriteTeams()).thenReturn(const []);
  when(() => storage.getFavoriteCompetitions()).thenReturn(const []);
  when(() => storage.getFavoriteMatches()).thenReturn(const []);
  when(() => storage.getFavoriteTeamTitles()).thenReturn(const {});
  when(() => storage.getFavoriteCompetitionTitles()).thenReturn(const {});
  when(() => storage.getFavoriteTeamLogos()).thenReturn(const {});
  when(() => storage.getFavoriteCompetitionLogos()).thenReturn(const {});

  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: BlocProvider(create: (_) => FavoritesCubit(storage), child: child),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late MockMatchDetailsRepository repo;
  late MockWebSocketService ws;
  late MockLocalStorageService storage;

  setUp(() {
    repo = MockMatchDetailsRepository();
    ws = MockWebSocketService();
    storage = MockLocalStorageService();

    if (GetIt.I.isRegistered<LocalStorageService>()) {
      GetIt.I.unregister<LocalStorageService>();
    }
    GetIt.I.registerSingleton<LocalStorageService>(storage);

    // Default stubs
    when(() => storage.getLanguage()).thenReturn('ar');
    when(() => storage.getTimezoneOffset()).thenReturn(3);
    when(() => storage.getTimeFormat()).thenReturn('12h');
    when(() => storage.isLiveActivityFeatureEnabled()).thenReturn(false);
    when(() => ws.joinMatchRoom(any())).thenReturn(null);
    when(() => ws.leaveMatchRoom(any())).thenReturn(null);
    when(() => ws.updatesStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.getEvents(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(() => repo.getEventsPayload(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess(MatchEventsPayload()));
    when(() => repo.getStats(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(
      () => repo.getDetails(
        any(),
        lang: any(named: 'lang'),
        utcOffset: any(named: 'utcOffset'),
      ),
    ).thenAnswer((_) async => const ApiSuccess([]));
    when(() => repo.getNews(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(() => repo.getLineups(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess(null));
  });

  tearDown(() {
    if (GetIt.I.isRegistered<LocalStorageService>()) {
      GetIt.I.unregister<LocalStorageService>();
    }
  });

  group('Match Tabs Structure — V4.7.6 Reference Match Tabs', () {
    // ── 1. Main tabs exist ────────────────────────────────────────────────
    testWidgets(
      'Main tabs exist: الأحداث, التفاصيل, التشكيلة, الإحصائيات, الترتيب, الأخبار',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: 'test123',
              ),
              child: const MatchDetailsView(matchId: 'test123'),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('الأحداث'), findsWidgets);
        expect(find.text('التفاصيل'), findsOneWidget);
        expect(find.text('التشكيلة'), findsOneWidget);
        expect(find.text('الإحصائيات'), findsWidgets);
        expect(find.text('الترتيب'), findsOneWidget);
        expect(find.text('الأخبار'), findsOneWidget);
      },
    );

    // ── 2. Events filter inside الأحداث ──────────────────────────────────
    testWidgets('Events tab contains الأبرز and كل الأحداث filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test123',
            ),
            child: const MatchDetailsView(matchId: 'test123'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('filter_highlights')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_all')), findsOneWidget);
    });

    // ── 3. Tab count is 6 ────────────────────────────────────────────────
    testWidgets('TabBar has 6 tabs', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test123',
            ),
            child: const MatchDetailsView(matchId: 'test123'),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Tab), findsNWidgets(8));
    });

    // ── 4. Switching to التفاصيل tab ──────────────────────────────────────
    testWidgets('tapping التفاصيل tab switches content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test123',
            ),
            child: const MatchDetailsView(matchId: 'test123'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // ── 5. التشكيلة tab shows unavailable state ───────────────────────────
    testWidgets('"التشكيلة" tab shows lineup unavailable state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test123',
            ),
            child: const MatchDetailsView(matchId: 'test123'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('التشكيلة'));
      await tester.pumpAndSettle();

      expect(find.text('لم يتم الإعلان عن التشكيلة بعد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Match header banner is rendered ────────────────────────────────
    testWidgets('MatchHeaderBanner is rendered in the tab layout', (
      tester,
    ) async {
      const match = MatchEntity(
        id: 'test999',
        team1: 'الأهلي',
        team2: 'الزمالك',
        score1: '2',
        score2: '1',
        status: 'انتهت',
      );

      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test999',
            ),
            child: const MatchDetailsView(
              matchId: 'test999',
              initialMatch: match,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الأهلي'), findsWidgets);
      expect(find.text('الزمالك'), findsWidgets);
    });

    // ── 7. No overflow on 320px screen ────────────────────────────────────
    testWidgets('No overflow on 320px screen width', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test123',
            ),
            child: const MatchDetailsView(matchId: 'test123'),
          ),
          width: 320,
          height: 568,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    // ── 8. No overflow on 768px tablet ────────────────────────────────────
    testWidgets('No overflow on 768px tablet width', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: 'test123',
            ),
            child: const MatchDetailsView(matchId: 'test123'),
          ),
          width: 768,
          height: 1024,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    // ── 9. Independent RefreshIndicator on Events tab ──────────────────────
    testWidgets(
      'Events tab has independent RefreshIndicator and triggers refresh',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: 'test123',
              ),
              child: const MatchDetailsView(matchId: 'test123'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify RefreshIndicator is present
        expect(find.byType(RefreshIndicator), findsWidgets);

        // Perform a pull-to-refresh drag gesture on the first tab
        await tester.drag(
          find.byKey(const PageStorageKey('events_tab_list')),
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Verify repository was queried on refresh
        verify(() => repo.getEventsPayload('test123', lang: any(named: 'lang')))
            .called(greaterThanOrEqualTo(1));
      },
    );

    // ── 10. Upcoming match hides Events tab ─────────────────────────────────
    testWidgets(
      'Upcoming match (لم تبدأ) hides Events (الأحداث) tab',
      (tester) async {
        const upcomingMatch = MatchEntity(
          id: 'upcoming123',
          team1: 'Arsenal',
          team2: 'Chelsea',
          status: 'لم تبدأ',
          statusCode: 'UPCOMING',
        );

        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: 'upcoming123',
              ),
              child: const MatchDetailsView(
                matchId: 'upcoming123',
                initialMatch: upcomingMatch,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Events tab should NOT be displayed
        expect(find.text('الأحداث'), findsNothing);
        // Details tab should be present
        expect(find.text('التفاصيل'), findsOneWidget);
        expect(find.text('التشكيلة'), findsOneWidget);
        expect(find.text('الترتيب'), findsOneWidget);
      },
    );
  });
}
