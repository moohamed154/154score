import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/features/matches/domain/entities/match_entity.dart';
import 'package:ysscores/features/matches/presentation/widgets/match_card.dart';

void main() {
  testWidgets('MatchCard renders teams and score correctly', (WidgetTester tester) async {
    const match = MatchEntity(
      id: '1',
      team1: 'Real Madrid',
      team2: 'Barcelona',
      score1: '3',
      score2: '1',
      status: 'Ended',
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: Scaffold(
          body: MatchCard(match: match),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Real Madrid'), findsOneWidget);
    expect(find.text('Barcelona'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
  });
}
