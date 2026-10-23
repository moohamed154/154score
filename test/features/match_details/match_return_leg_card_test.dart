import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/match_return_leg_card.dart';

void main() {
  Widget buildWidget(MatchReturnLegEntity returnLeg) {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      home: Scaffold(
        body: MatchReturnLegCard(
          returnLeg: returnLeg,
          isDark: true,
          isArabic: false,
        ),
      ),
    );
  }

  group('MatchReturnLegCard Tests', () {
    testWidgets(
        'does NOT display penalties when string contains [object Object]',
        (tester) async {
      const entity = MatchReturnLegEntity(
        matchId: '123',
        homeTeam: 'Red Arrows',
        awayTeam: 'Kaizer Chiefs',
        homeScores: 1,
        awayScores: 0,
        aggResult: '1 - 1',
        penalties:
            '[object Object],[object Object],[object Object],[object Object],[object Object] - [object Object],[object Object],[object Object],[object Object],[object Object]',
      );

      await tester.pumpWidget(buildWidget(entity));
      await tester.pumpAndSettle();

      expect(find.text('Red Arrows'), findsOneWidget);
      expect(find.text('Kaizer Chiefs'), findsOneWidget);
      expect(find.text('Agg: 1 - 1'), findsOneWidget);
      expect(find.textContaining('[object'), findsNothing);
      expect(find.textContaining('Penalties:'), findsNothing);
    });

    testWidgets(
        'does NOT display aggResult when string contains [object Object]',
        (tester) async {
      const entity = MatchReturnLegEntity(
        matchId: '123',
        homeTeam: 'Red Arrows',
        awayTeam: 'Kaizer Chiefs',
        homeScores: 1,
        awayScores: 0,
        aggResult: '[object Object]',
      );

      await tester.pumpWidget(buildWidget(entity));
      await tester.pumpAndSettle();

      expect(find.textContaining('[object'), findsNothing);
      expect(find.textContaining('Agg:'), findsNothing);
    });

    testWidgets('displays valid penalties when clean numeric score',
        (tester) async {
      const entity = MatchReturnLegEntity(
        matchId: '123',
        homeTeam: 'Red Arrows',
        awayTeam: 'Kaizer Chiefs',
        homeScores: 1,
        awayScores: 0,
        aggResult: '1 - 1',
        penalties: '2 - 3',
      );

      await tester.pumpWidget(buildWidget(entity));
      await tester.pumpAndSettle();

      expect(find.text('Penalties: 2 - 3'), findsOneWidget);
    });
  });
}
