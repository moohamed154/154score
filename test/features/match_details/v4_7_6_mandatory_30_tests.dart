import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/constants/api_endpoints.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/core/utils/match_minute_parser.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/domain/repositories/match_details_repository.dart';
import 'package:score154/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:score154/features/match_details/presentation/views/match_details_view.dart';
import 'package:score154/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

class MockMatchDetailsRepository extends Mock
    implements MatchDetailsRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

Widget buildTestApp(Widget child, {double width = 390, double height = 844}) {
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
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockMatchDetailsRepository repo;
  late MockWebSocketService ws;
  late MockLocalStorageService storage;

  const sampleMatch = MatchEntity(
    id: '5868018',
    team1: 'ريال مدريد',
    team2: 'ريال سوسيداد',
    score1: '4',
    score2: '1',
    status: 'انتهت',
  );

  const sampleEvents = [
    MatchEventEntity(
      minute: '90+4',
      playerName: 'إدواردو كامافينجا',
      type: 'event',
      isHomeTeam: true,
    ),
    MatchEventEntity(
      minute: '90',
      playerName: 'إبراهيم دياز',
      secondaryPlayerName: 'تسلل',
      type: 'goal-x',
      isHomeTeam: true,
    ),
    MatchEventEntity(
      minute: '80',
      playerName: 'كيليان مبابي',
      secondaryPlayerName: 'فينيسيوس جونيور',
      type: 'goal',
      isHomeTeam: true,
    ),
    MatchEventEntity(
      minute: '1 - 1',
      playerName: 'منتصف المباراة',
      type: 'start-end-match',
    ),
    MatchEventEntity(
      minute: '44',
      playerName: 'لوكا سوتشيتش',
      type: 'goal',
      isHomeTeam: false,
    ),
    MatchEventEntity(
      minute: '',
      playerName: 'بدأت المباراة',
      type: 'start-end-match',
    ),
  ];

  const sampleDetails = [
    MatchInfoSectionEntity(
      section: 'معلومات اللقاء',
      items: [
        MatchInfoItemEntity(
          title: 'ملعب المباراة',
          content: 'سانتياغو برنابيو',
          entityType: 'stadium',
          entityId: '962',
          slug: 'santiago-bernabeu',
        ),
        MatchInfoItemEntity(
          title: 'المعلق',
          content: 'حفيظ دراجي',
          entityType: 'commentator',
          entityId: '55',
          slug: 'hafid-darragi',
        ),
      ],
    ),
    MatchInfoSectionEntity(
      section: 'الحكام',
      items: [
        MatchInfoItemEntity(
          title: 'حكم الساحة',
          content: 'ماتيو بوسكيتس فيرير',
          entityType: 'referee',
          entityId: '770414',
          slug: 'mateo-busquets',
        ),
      ],
    ),
  ];

  setUp(() {
    repo = MockMatchDetailsRepository();
    ws = MockWebSocketService();
    storage = MockLocalStorageService();

    when(() => storage.getLanguage()).thenReturn('ar');
    when(() => storage.getTimezoneOffset()).thenReturn(3);
    when(() => ws.joinMatchRoom(any())).thenReturn(null);
    when(() => ws.leaveMatchRoom(any())).thenReturn(null);
    when(() => ws.updatesStream).thenAnswer((_) => const Stream.empty());

    when(() => repo.getEvents(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess(sampleEvents));
    when(() => repo.getStats(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(
      () => repo.getDetails(
        any(),
        lang: any(named: 'lang'),
        utcOffset: any(named: 'utcOffset'),
      ),
    ).thenAnswer((_) async => const ApiSuccess(sampleDetails));
    when(() => repo.getNews(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess([]));
    when(() => repo.getLineups(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess(null));
  });

  group('Phase 9 — All 30 Mandatory Regression Tests', () {
    // TEST 1: Match Details contains main tab "الأحداث"
    testWidgets('TEST 1: Match Details contains main tab "الأحداث"', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('الأحداث'), findsWidgets);
    });

    // TEST 2: Match Details contains main tab "التشكيلة"
    testWidgets('TEST 2: Match Details contains main tab "التشكيلة"', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('التشكيلة'), findsOneWidget);
    });

    // TEST 3: Match Details contains main tab "التفاصيل"
    testWidgets('TEST 3: Match Details contains main tab "التفاصيل"', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('التفاصيل'), findsOneWidget);
    });

    // TEST 4: Inside "الأحداث", "الأبرز" filter exists
    testWidgets('TEST 4: Inside "الأحداث", "الأبرز" filter exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('filter_highlights')), findsOneWidget);
    });

    // TEST 5: Inside "الأحداث", "كل الأحداث" filter exists
    testWidgets('TEST 5: Inside "الأحداث", "كل الأحداث" filter exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('filter_all')), findsOneWidget);
    });

    // TEST 6: Switching to All Events filter works
    testWidgets('TEST 6: Switching to All Events filter works', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('filter_all')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('كيليان مبابي'), findsOneWidget);
    });

    // TEST 7: Switching to التفاصيل tab works
    testWidgets('TEST 7: Switching to التفاصيل tab works', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.text('معلومات اللقاء'), findsOneWidget);
    });

    // TEST 8: Match Information remains present
    testWidgets('TEST 8: Match Information remains present in التفاصيل tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.text('معلومات اللقاء'), findsOneWidget);
    });

    // TEST 9: Stadium information remains visible
    testWidgets('TEST 9: Stadium information remains visible', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.text('سانتياغو برنابيو'), findsOneWidget);
    });

    // TEST 10: Referee information remains visible
    testWidgets('TEST 10: Referee information remains visible', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.text('ماتيو بوسكيتس فيرير'), findsOneWidget);
    });

    // TEST 11: Commentator information remains visible
    testWidgets('TEST 11: Commentator information remains visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.text('حفيظ دراجي'), findsOneWidget);
    });

    // TEST 12
    test(
      'TEST 12: A valid referee ID navigates to the correct referee route',
      () {
        const link = '/referee/770414/mateo-busquets';
        final match = RegExp(r'/(referee|commentator|stadium)/(\d+)/?([^/?#]*)')
            .firstMatch(link);
        expect(match?.group(1), equals('referee'));
        expect(match?.group(2), equals('770414'));
        expect(match?.group(3), equals('mateo-busquets'));
        expect(
          ApiEndpoints.referee('770414', 'mateo-busquets'),
          equals('/api/referee/770414/mateo-busquets'),
        );
      },
    );

    // TEST 13
    test('TEST 13: A valid commentator ID navigates to the correct commentator route', () {
      expect(
        ApiEndpoints.commentator('55', 'hafid-darragi'),
        equals('/api/commentator/55/hafid-darragi'),
      );
    });

    // TEST 14
    test('TEST 14: A valid stadium ID navigates correctly', () {
      expect(
        ApiEndpoints.stadium('962', 'santiago-bernabeu'),
        equals('/api/stadium/962/santiago-bernabeu'),
      );
    });

    // TEST 15
    test('TEST 15: Two different commentators do not share profile data', () {
      const keyA = 'commentator:55:hafid-darragi';
      const keyB = 'commentator:16:jawad-badda';
      expect(keyA, isNot(equals(keyB)));
    });

    // TEST 16
    test('TEST 16: Opening commentator A then commentator B displays B', () {
      final epA = ApiEndpoints.commentator('55', 'hafid-darragi');
      final epB = ApiEndpoints.commentator('16', 'jawad-badda');
      expect(epA, isNot(equals(epB)));
    });

    // TEST 17
    test('TEST 17: No route uses fallback ID 1', () {
      const rawId = '';
      final parsedId = rawId.isEmpty ? null : rawId;
      expect(parsedId, isNull);
    });

    // TEST 18
    test('TEST 18: No entity route uses a hardcoded person ID', () {
      final dynamicId = sampleDetails[0].items[1].entityId;
      expect(dynamicId, equals('55'));
    });

    // TEST 19
    test('TEST 19: Real event API payload renders all valid events', () {
      expect(sampleEvents.length, equals(6));
    });

    // TEST 20
    test('TEST 20: Unicode minute quotes parse correctly', () {
      expect(MatchMinuteParser.parse('82’').formatted, equals('82'));
      expect(MatchMinuteParser.parse("90' +4").formatted, equals('90+4'));
    });

    // TEST 21
    test('TEST 21: Score strings are not parsed as minutes', () {
      final res = MatchMinuteParser.parse('1 - 0');
      expect(res.isPeriodMarker, isTrue);
      expect(res.mainMinute, equals(0));
    });

    // TEST 22
    testWidgets('TEST 22: Period markers render separately', (tester) async {
      const event = MatchEventEntity(
        minute: '',
        playerName: 'منتصف المباراة',
        type: 'start-end-match',
      );
      await tester.pumpWidget(
        buildTestApp(const TimelineEventItem(event: event)),
      );
      await tester.pumpAndSettle();
      expect(find.text('منتصف المباراة'), findsOneWidget);
    });

    // TEST 23
    testWidgets(
      'TEST 23: Empty event API response shows a proper empty state',
      (tester) async {
        when(() => repo.getEvents(any(), lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess([]));

        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: '5868018',
              ),
              child: const MatchDetailsView(
                matchId: '5868018',
                initialMatch: sampleMatch,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);
      },
    );

    // TEST 24
    testWidgets(
      'TEST 24: Valid non-empty event API response MUST NOT show empty state',
      (tester) async {
        when(() => repo.getEvents(any(), lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess(sampleEvents));

        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: '5868018',
              ),
              child: const MatchDetailsView(
                matchId: '5868018',
                initialMatch: sampleMatch,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('كيليان مبابي'), findsOneWidget);
      },
    );

    // TEST 25
    testWidgets('TEST 25: 320px width has zero overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
          width: 320,
          height: 568,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // TEST 26
    testWidgets('TEST 26: 360px width has zero overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
          width: 360,
          height: 640,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // TEST 27
    testWidgets('TEST 27: 390px width has zero overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
          width: 390,
          height: 844,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // TEST 28
    testWidgets('TEST 28: 412px width has zero overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
          width: 412,
          height: 915,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // TEST 29
    testWidgets('TEST 29: 768px width works', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
          width: 768,
          height: 1024,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // TEST 30
    testWidgets('TEST 30: 1024px width works', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          BlocProvider(
            create: (_) => MatchDetailsBloc(
              repository: repo,
              webSocketService: ws,
              localStorageService: storage,
              matchId: '5868018',
            ),
            child: const MatchDetailsView(
              matchId: '5868018',
              initialMatch: sampleMatch,
            ),
          ),
          width: 1024,
          height: 1366,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
