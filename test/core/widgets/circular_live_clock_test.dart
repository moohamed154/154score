import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/widgets/circular_live_clock.dart';

void main() {
  group('CircularLiveClock Extra Time & Refresh Tests', () {
    testWidgets(
      'Stoppage time displays actual elapsed extra time from minute (e.g. 94\' with extraTime 9)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: "94'",
                extraTime: '9',
                status: 'الشوط الثاني',
                period: '2nd_half',
                statusCode: 'LIVE',
              ),
            ),
          ),
        );

        // Main circle displays 90:00
        expect(find.text('90:00'), findsOneWidget);
        // Extra time displays +04:00 / 9, NOT +00:00 / 9!
        expect(find.text('+04:00 / 9'), findsOneWidget);
      },
    );

    testWidgets(
      'Preserves clock seconds when clock format is passed (e.g. 94:23 with extraTime 9)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: '94:23',
                extraTime: '9',
                status: 'الشوط الثاني',
                period: '2nd_half',
                statusCode: 'LIVE',
              ),
            ),
          ),
        );

        expect(find.text('90:00'), findsOneWidget);
        expect(find.text('+04:23 / 9'), findsOneWidget);
      },
    );

    testWidgets(
      'Does NOT reset to +00:00 when widget updates/refreshes in extra time',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: '94:23',
                extraTime: '9',
                status: 'الشوط الثاني',
                period: '2nd_half',
                statusCode: 'LIVE',
              ),
            ),
          ),
        );

        expect(find.text('+04:23 / 9'), findsOneWidget);

        // Simulate a refresh arriving with updated time 94:24
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: '94:24',
                extraTime: '9',
                status: 'الشوط الثاني',
                period: '2nd_half',
                statusCode: 'LIVE',
              ),
            ),
          ),
        );

        // Should advance to 94:24 (+04:24 / 9) and definitely NOT reset to +00:00
        expect(find.text('+04:24 / 9'), findsOneWidget);
        expect(find.text('+00:00 / 9'), findsNothing);
      },
    );

    testWidgets(
      'Suppresses residual extraTime in 2nd half regular time (e.g. minute 81 with residual extraTime 1)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: "81'",
                extraTime: '1',
                status: 'الشوط الثاني',
                period: '2nd_half',
                statusCode: 'LIVE',
              ),
            ),
          ),
        );

        // Should display 81:00, NOT 90:00, and NO extra time text!
        expect(find.text('81:00'), findsOneWidget);
        expect(find.text('+00:00 / 1'), findsNothing);
        expect(find.text('+01:00 / 1'), findsNothing);
      },
    );

    testWidgets(
      'Handles 1st half extra time correctly (e.g. minute 47 with extraTime 3)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: "47'",
                extraTime: '3',
                status: 'الشوط الأول',
                period: '1st_half',
                statusCode: 'LIVE',
              ),
            ),
          ),
        );

        expect(find.text('45:00'), findsOneWidget);
        expect(find.text('+02:00 / 3'), findsOneWidget);
      },
    );

    testWidgets('Parses compound minute format "90+4\'" correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularLiveClock(
              minute: "90+4'",
              extraTime: '6',
              status: 'الشوط الثاني',
              period: '2nd_half',
              statusCode: 'LIVE',
            ),
          ),
        ),
      );

      expect(find.text('90:00'), findsOneWidget);
      expect(find.text('+04:00 / 6'), findsOneWidget);
    });

    testWidgets(
      'Calculates elapsed time from timestamp when minute is null on app restart (never resets to 00:00)',
      (tester) async {
        final nowUtc = DateTime.now().toUtc();
        // Kickoff 20 minutes ago
        final kickoffTs = (nowUtc.millisecondsSinceEpoch ~/ 1000) - (20 * 60 + 15);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: null,
                status: 'الشوط الأول',
                period: '1st_half',
                statusCode: 'LIVE',
                timestamp: kickoffTs,
              ),
            ),
          ),
        );

        // It should display 20:15, NOT 00:00!
        expect(find.text('20:15'), findsOneWidget);
        expect(find.text('00:00'), findsNothing);
      },
    );

    testWidgets(
      'Calculates 2nd half elapsed time from timestamp when minute is null',
      (tester) async {
        final nowUtc = DateTime.now().toUtc();
        // Match kicked off 75 minutes ago (45m 1st half + 15m HT break + 15m 2nd half)
        final kickoffTs = (nowUtc.millisecondsSinceEpoch ~/ 1000) - (75 * 60 + 30);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CircularLiveClock(
                minute: null,
                status: 'الشوط الثاني',
                period: '2nd_half',
                statusCode: 'LIVE',
                timestamp: kickoffTs,
              ),
            ),
          ),
        );

        // It should display 60:30 (45 + 15m 30s), NOT 45:00 or 00:00!
        expect(find.text('60:30'), findsOneWidget);
        expect(find.text('00:00'), findsNothing);
      },
    );
  });
}
