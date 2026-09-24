import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/lineup/pitch_player_node.dart';

Widget buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
  double width = 390,
  double height = 844,
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
      data: MediaQueryData(size: Size(width, height)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Lineup Player Modal Match Contributions Tests', () {
    testWidgets(
      'renders player modal with match contributions (goals, assists, motm, sub)',
      (tester) async {
        const player = LineupPlayerEntity(
          playerId: '711',
          name: 'رافينيا',
          number: 11,
          position: 'LW',
          detailedPosition: 'LW',
          rating: '9.7',
          isCaptain: true,
          isStarter: true,
          isManOfMatch: true,
          goals: 3,
          assists: 1,
          yellowCards: 1,
          substituteOut: true,
          substituteTime: 85,
          subbedForName: 'غافي',
        );

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showLineupPlayerModal(context, player),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open the modal
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Verify Header details
        expect(find.text('رافينيا'), findsOneWidget);
        expect(find.text('#11'), findsOneWidget);
        expect(find.text('LW'), findsOneWidget);

        // Verify Key attributes
        expect(find.text('9.7'), findsOneWidget);
        expect(find.text('أساسي'), findsOneWidget);

        // Verify Match Contributions section
        expect(find.text('ما قدمه اللاعب في المباراة'), findsOneWidget);
        expect(find.textContaining('3 أهداف'), findsOneWidget);
        expect(find.textContaining('صناعة هدف'), findsOneWidget);
        expect(find.textContaining('بطاقة صفراء'), findsOneWidget);
        expect(find.textContaining('تم استبداله'), findsOneWidget);
        expect(find.textContaining('غافي'), findsOneWidget);

        // Verify Navigation button
        expect(find.text('الملف الشخصي للاعب'), findsOneWidget);
      },
    );

    testWidgets(
      'renders player modal for clean player with no cards or events gracefully',
      (tester) async {
        const cleanPlayer = LineupPlayerEntity(
          playerId: '8',
          name: 'بيدري',
          number: 8,
          position: 'CM',
          rating: '7.3',
          isCaptain: false,
          isStarter: true,
        );

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showLineupPlayerModal(context, cleanPlayer),
                  child: const Text('Open Clean Modal'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Clean Modal'));
        await tester.pumpAndSettle();

        expect(find.text('بيدري'), findsOneWidget);
        expect(find.text('#8'), findsOneWidget);
        expect(find.text('7.3'), findsOneWidget);
        expect(
          find.text('شارك كأساسي في المباراة دون أحداث مسجلة'),
          findsOneWidget,
        );
        expect(find.text('الملف الشخصي للاعب'), findsOneWidget);
      },
    );
  });
}
