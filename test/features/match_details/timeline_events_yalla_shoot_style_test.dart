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
  });
}
