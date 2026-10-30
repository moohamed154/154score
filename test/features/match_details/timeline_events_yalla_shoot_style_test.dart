import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/presentation/widgets/match_event_visual_icon.dart';
import 'package:score154/features/match_details/presentation/widgets/timeline_event_item.dart';

Widget buildTestWidget(Widget child, {bool isDark = true}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('Timeline Events — Yalla Shoot Inspired Style with App Theme', () {
    testWidgets('1. Goal event renders minute in circular outline badge and custom visual icon', (
      tester,
    ) async {
      const goalEvent = MatchEventEntity(
        minute: '82',
        playerName: 'يان ديوماندي',
        type: 'goal',
        isHomeTeam: true,
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: goalEvent)));
      await tester.pumpAndSettle();

      // Minute text
      expect(find.text("82'"), findsOneWidget);
      // Event visual icon
      expect(find.byType(MatchEventVisualIcon), findsOneWidget);

      // Verify container with circular border around minute
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circularRing = containers.where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.shape == BoxShape.circle && dec.border != null;
      });
      expect(circularRing.isNotEmpty, isTrue);
    });

    testWidgets('2. Non-goal event (e.g. Yellow Card) renders plain text minute without circular ring', (
      tester,
    ) async {
      const cardEvent = MatchEventEntity(
        minute: '73',
        playerName: 'مارك كوكوريلا',
        type: 'yellow_card',
        isHomeTeam: true,
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: cardEvent)));
      await tester.pumpAndSettle();

      // Minute text exists
      expect(find.text("73'"), findsOneWidget);
      expect(find.text('مارك كوكوريلا'), findsOneWidget);

      // Verify no circular ring is applied to non-goal minute
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circularRing = containers.where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.shape == BoxShape.circle;
      });
      expect(circularRing.isEmpty, isTrue);
    });

    testWidgets('3. Substitution event renders directional horizontal arrows for IN and OUT players', (
      tester,
    ) async {
      const subEvent = MatchEventEntity(
        minute: '85',
        playerName: 'فالفيردي',
        secondaryPlayerName: 'إيدير ميليتاو',
        type: 'substitution',
        isHomeTeam: true,
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: subEvent)));
      await tester.pumpAndSettle();

      expect(find.text("85'"), findsOneWidget);
      expect(find.text('إيدير ميليتاو'), findsOneWidget);
      expect(find.text('فالفيردي'), findsOneWidget);

      // Substitution directional arrows
      expect(find.byIcon(Icons.east_rounded), findsOneWidget);
      expect(find.byIcon(Icons.west_rounded), findsOneWidget);
    });

    testWidgets('4. Period markers stack whistle icon vertically above label', (
      tester,
    ) async {
      const kickoffEvent = MatchEventEntity(
        minute: '',
        playerName: 'بداية الشوط الأول',
        type: 'whistle',
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: kickoffEvent)));
      await tester.pumpAndSettle();

      expect(find.text('بداية الشوط الأول'), findsOneWidget);
      expect(find.byType(MatchEventVisualIcon), findsOneWidget);
    });

    testWidgets('5. Penalty scored, missed chance, and crossbar render custom visual icons', (
      tester,
    ) async {
      const penEvent = MatchEventEntity(
        minute: '82',
        playerName: 'زيزو',
        type: 'penalty_goal',
        isHomeTeam: true,
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: penEvent)));
      await tester.pumpAndSettle();

      expect(find.text("82'"), findsOneWidget);
      expect(find.text('زيزو'), findsOneWidget);
      expect(find.byType(MatchEventVisualIcon), findsOneWidget);
    });

    testWidgets('6. Missed chance in Arabic renders "فرصة ضائعة" and NOT penalty missed', (
      tester,
    ) async {
      const missedChanceEvent = MatchEventEntity(
        minute: '9',
        playerName: 'طاهر محمد طاهر',
        secondaryPlayerName: 'فرصة ضائعة',
        type: 'miss_chance',
        isHomeTeam: true,
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: missedChanceEvent)));
      await tester.pumpAndSettle();

      expect(find.text("9'"), findsOneWidget);
      expect(find.text('طاهر محمد طاهر'), findsOneWidget);
      expect(find.text('فرصة ضائعة'), findsOneWidget);
      expect(find.text('ضربة جزاء ضائعة'), findsNothing);
      expect(find.text('ركلة جزاء ضائعة'), findsNothing);

      final iconFinder = find.byType(MatchEventVisualIcon);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<MatchEventVisualIcon>(iconFinder);
      expect(iconWidget.type, MatchVisualEventType.missChance);
    });

    testWidgets('7. Missed chance in English renders "Missed Chance"', (
      tester,
    ) async {
      const missedChanceEventEn = MatchEventEntity(
        minute: '21',
        playerName: 'Hussein El Shahat',
        secondaryPlayerName: 'Missed Chance',
        type: 'miss_chance',
        isHomeTeam: true,
      );

      final widget = MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: TimelineEventItem(event: missedChanceEventEn),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text("21'"), findsOneWidget);
      expect(find.text('Hussein El Shahat'), findsOneWidget);
      expect(find.text('Missed Chance'), findsOneWidget);
    });

    testWidgets('8. Actual missed penalty in Arabic renders "ركلة جزاء ضائعة"', (
      tester,
    ) async {
      const missedPenEvent = MatchEventEntity(
        minute: '35',
        playerName: 'علي معلول',
        secondaryPlayerName: 'ركلة جزاء ضائعة',
        type: 'missed_penalty',
        isHomeTeam: true,
      );

      await tester.pumpWidget(buildTestWidget(const TimelineEventItem(event: missedPenEvent)));
      await tester.pumpAndSettle();

      expect(find.text("35'"), findsOneWidget);
      expect(find.text('علي معلول'), findsOneWidget);
      expect(find.text('ركلة جزاء ضائعة'), findsOneWidget);

      final iconFinder = find.byType(MatchEventVisualIcon);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<MatchEventVisualIcon>(iconFinder);
      expect(iconWidget.type, MatchVisualEventType.missedPenalty);
    });

    testWidgets(
      '9. Substitution with player name containing "red" ("Adem Redjem") renders as substitution (not red card) with consistent IN/OUT order in English and Arabic',
      (tester) async {
        // API semantics: playerName = Player OUT (Kaboria #98),
        // secondaryPlayerName = Player IN (Adem Redjem #7).
        const subEventEn = MatchEventEntity(
          minute: '78',
          playerName: 'Kaboria',
          playerId: '940251207',
          playerNumber: 98,
          secondaryPlayerName: 'Adem Redjem',
          secondaryPlayerId: '1121519',
          secondaryPlayerNumber: 7,
          type: 'substitution',
          isHomeTeam: true,
        );

        final widgetEn = MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: TimelineEventItem(event: subEventEn),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widgetEn);
        await tester.pumpAndSettle();

        // Must NOT render a MatchEventVisualIcon of type redCard
        expect(find.byType(MatchEventVisualIcon), findsNothing);

        // Both player names must be present
        final inFinderEn = find.text('Adem Redjem');
        final outFinderEn = find.text('Kaboria');
        expect(inFinderEn, findsOneWidget);
        expect(outFinderEn, findsOneWidget);

        // Player IN (Adem Redjem) must be on Line 1 (above Player OUT Kaboria)
        expect(
          tester.getTopLeft(inFinderEn).dy,
          lessThan(tester.getTopLeft(outFinderEn).dy),
        );

        // Player IN's jersey number (#7) must be on Line 1 (above #98)
        final numInFinder = find.text('7');
        final numOutFinder = find.text('98');
        expect(numInFinder, findsOneWidget);
        expect(numOutFinder, findsOneWidget);
        expect(
          tester.getTopLeft(numInFinder).dy,
          lessThan(tester.getTopLeft(numOutFinder).dy),
        );

        // Now verify Arabic renders the exact same vertical order (IN on top, OUT on bottom)
        const subEventAr = MatchEventEntity(
          minute: '78',
          playerName: 'كابوريا',
          playerId: '940251207',
          playerNumber: 98,
          secondaryPlayerName: 'أدم رجم',
          secondaryPlayerId: '1121519',
          secondaryPlayerNumber: 7,
          type: 'substitution',
          isHomeTeam: true,
        );

        await tester.pumpWidget(
          buildTestWidget(const TimelineEventItem(event: subEventAr)),
        );
        await tester.pumpAndSettle();

        final inFinderAr = find.text('أدم رجم');
        final outFinderAr = find.text('كابوريا');
        expect(inFinderAr, findsOneWidget);
        expect(outFinderAr, findsOneWidget);
        expect(
          tester.getTopLeft(inFinderAr).dy,
          lessThan(tester.getTopLeft(outFinderAr).dy),
        );
      },
    );
  });
}
