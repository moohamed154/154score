import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';

void main() {
  testWidgets('MatchCard renders teams and score correctly', (
    WidgetTester tester,
  ) async {
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
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: [Locale('en')],
        home: Scaffold(body: MatchCard(match: match)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Real Madrid'), findsOneWidget);
    expect(find.text('Barcelona'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('FT'), findsOneWidget);
  });

  testWidgets(
    'MatchCard renders live state with circular clock and minute correctly',
    (WidgetTester tester) async {
      const match = MatchEntity(
        id: '2',
        team1: 'Al-Faisaly',
        team2: 'Al Ittihad',
        score1: '0',
        score2: '3',
        minute: '85',
        status: 'Live',
      );

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(body: MatchCard(match: match)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Al-Faisaly'), findsOneWidget);
      expect(find.text('Al Ittihad'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('85:00'), findsOneWidget);
    },
  );

  testWidgets('MatchCard renders upcoming state with time capsule correctly', (
    WidgetTester tester,
  ) async {
    const match = MatchEntity(
      id: '3',
      team1: 'Al-Ahli',
      team2: 'Al Hazem',
      time: '09:00 PM',
      status: 'Upcoming',
      date: '2030-01-01',
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: [Locale('en')],
        home: Scaffold(body: MatchCard(match: match)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Al-Ahli'), findsOneWidget);
    expect(find.text('Al Hazem'), findsOneWidget);
    expect(find.text('09:00 PM'), findsOneWidget);
  });

  testWidgets('MatchCard renders extra time under match time correctly', (
    WidgetTester tester,
  ) async {
    const match = MatchEntity(
      id: '4',
      team1: 'Coritiba',
      team2: 'Paranaense',
      score1: '0',
      score2: '2',
      status: 'الشوط الثاني',
      statusCode: 'LIVE',
      minute: '90',
      period: '2nd_half',
      extraTime: '+04:36 / 12',
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: [Locale('en')],
        home: Scaffold(body: MatchCard(match: match)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('90:00'), findsOneWidget);
    expect(find.text('+04:36 / 12'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
