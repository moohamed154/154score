import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:score154/core/widgets/penalty_shootout_widget.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/penalty_shootout_events_card.dart';

void main() {
  group('PenaltyShootoutWidget Tests', () {
    testWidgets('Renders card banner style with soccer balls and penalty score',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PenaltyShootoutWidget(
              penaltyScore1: '3',
              penaltyScore2: '2',
              attempts1: [true, false, false, true, true],
              attempts2: [false, true, false, false, true],
              isCardBanner: true,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'Penalty Kicks' || w.data == 'ركلات الترجيح'),
        ),
        findsOneWidget,
      );
      expect(find.text('3 - 2'), findsOneWidget);
      // 5 home balls + 5 away balls = 10 soccer ball icons
      expect(find.byIcon(Icons.sports_soccer_rounded), findsNWidgets(10));
    });

    testWidgets('Renders compact style correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PenaltyShootoutWidget(
              penaltyScore1: '4',
              penaltyScore2: '3',
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('4 - 3'), findsOneWidget);
    });
  });

  group('PenaltyShootoutEventsCard Tests', () {
    testWidgets('Renders Yalla Shoot style shootout box in Events tab',
        (tester) async {
      const detail = PenaltyShootoutDetailEntity(
        homeScore: '3',
        awayScore: '2',
        homeKicks: [
          PenaltyKickItemEntity(
            order: 1,
            playerName: 'Al-Hamdan',
            isGoal: true,
          ),
          PenaltyKickItemEntity(
            order: 2,
            playerName: 'Kanno',
            isGoal: true,
          ),
          PenaltyKickItemEntity(
            order: 3,
            playerName: 'Tambakti',
            isGoal: false,
          ),
        ],
        awayKicks: [
          PenaltyKickItemEntity(
            order: 1,
            playerName: 'Almoez',
            isGoal: false,
          ),
          PenaltyKickItemEntity(
            order: 2,
            playerName: 'Edmilson',
            isGoal: true,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PenaltyShootoutEventsCard(
              penaltiesDetail: detail,
              penaltyScore1: '3',
              penaltyScore2: '2',
              fullTimeScore: '0 - 0',
              isDark: true,
              isArabic: false,
            ),
          ),
        ),
      );

      expect(find.text('Full-Time'), findsOneWidget);
      expect(find.text('3 - 2'), findsOneWidget);
      expect(find.text('1- Al-Hamdan (Goal)'), findsOneWidget);
      expect(find.text('2- Kanno (Goal)'), findsOneWidget);
      expect(find.text('3- Tambakti (Missed)'), findsOneWidget);
      expect(find.text('Almoez (Missed) -1'), findsOneWidget);
      expect(find.text('Edmilson (Goal) -2'), findsOneWidget);
      expect(find.text('0 - 0'), findsOneWidget);
      expect(find.text('Penalties'), findsOneWidget);
    });
  });
}
