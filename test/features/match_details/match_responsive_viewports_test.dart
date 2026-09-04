import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/network/api_result.dart';
import 'package:ysscores/core/storage/local_storage_service.dart';
import 'package:ysscores/core/theme/app_theme.dart';
import 'package:ysscores/core/websocket/websocket_service.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';
import 'package:ysscores/features/match_details/domain/repositories/match_details_repository.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:ysscores/features/match_details/presentation/views/match_details_view.dart';
import 'package:ysscores/features/matches/domain/entities/match_entity.dart';

class MockMatchDetailsRepository extends Mock
    implements MatchDetailsRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

Widget buildResponsiveApp({
  required Widget child,
  required double width,
  required double height,
}) {
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
      child: child,
    ),
  );
}

void main() {
  late MockMatchDetailsRepository repo;
  late MockWebSocketService ws;
  late MockLocalStorageService storage;

  const testMatch = MatchEntity(
    id: '5868018',
    team1: 'ريال مدريد',
    team2: 'ريال سوسيداد',
    score1: '4',
    score2: '1',
    status: 'انتهت المباراة',
  );

  const sampleEvents = [
    MatchEventEntity(
      minute: '90’ +4',
      playerName: 'إدواردو كامافينجا',
      type: 'event',
      isHomeTeam: true,
    ),
    MatchEventEntity(
      minute: '90’',
      playerName: 'إبراهيم دياز',
      secondaryPlayerName: 'تسلل',
      type: 'goal-x',
      isHomeTeam: true,
    ),
    MatchEventEntity(
      minute: '80’',
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
      minute: '44’',
      playerName: 'لوكا سوتشيتش',
      type: 'goal',
      isHomeTeam: false,
    ),
  ];

  const sampleStats = [
    MatchStatItemEntity(
      title: 'الاستحواذ',
      homeValue: '62%',
      awayValue: '38%',
      homePercentage: 0.62,
    ),
    MatchStatItemEntity(
      title: 'التسديدات',
      homeValue: '18',
      awayValue: '7',
      homePercentage: 0.72,
    ),
  ];

  const sampleDetails = [
    MatchInfoSectionEntity(
      section: 'معلومات اللقاء',
      items: [
        MatchInfoItemEntity(title: 'القناة', content: 'بي إن سبورت 1'),
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
    when(() => repo.getStats(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => const ApiSuccess(sampleStats));
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

  group('Match Details Responsive Matrix Tests (320px - 1024px)', () {
    final viewports = [
      (320.0, 568.0, '320px (iPhone SE 1st gen)'),
      (360.0, 640.0, '360px (Standard Android)'),
      (375.0, 667.0, '375px (iPhone SE 2nd gen)'),
      (390.0, 844.0, '390px (iPhone 14)'),
      (412.0, 915.0, '412px (Pixel 7)'),
      (600.0, 960.0, '600px (Foldable / Small Tablet)'),
      (768.0, 1024.0, '768px (iPad Mini)'),
      (1024.0, 1366.0, '1024px (iPad Pro / Desktop)'),
    ];

    for (final (w, h, desc) in viewports) {
      testWidgets('renders zero RenderFlex overflow on $desc', (tester) async {
        await tester.pumpWidget(
          buildResponsiveApp(
            width: w,
            height: h,
            child: BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: '5868018',
              ),
              child: const MatchDetailsView(
                matchId: '5868018',
                initialMatch: testMatch,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Must render without exception
        expect(tester.takeException(), isNull);

        // Filter pills must be present in Events tab
        expect(find.byKey(const ValueKey('filter_highlights')), findsOneWidget);
        expect(find.byKey(const ValueKey('filter_all')), findsOneWidget);

        // Switch to all events filter
        await tester.tap(find.byKey(const ValueKey('filter_all')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
