import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('MatchEntity copyWith and equality work correctly', () {
    const match = MatchEntity(
      id: '123',
      team1: 'Liverpool',
      team2: 'Man City',
      score1: '1',
      score2: '1',
      status: 'Live',
    );

    final updated = match.copyWith(score1: '2');
    expect(updated.score1, '2');
    expect(updated.score2, '1');
    expect(updated.id, '123');
    expect(updated == match, isFalse);
  });

  testWidgets('Test arrow icon in RTL', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Icon(Icons.arrow_back_rounded, key: Key('back')),
          ],
        ),
      ),
    );

    // Because matchTextDirection is true and textDirection is RTL, Icon wraps in Transform with -1 scale
    final transformFinder = find.descendant(
      of: find.byKey(const Key('back')),
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsOneWidget);
    final Transform transform = tester.widget(transformFinder);
    expect(
        transform.transform.storage[0], -1.0); // Horizontal flip (scaleX = -1)
  });
}
