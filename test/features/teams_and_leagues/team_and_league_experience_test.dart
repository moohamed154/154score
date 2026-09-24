import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:score154/features/leagues/domain/entities/league_entity.dart';
import 'package:score154/features/leagues/domain/entities/top_scorer_entity.dart';
import 'package:score154/features/leagues/domain/repositories/leagues_repository.dart';
import 'package:score154/features/leagues/presentation/bloc/league_bloc.dart';
import 'package:score154/features/leagues/presentation/views/league_view.dart';
import 'package:score154/features/leagues/presentation/widgets/league_header_card.dart';
import 'package:score154/features/leagues/presentation/widgets/top_scorers_table.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';
import 'package:score154/features/standings/domain/entities/standings_entity.dart';
import 'package:score154/features/standings/presentation/widgets/standings_table.dart';
import 'package:score154/features/teams/domain/entities/team_entity.dart';
import 'package:score154/features/teams/domain/repositories/teams_repository.dart';
import 'package:score154/features/teams/presentation/bloc/team_bloc.dart';
import 'package:score154/features/teams/presentation/views/team_view.dart';
import 'package:score154/features/teams/presentation/widgets/team_header_card.dart';
import 'package:score154/features/transfers/domain/entities/transfer_entity.dart';
import 'package:score154/features/transfers/presentation/widgets/transfer_card.dart';

class MockLocalStorageService implements LocalStorageService {
  @override
  Future<void> init() async {}

  @override
  String getLanguage() => 'ar';

  @override
  Future<bool> setLanguage(String langCode) async => true;

  @override
  String getThemeMode() => 'dark';

  @override
  Future<bool> setThemeMode(String themeMode) async => true;

  @override
  String getTimeFormat() => '24h';

  @override
  Future<bool> setTimeFormat(String format) async => true;

  @override
  int getTimezoneOffset() => 0;

  @override
  Future<bool> setTimezoneOffset(int offset) async => true;

  @override
  bool isTimezoneAuto() => true;

  @override
  Future<bool> setTimezoneAuto(bool isAuto) async => true;

  @override
  int getDeviceTimezoneOffset() => 3;

  @override
  List<String> getFavoriteTeams() => [];

  @override
  Future<bool> toggleFavoriteTeam(String teamName) async => true;

  @override
  bool isFavoriteTeam(String teamName) => false;

  @override
  List<String> getFavoriteCompetitions() => [];

  @override
  Future<bool> toggleFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) async => true;

  @override
  bool isFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) => false;

  @override
  Map<String, String> getFavoriteCompetitionTitles() => {};

  @override
  Future<bool> registerCompetitionTitles(Map<String, String> titles) async =>
      true;

  @override
  String resolveCompetitionTitle(String compOrId) => compOrId;

  @override
  List<String> getFavoriteMatches() => [];

  @override
  Future<bool> toggleFavoriteMatch(String matchId) async => true;

  @override
  bool isFavoriteMatch(String matchId) => false;

  @override
  Future<bool> setFavoriteCompetitions(List<String> list) async => true;

  @override
  String? getCachedRankings({String? lang}) => null;

  @override
  Future<bool> setCachedRankings(String json, {String? lang}) async => true;

  @override
  bool isReorderTipDismissed() => true;

  @override
  Future<bool> setReorderTipDismissed(bool dismissed) async => true;

  @override
  String? getMatchesFilter() => null;

  @override
  Future<bool> setMatchesFilter(String filter) async => true;

  @override
  String? getMatchesSortOrder() => null;

  @override
  Future<bool> setMatchesSortOrder(String sortOrder) async => true;

  @override
  bool hasCustomFavoriteCompetitions() => false;
}

class MockLeaguesRepository implements LeaguesRepository {
  @override
  Future<ApiResult<LeagueStandingsEntity>> getLeagueStandings(
    String leagueId, {
    required String lang,
  }) async {
    return const ApiSuccess(
      LeagueStandingsEntity(
        leagueId: '937599',
        leagueTitle: 'الدوري الإسباني الدرجة الأولى',
        rows: [
          StandingRowEntity(
            position: 1,
            teamName: 'ريال مدريد',
            teamLogo: 'https://example.com/rm.png',
            played: 28,
            wins: 21,
            draws: 6,
            losses: 1,
            goalsFor: 65,
            goalsAgainst: 20,
            goalDiff: 45,
            points: 69,
            rankColor: '#4CAF50',
          ),
          StandingRowEntity(
            position: 2,
            teamName: 'برشلونة',
            teamLogo: 'https://example.com/fcb.png',
            played: 28,
            wins: 19,
            draws: 7,
            losses: 2,
            goalsFor: 60,
            goalsAgainst: 24,
            goalDiff: 36,
            points: 64,
            rankColor: '#4CAF50',
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<List<TopScorerEntity>>> getLeagueTopScorers(
    String leagueId, {
    required String lang,
  }) async {
    return const ApiSuccess([
      TopScorerEntity(
        rank: 1,
        playerName: 'كيليان مبابي',
        playerImage: 'https://example.com/mbappe.png',
        teamName: 'ريال مدريد',
        teamLogo: 'https://example.com/rm.png',
        goals: 22,
        assists: 6,
      ),
      TopScorerEntity(
        rank: 2,
        playerName: 'روبرت ليفاندوفسكي',
        playerImage: 'https://example.com/lewa.png',
        teamName: 'برشلونة',
        teamLogo: 'https://example.com/fcb.png',
        goals: 19,
        assists: 4,
      ),
      TopScorerEntity(
        rank: 3,
        playerName: 'فينيسيوس جونيور',
        playerImage: 'https://example.com/vini.png',
        teamName: 'ريال مدريد',
        teamLogo: 'https://example.com/rm.png',
        goals: 16,
        assists: 9,
      ),
    ]);
  }

  @override
  Future<ApiResult<List<MatchEntity>>> getLeagueMatches(
    String leagueId, {
    required String lang,
    String? date,
  }) async {
    return const ApiSuccess([
      MatchEntity(
        id: '101',
        team1: 'ريال مدريد',
        team2: 'برشلونة',
        score1: '3',
        score2: '2',
        status: 'انتهت',
        leagueId: '937599',
        leagueTitle: 'الدوري الإسباني',
      ),
    ]);
  }

  @override
  Future<ApiResult<Map<String, dynamic>?>> getLeagueProfile(
    String leagueId, {
    required String lang,
  }) async {
    return const ApiSuccess({
      'country': 'إسبانيا',
      'current_season': {'season_name': '2026/2027'},
      'name': 'الدوري الإسباني',
    });
  }

  @override
  Future<ApiResult<List<TopScorerEntity>>> getLeagueAssists(
    String leagueId, {
    required String lang,
  }) async {
    return const ApiSuccess([]);
  }

  @override
  Future<ApiResult<LeagueDetailsEntity>> getLeagueFullDetails(
    String leagueId, {
    required String lang,
    bool forceRefresh = false,
  }) async {
    return ApiSuccess(
      LeagueDetailsEntity(
        id: leagueId,
        name: 'الدوري الإسباني',
        standings: const LeagueStandingsEntity(
          leagueId: '937599',
          leagueTitle: 'الدوري الإسباني الدرجة الأولى',
          rows: [],
        ),
        topScorers: const [],
        topAssists: const [],
        matches: const [],
      ),
    );
  }
}

class MockTeamsRepository implements TeamsRepository {
  @override
  Future<ApiResult<TeamProfileEntity>> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  }) async {
    return const ApiSuccess(
      TeamProfileEntity(
        teamId: 'rm',
        teamName: 'ريال مدريد',
        teamLogo: 'https://example.com/rm.png',
        leagueId: '937599',
        leagueName: 'الدوري الإسباني',
        form: ['W', 'W', 'D', 'W', 'W'],
        standingsRow: StandingRowEntity(
          position: 1,
          teamName: 'ريال مدريد',
          played: 28,
          wins: 21,
          draws: 6,
          losses: 1,
          goalsFor: 65,
          goalsAgainst: 20,
          goalDiff: 45,
          points: 69,
        ),
        upcomingMatches: [
          MatchEntity(
            id: '201',
            team1: 'ريال مدريد',
            team2: 'إشبيلية',
            time: '21:00',
            status: 'لم تبدأ',
            leagueId: '937599',
            leagueTitle: 'الدوري الإسباني',
          ),
        ],
        recentMatches: [
          MatchEntity(
            id: '101',
            team1: 'ريال مدريد',
            team2: 'برشلونة',
            score1: '3',
            score2: '2',
            penaltyScore1: '4',
            penaltyScore2: '3',
            status: 'انتهت',
            leagueId: '937599',
            leagueTitle: 'الدوري الإسباني',
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<LeagueStandingsEntity>> getChampionshipStandings(
    String championshipId, {
    required String lang,
  }) async {
    return const ApiSuccess(
      LeagueStandingsEntity(
        leagueId: '937599',
        leagueTitle: 'الدوري الإسباني الدرجة الأولى',
        rows: [],
      ),
    );
  }
}

Widget createTestApp(Widget child, {Locale locale = const Locale('ar')}) {
  return BlocProvider<FavoritesCubit>(
    create: (_) => FavoritesCubit(MockLocalStorageService()),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: ThemeData.dark(),
      home: child,
    ),
  );
}

void main() {
  group('154Score V4.5 — Team & League Experience Tests', () {
    testWidgets(
      '1. TeamHeaderCard displays name, league, rank, and form pills',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const profile = TeamProfileEntity(
          teamId: 'rm',
          teamName: 'ريال مدريد',
          leagueName: 'الدوري الإسباني',
          form: ['W', 'W', 'D', 'L', 'W'],
          standingsRow: StandingRowEntity(
            position: 1,
            teamName: 'ريال مدريد',
            played: 28,
            wins: 21,
            draws: 6,
            losses: 1,
            goalsFor: 65,
            goalsAgainst: 20,
            goalDiff: 45,
            points: 69,
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: TeamHeaderCard(
                profile: profile,
                fallbackName: 'ريال مدريد',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ريال مدريد'), findsWidgets);
        expect(find.text('الدوري الإسباني'), findsOneWidget);
        expect(find.text('#1 (69 نقطة)'), findsOneWidget);
        expect(find.text('ف'), findsWidgets);
        expect(find.text('ت'), findsWidgets);
        expect(find.text('خ'), findsWidgets);
      },
    );

    testWidgets('2. LeagueHeaderCard displays title and responsive layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: LeagueHeaderCard(
              title: 'دوري أبطال أوروبا',
              country: 'أوروبا',
              season: '2025/2026',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('دوري أبطال أوروبا'), findsOneWidget);
      expect(find.text('أوروبا'), findsOneWidget);
      expect(find.text('2025/2026'), findsOneWidget);
    });

    testWidgets('3. TopScorersTable displays rankings, names, and goals', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const scorers = [
        TopScorerEntity(
          rank: 1,
          playerName: 'كيليان مبابي',
          teamName: 'ريال مدريد',
          goals: 22,
        ),
        TopScorerEntity(
          rank: 2,
          playerName: 'روبرت ليفاندوفسكي',
          teamName: 'برشلونة',
          goals: 19,
        ),
      ];

      await tester.pumpWidget(
        createTestApp(const Scaffold(body: TopScorersTable(scorers: scorers))),
      );
      await tester.pumpAndSettle();

      expect(find.text('كيليان مبابي'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('روبرت ليفاندوفسكي'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
    });

    testWidgets('4. TeamView renders tabs and overview content cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final teamBloc = TeamBloc(
        repository: MockTeamsRepository(),
        localStorageService: MockLocalStorageService(),
        teamId: 'rm',
        initialName: 'ريال مدريد',
      );

      await tester.pumpWidget(
        createTestApp(
          BlocProvider.value(
            value: teamBloc,
            child: const TeamView(teamId: 'rm', initialName: 'ريال مدريد'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ريال مدريد'), findsWidgets);
      expect(find.text('المباريات'), findsOneWidget);
      expect(find.text('الترتيب'), findsOneWidget);
      expect(find.text('اللاعبين'), findsOneWidget);
    });

    testWidgets('5. LeagueView renders tabs, standings, and top scorers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final leagueBloc = LeagueBloc(
        repository: MockLeaguesRepository(),
        localStorageService: MockLocalStorageService(),
        leagueId: '937599',
        initialTitle: 'الدوري الإسباني',
      );

      await tester.pumpWidget(
        createTestApp(
          BlocProvider.value(
            value: leagueBloc,
            child: const LeagueView(
              leagueId: '937599',
              initialTitle: 'الدوري الإسباني',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('الدوري الإسباني'), findsWidgets);
      expect(find.text('الهدافون'), findsOneWidget);
      expect(find.text('الترتيب'), findsWidgets);
    });

    testWidgets('6. Responsive Breakpoint Validation (320px to 1024px)', (
      tester,
    ) async {
      final widths = [320.0, 360.0, 375.0, 390.0, 414.0, 600.0, 768.0, 1024.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;

        const profile = TeamProfileEntity(
          teamId: 'rm',
          teamName: 'ريال مدريد دي فوتبول نادي العاصمة الإسبانية',
          leagueName: 'الدوري الإسباني الدرجة الأولى الممتاز',
          form: ['W', 'D', 'L', 'W', 'W'],
        );

        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    TeamHeaderCard(
                      profile: profile,
                      fallbackName: 'ريال مدريد',
                    ),
                    TopScorersTable(
                      scorers: [
                        TopScorerEntity(
                          rank: 1,
                          playerName:
                              'كيليان مبابي لوتين دي ريفر بلايت سانت جيرمان',
                          teamName: 'ريال مدريد الإسباني',
                          goals: 25,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('7. MatchCard, StandingsTable, and TransferCard team clicks', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const match = MatchEntity(
        id: '101',
        team1: 'ريال مدريد',
        team2: 'برشلونة',
        score1: '2',
        score2: '1',
        status: 'انتهت',
      );

      const rows = [
        StandingRowEntity(
          position: 1,
          teamName: 'ريال مدريد',
          played: 10,
          wins: 8,
          draws: 2,
          losses: 0,
          goalsFor: 20,
          goalsAgainst: 5,
          goalDiff: 15,
          points: 26,
        ),
      ];

      const transfer = TransferEntity(
        id: 't1',
        playerName: 'لاعب تجريبي',
        fromTeamName: 'النادي السابق',
        toTeamName: 'النادي الجديد',
        date: '2026-08-20',
      );

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  MatchCard(match: match),
                  StandingsTable(rows: rows),
                  TransferCard(transfer: transfer),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ريال مدريد'), findsWidgets);
      expect(find.text('برشلونة'), findsWidgets);
      expect(find.text('النادي السابق'), findsOneWidget);
      expect(find.text('النادي الجديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
