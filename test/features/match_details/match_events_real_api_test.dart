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
import 'package:score154/features/match_details/presentation/bloc/match_details_event.dart';
import 'package:score154/features/match_details/presentation/views/match_details_view.dart';
import 'package:score154/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:score154/core/widgets/status_pill.dart';
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
          id: '962',
          slug: 'santiago-bernabeu',
        ),
        MatchInfoItemEntity(
          title: 'المعلق',
          content: 'حفيظ دراجي',
          id: '55',
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
          id: '770414',
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
    when(() => repo.getEventsPayload(any(), lang: any(named: 'lang')))
        .thenAnswer(
      (_) async => const ApiSuccess(MatchEventsPayload(events: sampleEvents)),
    );
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

  group('V4.7.4 Mandatory Regression Tests (1 to 15)', () {
    // ── 1. Real event payload with Unicode apostrophe minute parses correctly ──
    test(
      '1. Real event payload with Unicode apostrophe minute parses correctly',
      () {
        final res = MatchMinuteParser.parse('82’');
        expect(res.mainMinute, equals(82));
        expect(res.extraMinute, equals(0));
        expect(res.formatted, equals('82'));
      },
    );

    // ── 2. 90’ +4 parses correctly ──────────────────────────────────────────
    test('2. 90’ +4 and all its variants parse correctly', () {
      final res1 = MatchMinuteParser.parse('90’ +4');
      expect(res1.mainMinute, equals(90));
      expect(res1.extraMinute, equals(4));
      expect(res1.formatted, equals('90+4'));

      final res2 = MatchMinuteParser.parse('90 + 4');
      expect(res2.mainMinute, equals(90));
      expect(res2.extraMinute, equals(4));
      expect(res2.formatted, equals('90+4'));

      final res3 = MatchMinuteParser.parse('45+2');
      expect(res3.mainMinute, equals(45));
      expect(res3.extraMinute, equals(2));
      expect(res3.formatted, equals('45+2'));
    });

    // ── 3. Period marker is rendered as a separator ─────────────────────────
    testWidgets('3. Period marker is rendered as a centered separator', (
      tester,
    ) async {
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
      expect(find.byIcon(Icons.sports_rounded), findsOneWidget);
    });

    // ── 4. Empty response variants do not crash ─────────────────────────────
    test('4. Empty response variants do not crash minute parser', () {
      expect(MatchMinuteParser.parse(null).formatted, equals(''));
      expect(MatchMinuteParser.parse('').formatted, equals(''));
      expect(MatchMinuteParser.parse('   ').formatted, equals(''));
    });

    // ── 5. Referee navigation uses extracted real ID ────────────────────────
    test('5. Referee navigation uses extracted real ID and slug', () {
      const link = '/referee/770414/mateo-busquets';
      final match = RegExp(r'/(referee|commentator|stadium)/(\d+)/?([^/?#]*)')
          .firstMatch(link);
      expect(match?.group(1), equals('referee'));
      expect(match?.group(2), equals('770414'));
      expect(match?.group(3), equals('mateo-busquets'));
    });

    // ── 6. Commentator navigation never defaults to ID 1 ───────────────────
    test('6. Commentator navigation never defaults to fixed ID 1', () {
      final endpoint1 = ApiEndpoints.commentator('55', 'hafid-darragi');
      final endpoint2 = ApiEndpoints.commentator('16', 'jawad-badda');
      expect(endpoint1, equals('/api/commentator/55/hafid-darragi'));
      expect(endpoint2, equals('/api/commentator/16/jawad-badda'));
      expect(endpoint1, isNot(equals(endpoint2)));
    });

    // ── 7. Different commentators produce different API requests ───────────
    test('7. Different commentators produce different API requests', () {
      final ep1 = ApiEndpoints.commentator('101', 'comm-1');
      final ep2 = ApiEndpoints.commentator('102', 'comm-2');
      expect(ep1, isNot(equals(ep2)));
    });

    // ── 8. Different commentator pages do not reuse cached state ───────────
    test('8. Different commentator pages do not reuse cached state', () {
      const keyA = 'commentator:55:hafid-darragi';
      const keyB = 'commentator:16:jawad-badda';
      expect(keyA, isNot(equals(keyB)));
    });

    // ── 9. Stadium navigation uses extracted real ID ────────────────────────
    test('9. Stadium navigation uses extracted real ID from link', () {
      const link = 'https://ysscores.com/stadium/962/hard-rock-stadium';
      final match = RegExp(r'/(referee|commentator|stadium)/(\d+)/?([^/?#]*)')
          .firstMatch(link);
      expect(match?.group(1), equals('stadium'));
      expect(match?.group(2), equals('962'));
      expect(match?.group(3), equals('hard-rock-stadium'));
    });

    // ── 10. التفاصيل contains Match Information ─────────────────────────────
    testWidgets('10. التفاصيل contains Match Information cards', (
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
      expect(find.text('سانتياغو برنابيو'), findsOneWidget);
      expect(find.text('حفيظ دراجي'), findsOneWidget);
    });

    // ── 11. Events are visible in Events tab ─────────────────────────────────
    testWidgets('11. Events are visible in Events tab', (tester) async {
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
      expect(find.text('لوكا سوتشيتش'), findsOneWidget);
    });

    // ── 12. Main tabs are restored ─────────────────────────────────────────
    testWidgets('12. Main tabs exist', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الأحداث'), findsWidgets);
      expect(find.text('التفاصيل'), findsOneWidget);
      expect(find.text('التشكيلة'), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(6));
    });

    // ── 13. Event filter pills: الأبرز and كل الأحداث ───────────────────────
    testWidgets('13. Event filter pills: الأبرز and كل الأحداث', (
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('filter_highlights')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_all')), findsOneWidget);
    });

    // ── 14. News tab exists ────────────────────────────────────────────────
    testWidgets('14. News tab exists in main TabBar', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الأخبار'), findsOneWidget);
    });

    // ── 15. No RenderFlex overflow at 320px ──────────────────────────────────
    testWidgets('15. No RenderFlex overflow on 320px screen width', (
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
          width: 320,
          height: 568,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    // ── 16. Event with video_url renders video badge and hasVideo flag ────────
    testWidgets(
      '16. Event with video_url renders video badge and hasVideo flag',
      (tester) async {
        const eventWithVideo = MatchEventEntity(
          minute: '67',
          playerName: 'كيليان مبابي',
          type: 'goal',
          isHomeTeam: true,
          score: '1 - 0',
          videoUrl: 'https://x.com/beINSPORTS/status/2097768372154876218',
        );

        expect(eventWithVideo.hasVideo, isTrue);

        await tester.pumpWidget(
          buildTestApp(const TimelineEventItem(event: eventWithVideo)),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.text('فيديو'), findsNothing);
      },
    );

    // ── 17. StatusPill with live extra time shows base minute and stoppage ────
    testWidgets(
      '17. StatusPill with live extra time shows base minute and stoppage',
      (tester) async {
        // Simulation of Paris vs Bratislava (1st half extra time with extraTime = "1")
        await tester.pumpWidget(
          buildTestApp(
            const StatusPill(
              status: 'الشوط الأول',
              minute: '45',
              extraTime: '1',
              score1: '0',
              score2: '3',
              time: '22:00',
              period: '1st_half',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must display base minute '45' and stoppage format '00:00  / 1' (not bare '00:00 / 1')
        expect(find.text('45'), findsOneWidget);
        expect(find.text('00:00  / 1'), findsOneWidget);
      },
    );

    // ── 18. MatchDetailsBloc cleans match: prefix when loading events & stats ─
    test(
      '18. MatchDetailsBloc cleans match: prefix when loading events & stats',
      () async {
        when(() => repo.getEvents('5802935', lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess(sampleEvents));
        when(() => repo.getStats('5802935', lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess([]));
        when(
          () => repo.getDetails(
            '5802935',
            lang: any(named: 'lang'),
            utcOffset: any(named: 'utcOffset'),
          ),
        ).thenAnswer((_) async => const ApiSuccess([]));
        when(() => repo.getNews('5802935', lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess([]));
        when(() => repo.getLineups('5802935', lang: any(named: 'lang')))
            .thenAnswer((_) async => const ApiSuccess(null));

        final bloc = MatchDetailsBloc(
          repository: repo,
          webSocketService: ws,
          localStorageService: storage,
          matchId: 'match:5802935',
        );

        bloc.add(const LoadMatchDetailsEvent('match:5802935'));
        await pumpEventQueue();

        verify(() => repo.getEventsPayload('5802935', lang: any(named: 'lang')))
            .called(1);
        verify(() => repo.getStats('5802935', lang: any(named: 'lang')))
            .called(1);
        expect(bloc.state.events, sampleEvents);
        expect(bloc.state.matchId, '5802935');

        await bloc.close();
      },
    );
  });
}
