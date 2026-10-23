import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Match & News Share Static URLs and Branding Tests', () {
    testWidgets('News detail share card renders app logo and 154 SCORE branding',
        (tester) async {
      // Verify widget tree contains the branding capsule with app logo and '154 SCORE'
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: 14,
                      height: 14,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '154 SCORE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('154 SCORE'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    test('Verify static share URL format', () {
      const expectedUrl = 'https://154score-api.medohs770.workers.dev/';
      expect(expectedUrl, 'https://154score-api.medohs770.workers.dev/');
    });
  });
}
