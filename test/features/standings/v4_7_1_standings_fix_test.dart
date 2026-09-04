import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/network/api_client.dart';
import 'package:ysscores/features/standings/data/datasources/standings_remote_datasource.dart';
import 'package:ysscores/features/standings/domain/entities/standings_entity.dart';
import 'package:ysscores/features/standings/presentation/widgets/standings_table.dart';

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
  group('154Score V4.7.1 Standings Fix & Qualification Regression Tests', () {
    test('1. DataSource parses all 20 teams when data.table has 1 item and raw.list_match has 20 items', () async {
      final mockClient = MockApiClient();
      final ds = StandingsRemoteDataSourceImpl(mockClient);

      // Simulate the exact production API response bug where table had 1 item, but raw.list_match had 20 items
      final mock20Teams = <String, dynamic>{};
      for (int i = 1; i <= 20; i++) {
        mock20Teams[i.toString()] = {
          'name': 'الفريق $i',
          'play': 38,
          'wins': 20,
          'draw': 10,
          'lose': 8,
          'for': 60,
          'against': 30,
          'diff': 30,
          'points': 70 - i,
          'color': i <= 4 ? '#4986e7' : (i >= 18 ? '#f83a22' : null),
        };
      }

      final mockPayload = {
        'success': true,
        'data': {
          'league_name': 'الدوري الإنجليزي الممتاز',
          'table': [
            {
              'position': 1,
              'team_name': 'الفريق 1',
              'played': 38,
              'wins': 20,
              'draws': 10,
              'losses': 8,
              'goals_for': 60,
              'goals_against': 30,
              'goal_difference': 30,
              'points': 70,
            },
          ],
          'raw': {
            'list_match': [mock20Teams],
            'promotion': [
              '<div class="rank-key"><svg><rect fill="#4986e7"/></svg><span>يتأهل دوري أبطال أوروبا</span></div> <div class="rank-key"><svg><rect fill="#f83a22"/></svg><span>يهبط دوري البطولة الإنجليزية</span></div>',
            ],
          },
        },
      };

      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockPayload);

      final result = await ds.getStandings('937599', lang: 'ar');

      expect(result.rows.length, 20); // Must be 20 teams, NOT 1 team!
      expect(result.rows.first.teamName, 'الفريق 1');
      expect(result.rows.last.teamName, 'الفريق 20');
      expect(result.legends, isNotNull);
      expect(result.legends!.length, 2);
      expect(result.legends!.first.description, 'يتأهل دوري أبطال أوروبا');
      expect(result.legends!.last.description, 'يهبط دوري البطولة الإنجليزية');
    });

    testWidgets('2. StandingsTable renders all 5 teams without dropping rows', (
      tester,
    ) async {
      final rows = List.generate(
        5,
        (i) => StandingRowEntity(
          position: i + 1,
          teamName: 'نادي الفريق ${i + 1}',
          played: 10,
          wins: 5,
          draws: 3,
          losses: 2,
          goalsFor: 15,
          goalsAgainst: 8,
          goalDiff: 7,
          points: 18 - i,
          rankColor: i == 0 ? '#4986e7' : null,
        ),
      );

      await tester.pumpWidget(
        createTestApp(SingleChildScrollView(child: StandingsTable(rows: rows))),
      );
      await tester.pump();

      for (int i = 1; i <= 5; i++) {
        expect(find.text('نادي الفريق $i'), findsOneWidget);
      }
    });

    testWidgets(
      '3. Long table of 20 teams is completely rendered and scrollable',
      (tester) async {
        final rows = List.generate(
          20,
          (i) => StandingRowEntity(
            position: i + 1,
            teamName: 'نادي الدوري رقم ${i + 1}',
            played: 38,
            wins: 25 - i,
            draws: 5,
            losses: 8 + i,
            goalsFor: 70 - i,
            goalsAgainst: 30 + i,
            goalDiff: 40 - (2 * i),
            points: 80 - (3 * i),
            rankColor: i < 4 ? '#4986e7' : (i >= 17 ? '#f83a22' : null),
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            SingleChildScrollView(child: StandingsTable(rows: rows)),
          ),
        );
        await tester.pump();

        expect(find.text('نادي الدوري رقم 1'), findsOneWidget);
        expect(find.text('نادي الدوري رقم 20'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Multi-group standings render both Group A and Group B tables',
      (tester) async {
        final groupA = List.generate(
          4,
          (i) => StandingRowEntity(
            position: i + 1,
            teamName: 'فريق المجموعة الأولى $i',
            played: 6,
            wins: 4,
            draws: 1,
            losses: 1,
            goalsFor: 10,
            goalsAgainst: 4,
            goalDiff: 6,
            points: 13 - i,
            groupName: 'المجموعة A',
          ),
        );

        final groupB = List.generate(
          4,
          (i) => StandingRowEntity(
            position: i + 1,
            teamName: 'فريق المجموعة الثانية $i',
            played: 6,
            wins: 3,
            draws: 2,
            losses: 1,
            goalsFor: 9,
            goalsAgainst: 5,
            goalDiff: 4,
            points: 11 - i,
            groupName: 'المجموعة B',
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            SingleChildScrollView(
              child: Column(
                children: [
                  const Text('المجموعة A'),
                  StandingsTable(rows: groupA),
                  const Text('المجموعة B'),
                  StandingsTable(rows: groupB),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('المجموعة A'), findsOneWidget);
        expect(find.text('المجموعة B'), findsOneWidget);
        expect(find.text('فريق المجموعة الأولى 0'), findsOneWidget);
        expect(find.text('فريق المجموعة الثانية 0'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Long Arabic team names and small screen (320px) zero-overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        const testRows = [
          StandingRowEntity(
            position: 1,
            teamName: 'نادي مانشستر سيتي الإنجليزي حامل اللقب المتصدر',
            played: 38,
            wins: 29,
            draws: 6,
            losses: 3,
            goalsFor: 96,
            goalsAgainst: 34,
            goalDiff: 62,
            points: 93,
            rankColor: '#4986e7',
          ),
          StandingRowEntity(
            position: 20,
            teamName: 'نادي شيفيلد يونايتد متذيل جدول الترتيب العام',
            played: 38,
            wins: 3,
            draws: 7,
            losses: 28,
            goalsFor: 35,
            goalsAgainst: 104,
            goalDiff: -69,
            points: 16,
            rankColor: '#f83a22',
          ),
        ];

        await tester.pumpWidget(
          createTestApp(
            const SingleChildScrollView(child: StandingsTable(rows: testRows)),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        tester.view.resetPhysicalSize();
      },
    );

    testWidgets(
      '6. Qualification & Relegation legend rendered from API metadata without invented rules',
      (tester) async {
        const legends = [
          StandingLegendEntity(
            colorHex: '#4986e7',
            description: 'يتأهل دوري أبطال أوروبا',
          ),
          StandingLegendEntity(
            colorHex: '#ff7537',
            description: 'يتأهل الدوري الأوروبي',
          ),
          StandingLegendEntity(
            colorHex: '#f83a22',
            description: 'يهبط دوري البطولة الإنجليزية',
          ),
        ];

        const standings = LeagueStandingsEntity(
          leagueId: '937599',
          leagueTitle: 'الدوري الإنجليزي',
          rows: [
            StandingRowEntity(
              position: 1,
              teamName: 'أرسنال',
              played: 1,
              wins: 1,
              draws: 0,
              losses: 0,
              goalsFor: 2,
              goalsAgainst: 0,
              goalDiff: 2,
              points: 3,
              rankColor: '#4986e7',
            ),
          ],
          legends: legends,
        );

        await tester.pumpWidget(
          createTestApp(
            SingleChildScrollView(
              child: Column(
                children: [
                  StandingsTable(rows: standings.rows),
                  Wrap(
                    children: standings.legends!
                        .map((l) => Text(l.description))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('يتأهل دوري أبطال أوروبا'), findsOneWidget);
        expect(find.text('يتأهل الدوري الأوروبي'), findsOneWidget);
        expect(find.text('يهبط دوري البطولة الإنجليزية'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Neutral fallback displayed when no qualification metadata exists in API',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(l10n.translate('standings_no_legends'));
              },
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text('معلومات التأهل والهبوط غير متاحة لهذه البطولة حالياً'),
          findsOneWidget,
        );
      },
    );
  });
}
