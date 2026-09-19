import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/websocket/websocket_event.dart';

void main() {
  group('LiveMatchUpdate Model Tests', () {
    test('LiveMatchUpdate parses json correctly', () {
      final json = {
        'id': '5868013',
        'league_title': 'LaLiga',
        'team_1': 'Real Madrid',
        'team_2': 'Barcelona',
        'score_1': '2',
        'score_2': '1',
        'minute': "75'",
        'status': 'Second Half',
        'event_type': 'goal',
        'player_name': 'Vinicius Jr',
      };

      final update = LiveMatchUpdate.fromJson(json);

      expect(update.matchId, '5868013');
      expect(update.leagueTitle, 'LaLiga');
      expect(update.team1, 'Real Madrid');
      expect(update.team2, 'Barcelona');
      expect(update.score1, '2');
      expect(update.score2, '1');
      expect(update.minute, "75'");
      expect(update.status, 'Second Half');
      expect(update.eventType, 'goal');
      expect(update.playerName, 'Vinicius Jr');
    });

    test('LiveMatchUpdate handles missing/null values safely', () {
      final update = LiveMatchUpdate.fromJson(const {});
      expect(update.matchId, isNull);
      expect(update.score1, isNull);
      expect(update.score2, isNull);
    });
  });
}
