import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/theme/app_theme.dart';
import 'package:ysscores/core/widgets/match_score_widget.dart';
import 'package:ysscores/core/widgets/penalty_shootout_widget.dart';
import 'package:ysscores/features/matches/domain/entities/match_entity.dart';
import 'package:ysscores/features/matches/presentation/widgets/match_card.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';
import 'package:ysscores/features/match_details/presentation/widgets/match_header_banner.dart';
import 'package:ysscores/features/match_details/presentation/widgets/stat_comparison_bar.dart';
import 'package:ysscores/features/match_details/presentation/widgets/timeline_event_item.dart';
import 'package:ysscores/features/standings/domain/entities/standings_entity.dart';
import 'package:ysscores/features/standings/presentation/widgets/standings_table.dart';

Widget createTestableWidget(
  Widget child, {
  double width = 360.0,
  double height = 800.0,
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('Deep Match Experience & Score Engine Tests (V4.3.1)', () {
    testWidgets('Normal Score, Draw & Half-Time rendering', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const MatchScoreWidget(
            score1: '2',
            score2: '1',
            halfTimeScore1: '1',
            halfTimeScore2: '0',
            isLarge: true,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('(الشوط الأول: 1 - 0)'), findsOneWidget);
    });

    testWidgets('Penalty Shootout separated from Match Score', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const MatchScoreWidget(
            score1: '1',
            score2: '1',
            penaltyScore1: '4',
            penaltyScore2: '3',
            isLarge: true,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('4 : 3'), findsOneWidget);
      expect(find.text('ركلات الترجيح: '), findsOneWidget);
    });

    testWidgets('PenaltyShootoutWidget compact mode for MatchCard', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          const PenaltyShootoutWidget(
            penaltyScore1: '5',
            penaltyScore2: '4',
            isCompact: true,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('5 - 4'), findsOneWidget);
    });

    testWidgets('MatchCard with Penalty Shootout renders on 320px screen', (
      tester,
    ) async {
      const penaltyMatch = MatchEntity(
        id: '9999',
        team1: 'ريال مدريد الملكي',
        team2: 'أتلتيكو مدريد الثاني',
        score1: '1',
        score2: '1',
        penaltyScore1: '5',
        penaltyScore2: '3',
        status: 'انتهت بركلات الترجيح',
      );

      await tester.pumpWidget(
        createTestableWidget(
          const MatchCard(match: penaltyMatch),
          width: 320.0,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('5 - 4'), findsNothing);
      expect(find.text('5 - 3'), findsOneWidget);
    });

    testWidgets(
      'MatchHeaderBanner with penalties & extra time on 320px screen',
      (tester) async {
        const match = MatchEntity(
          id: '1234',
          team1: 'الأهلي المصري القاهري',
          team2: 'الزمالك المصري الرياضي',
          score1: '2',
          score2: '2',
          penaltyScore1: '4',
          penaltyScore2: '3',
          halfTimeScore1: '1',
          halfTimeScore2: '1',
          status: 'انتهت',
        );

        await tester.pumpWidget(
          createTestableWidget(
            const MatchHeaderBanner(
              match: match,
              penaltyScore1: '4',
              penaltyScore2: '3',
            ),
            width: 320.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('4 - 3'), findsOneWidget);
      },
    );

    testWidgets(
      'Match Events Timeline handles all event types without errors',
      (tester) async {
        const events = [
          MatchEventEntity(
            playerName: 'كيليان مبابي',
            minute: '12',
            type: 'goal',
            isHomeTeam: true,
            score: '1 - 0',
          ),
          MatchEventEntity(
            playerName: 'سيرجيو راموس',
            minute: '34',
            type: 'own_goal',
            isHomeTeam: false,
          ),
          MatchEventEntity(
            playerName: 'لوكا مودريتش',
            minute: '55',
            type: 'penalty_goal',
            isHomeTeam: true,
            score: '2 - 1',
          ),
          MatchEventEntity(
            playerName: 'أنطوان غريزمان',
            minute: '67',
            type: 'missed_penalty',
            isHomeTeam: false,
          ),
          MatchEventEntity(
            playerName: 'كاسيميرو',
            minute: '72',
            type: 'yellow_card',
            isHomeTeam: true,
          ),
          MatchEventEntity(
            playerName: 'كاسيميرو',
            minute: '85',
            type: 'second_yellow',
            isHomeTeam: true,
          ),
          MatchEventEntity(
            playerName: 'رودريغو (دخول) / فينيسيوس (خروج)',
            minute: '88',
            type: 'substitution',
            isHomeTeam: true,
          ),
          MatchEventEntity(
            playerName: 'قرار الفار: إلغاء هدف بداعي التسلل',
            minute: '90+3',
            type: 'var',
            isHomeTeam: false,
          ),
          MatchEventEntity(
            playerName: 'نهاية الشوط الأول',
            minute: '45',
            type: 'half-time',
          ),
        ];

        await tester.pumpWidget(
          createTestableWidget(
            ListView(
              children: events.map((e) => TimelineEventItem(event: e)).toList(),
            ),
            width: 320.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Match Statistics handles zero values, percentages, and NaN safe flex',
      (tester) async {
        const stats = [
          MatchStatItemEntity(
            title: 'الاستحواذ',
            homeValue: '55%',
            awayValue: '45%',
            homePercentage: 0.55,
            category: 'عام',
          ),
          MatchStatItemEntity(
            title: 'التسديدات على المرمى',
            homeValue: '0',
            awayValue: '0',
            homePercentage: 0.5,
            category: 'الهجوم',
          ),
          MatchStatItemEntity(
            title: 'البطاقات الحمراء',
            homeValue: '1',
            awayValue: '0',
            homePercentage: 1.0,
            category: 'الانضباط',
          ),
        ];

        await tester.pumpWidget(
          createTestableWidget(
            ListView(
              children: stats.map((s) => StatComparisonBar(stat: s)).toList(),
            ),
            width: 320.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('StandingsTable handles small screen and dense row counts', (
      tester,
    ) async {
      final rows = List.generate(
        10,
        (i) => StandingRowEntity(
          position: i + 1,
          teamName: 'النادي الرياضي رقم ${i + 1}',
          played: 20,
          wins: 10,
          draws: 5,
          losses: 5,
          goalsFor: 30,
          goalsAgainst: 20,
          goalDiff: 10,
          points: 35,
          groupName: 'Group A',
        ),
      );

      await tester.pumpWidget(
        createTestableWidget(StandingsTable(rows: rows), width: 320.0),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
