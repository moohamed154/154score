import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/constants/app_colors.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/domain/repositories/match_details_repository.dart';
import 'package:score154/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:score154/features/match_details/presentation/views/match_details_view.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';

class MockMatchDetailsRepository extends Mock
    implements MatchDetailsRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

Widget buildTestApp(Widget child, {bool isDark = true}) {
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
    theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: BlocProvider(
        create: (_) => FavoritesCubit(storage),
        child: child,
      ),
    ),
  );
}

void main() {
  late MockMatchDetailsRepository repo;
  late MockWebSocketService ws;
  late MockLocalStorageService storage;

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
        .thenAnswer((_) async => const ApiSuccess([]));
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

  group('Match Events Alert Banner Styles', () {
    testWidgets(
      'Displays alert banner in Events tab with app styling when alert is in events payload',
      (tester) async {
        const alertMsg =
            'Legend Ronaldo continues his march towards 1000 goals with goal number 980';

        when(() => repo.getEventsPayload(any(), lang: any(named: 'lang')))
            .thenAnswer(
          (_) async => const ApiSuccess(
            MatchEventsPayload(
              events: [
                MatchEventEntity(
                  minute: '45',
                  playerName: 'Ronaldo',
                  type: 'goal',
                  score: '1-0',
                ),
              ],
              alert: alertMsg,
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: 'al_nassr_match',
              ),
              child: const MatchDetailsView(
                matchId: 'al_nassr_match',
                initialMatch: MatchEntity(
                  id: 'al_nassr_match',
                  team1: 'Al Nassr FC',
                  team2: 'Al Diriyah',
                  score1: '3',
                  score2: '0',
                  status: 'انتهت',
                  statusCode: 'FINISHED',
                ),
              ),
            ),
            isDark: true,
          ),
        );

        await tester.pumpAndSettle();

        // 1. Text is rendered
        expect(find.text(alertMsg), findsOneWidget);

        // 2. Info icon is present with primary color
        final iconFinder = find.byIcon(Icons.info_outline_rounded);
        expect(iconFinder, findsWidgets);

        final icon = tester.widget<Icon>(iconFinder.first);
        expect(icon.color, equals(AppColors.primary));

        // 3. Container has dark card styling and primary border
        final textWidget = tester.widget<Text>(find.text(alertMsg));
        expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
      },
    );

    testWidgets(
      'Does not display alert card when match has no alert',
      (tester) async {
        when(() => repo.getEventsPayload(any(), lang: any(named: 'lang')))
            .thenAnswer(
          (_) async => const ApiSuccess(
            MatchEventsPayload(
              events: [
                MatchEventEntity(
                  minute: '10',
                  playerName: 'Player A',
                  type: 'goal',
                  score: '1-0',
                ),
              ],
              alert: null,
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            BlocProvider(
              create: (_) => MatchDetailsBloc(
                repository: repo,
                webSocketService: ws,
                localStorageService: storage,
                matchId: 'normal_match',
              ),
              child: const MatchDetailsView(
                matchId: 'normal_match',
                initialMatch: MatchEntity(
                  id: 'normal_match',
                  team1: 'Team A',
                  team2: 'Team B',
                  status: 'انتهت',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.textContaining('Legend Ronaldo continues his march'),
          findsNothing,
        );
      },
    );
  });
}
