import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/features/standings/data/datasources/standings_remote_datasource.dart';
import 'package:score154/features/standings/domain/entities/standings_entity.dart';
import 'package:score154/features/standings/presentation/widgets/standings_table.dart';
import 'package:score154/features/standings/presentation/widgets/tournament_stages_widget.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget createTestApp(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('Tournament Stages and Standings Fix Tests', () {
    test('DataSource parses stages correctly for cup championships', () async {
      final mockClient = MockApiClient();
      final ds = StandingsRemoteDataSourceImpl(mockClient);

      final mockPayload = {
        'success': true,
        'data': {
          'league_name': 'دوري أبطال أفريقيا | الأدوار الإقصائية',
          'table': [],
          'stages': [
            {
              'stage_name': 'ربع النهائي',
              'stage_id': 'qf',
              'round': 1,
              'teams_number': 8,
              'matches': [
                {
                  'match_id': 'm101',
                  'position': 'QF 1',
                  'team_a': {
                    'id': '1',
                    'name': 'الأهلي',
                    'logo': 'https://example.com/ahly.png',
                    'score': 2,
                    'is_winner': true,
                  },
                  'team_b': {
                    'id': '2',
                    'name': 'صن داونز',
                    'logo': 'https://example.com/sundowns.png',
                    'score': 0,
                    'is_winner': false,
                  },
                  'winner_id': '1',
                  'match_date': '2024-04-10',
                  'match_time': '21:00',
                },
              ],
            },
            {
              'stage_name': 'النهائي',
              'stage_id': 'final',
              'round': 2,
              'teams_number': 2,
              'matches': [
                {
                  'match_id': 'm102',
                  'position': 'Final',
                  'team_a': {
                    'id': '1',
                    'name': 'الأهلي',
                    'logo': 'https://example.com/ahly.png',
                    'score': 1,
                    'is_winner': true,
                  },
                  'team_b': {
                    'id': '3',
                    'name': 'الترجي',
                    'logo': 'https://example.com/taraji.png',
                    'score': 0,
                    'is_winner': false,
                  },
                  'winner_id': '1',
                  'match_date': '2024-05-25',
                  'match_time': '20:00',
                },
              ],
            },
          ],
        },
      };

      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockPayload);

      final result = await ds.getStandings('943487', lang: 'ar');

      expect(result.hasStages, isTrue);
      expect(result.isKnockoutOnly, isTrue);
      expect(result.stages?.length, equals(2));
      expect(result.stages![0].stageName, equals('ربع النهائي'));
      expect(result.stages![0].matches.length, equals(1));
      expect(result.stages![0].matches[0].teamA.name, equals('الأهلي'));
      expect(result.stages![0].matches[0].teamA.score, equals(2));
      expect(result.stages![0].matches[0].teamA.isWinner, isTrue);
      expect(result.stages![0].matches[0].teamB.name, equals('صن داونز'));
      expect(result.stages![0].matches[0].teamB.score, equals(0));
      expect(result.stages![1].stageName, equals('النهائي'));
    });

    test('LeagueStandingsEntity correctly detects hasBothGroupsAndStages', () {
      const stage = TournamentStageEntity(stageName: 'النهائي', matches: []);

      const row = StandingRowEntity(
        position: 1,
        teamName: 'Team 1',
        played: 3,
        wins: 2,
        draws: 1,
        losses: 0,
        goalsFor: 5,
        goalsAgainst: 1,
        goalDiff: 4,
        points: 7,
      );

      const entityBoth = LeagueStandingsEntity(
        leagueId: '894789',
        leagueTitle: 'كأس العالم',
        rows: [row],
        groups: {
          'المجموعة A': [row],
        },
        stages: [stage],
      );

      expect(entityBoth.hasStages, isTrue);
      expect(entityBoth.isKnockoutOnly, isFalse);
      expect(entityBoth.hasBothGroupsAndStages, isTrue);
    });

    testWidgets('StandingsTable handles and fixes duplicate rank numbers', (
      tester,
    ) async {
      // Simulating table with duplicate positions (like 1, 1, 2, 2)
      final duplicateRows = [
        const StandingRowEntity(
          position: 1,
          teamName: 'برشلونة',
          played: 20,
          wins: 15,
          draws: 5,
          losses: 0,
          goalsFor: 50,
          goalsAgainst: 10,
          goalDiff: 40,
          points: 50,
        ),
        const StandingRowEntity(
          position: 1, // Duplicate position!
          teamName: 'ريال سوسيداد',
          played: 20,
          wins: 10,
          draws: 5,
          losses: 5,
          goalsFor: 30,
          goalsAgainst: 20,
          goalDiff: 10,
          points: 35,
        ),
        const StandingRowEntity(
          position: 2, // Another duplicate!
          teamName: 'أتلتيكو مدريد',
          played: 20,
          wins: 12,
          draws: 4,
          losses: 4,
          goalsFor: 40,
          goalsAgainst: 25,
          goalDiff: 15,
          points: 40,
        ),
      ];

      await tester.pumpWidget(
        createTestApp(StandingsTable(rows: duplicateRows)),
      );
      await tester.pumpAndSettle();

      // Ensure that '1', '2', and '3' are displayed sequentially, NOT two '1's!
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('برشلونة'), findsOneWidget);
      expect(find.text('ريال سوسيداد'), findsOneWidget);
      expect(find.text('أتلتيكو مدريد'), findsOneWidget);
    });

    testWidgets('TournamentStagesWidget renders stage pills and match cards', (
      tester,
    ) async {
      final stages = [
        const TournamentStageEntity(
          stageName: 'نصف النهائي',
          matches: [
            StageMatchEntity(
              matchId: 'm1',
              teamA: StageTeamEntity(name: 'فرنسا', score: 2, isWinner: true),
              teamB: StageTeamEntity(name: 'المغرب', score: 0, isWinner: false),
              matchDate: '2022-12-14',
            ),
          ],
        ),
        const TournamentStageEntity(
          stageName: 'النهائي',
          matches: [
            StageMatchEntity(
              matchId: 'm2',
              teamA: StageTeamEntity(
                name: 'الأرجنتين',
                score: 3,
                isWinner: true,
              ),
              teamB: StageTeamEntity(name: 'فرنسا', score: 3, isWinner: false),
              matchDate: '2022-12-18',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        createTestApp(TournamentStagesWidget(stages: stages)),
      );
      await tester.pumpAndSettle();

      // Because 'النهائي' is the final stage, it should default to 'النهائي'
      expect(find.text('النهائي'), findsOneWidget);
      expect(find.text('نصف النهائي'), findsOneWidget);
      expect(find.text('الأرجنتين'), findsOneWidget);
      expect(find.text('فرنسا'), findsOneWidget);

      // Tap on 'نصف النهائي' pill
      await tester.tap(find.text('نصف النهائي'));
      await tester.pumpAndSettle();

      expect(find.text('المغرب'), findsOneWidget);
    });
  });
}
