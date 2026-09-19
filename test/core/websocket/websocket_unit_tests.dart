import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/realtime_merge_engine.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/transfers/domain/entities/transfer_entity.dart';

void main() {
  group('WebSocket Event Models & Parsing', () {
    test('LiveMatchUpdate parses full JSON with timestamps and versions', () {
      final json = {
        'id': '5868013',
        'league_title': 'LaLiga',
        'team_1': 'Real Madrid',
        'team_2': 'Barcelona',
        'score_1': '2',
        'score_2': '1',
        'minute': "75'",
        'status': 'Live',
        'event_type': 'goal',
        'player_name': 'Vinicius Jr',
        'timestamp': 1700000000,
        'sequence': 12,
      };

      final update = LiveMatchUpdate.fromJson(json);

      expect(update.matchId, '5868013');
      expect(update.leagueTitle, 'LaLiga');
      expect(update.team1, 'Real Madrid');
      expect(update.team2, 'Barcelona');
      expect(update.score1, '2');
      expect(update.score2, '1');
      expect(update.minute, "75'");
      expect(update.status, 'Live');
      expect(update.eventType, 'goal');
      expect(update.playerName, 'Vinicius Jr');
      expect(update.timestamp, 1700000000);
      expect(update.sequence, 12);
      expect(update.fingerprint, contains('5868013'));
    });

    test('TransferUpdate parses JSON correctly', () {
      final json = {
        'id': 'tr_991',
        'player_name': 'Kylian Mbappe',
        'position': 'Forward',
        'from_team_name': 'PSG',
        'to_team_name': 'Real Madrid',
        'fee': 'Free Transfer',
        'date': '2026-07-01',
      };

      final update = TransferUpdate.fromJson(json);

      expect(update.transferId, 'tr_991');
      expect(update.playerName, 'Kylian Mbappe');
      expect(update.playerPosition, 'Forward');
      expect(update.fromTeamName, 'PSG');
      expect(update.toTeamName, 'Real Madrid');
      expect(update.transferFee, 'Free Transfer');
      expect(update.transferDate, '2026-07-01');
      expect(update.fingerprint, 'tr_991');
    });

    test('MatchDetailRealtimeUpdate parses JSON correctly', () {
      final json = {
        'id': '5868020',
        'home_score': '3',
        'away_score': '2',
        'status': 'Second Half',
        'minute': "88'",
        'type': 'goal',
        'player_name': 'Mohamed Salah',
        'assist': 'Alexander-Arnold',
        'is_home': true,
      };

      final update = MatchDetailRealtimeUpdate.fromJson(json);

      expect(update.matchId, '5868020');
      expect(update.score1, '3');
      expect(update.score2, '2');
      expect(update.status, 'Second Half');
      expect(update.minute, "88'");
      expect(update.eventType, 'goal');
      expect(update.eventPlayer, 'Mohamed Salah');
      expect(update.eventAssist, 'Alexander-Arnold');
      expect(update.isHomeTeam, isTrue);
      expect(update.eventFingerprint, contains('5868020'));
    });

    test('WebSocketConnectionHealth tracks metrics and state accurately', () {
      const health = WebSocketConnectionHealth(
        state: SocketConnectionState.connected,
        reconnectAttempts: 2,
        totalEventsReceived: 45,
        duplicateEventsSuppressed: 10,
        activeSubscriptions: {'live_matches_ar', 'match:5868020'},
      );

      expect(health.state, SocketConnectionState.connected);
      expect(health.reconnectAttempts, 2);
      expect(health.totalEventsReceived, 45);
      expect(health.duplicateEventsSuppressed, 10);
      expect(health.activeSubscriptions.length, 2);
    });
  });

  group('RealtimeMergeEngine Tests', () {
    const existingMatch = MatchEntity(
      id: '5868013',
      team1: 'Real Madrid',
      team2: 'Barcelona',
      team1Logo: 'https://logo1.png',
      team2Logo: 'https://logo2.png',
      score1: '1',
      score2: '1',
      status: 'Live',
      minute: "60'",
      leagueTitle: 'LaLiga',
    );

    const leagueGroup = LeagueGroupEntity(
      leagueTitle: 'LaLiga',
      matches: [existingMatch],
    );

    test(
      'mergeMatchesWithRealtime updates scores while preserving metadata',
      () {
        final update = LiveMatchUpdate.fromJson(const {
          'id': '5868013',
          'score_1': '2',
          'score_2': '1',
          'minute': "75'",
          'status': 'Second Half',
        });

        final result = RealtimeMergeEngine.mergeMatchesWithRealtime(
          existingLeagues: [leagueGroup],
          update: update,
        );

        expect(result.isUpdated, isTrue);
        expect(result.data.first.matches.first.score1, '2');
        expect(result.data.first.matches.first.score2, '1');
        expect(result.data.first.matches.first.minute, "75'");
        expect(result.data.first.matches.first.team1Logo, 'https://logo1.png');
        expect(result.data.first.matches.first.team1, 'Real Madrid');
      },
    );

    test(
      'mergeMatchesWithRealtime returns isUpdated false for non-matching ID',
      () {
        final update = LiveMatchUpdate.fromJson(const {
          'id': '9999999',
          'score_1': '5',
          'score_2': '0',
        });

        final result = RealtimeMergeEngine.mergeMatchesWithRealtime(
          existingLeagues: [leagueGroup],
          update: update,
        );

        expect(result.isUpdated, isFalse);
        expect(result.data.first.matches.first.score1, '1');
      },
    );

    test(
      'mergeMatchDetailsEvents appends new event and suppresses duplicates',
      () {
        const existingEvents = [
          MatchEventEntity(
            minute: "15'",
            playerName: 'Player A',
            type: 'goal',
            isHomeTeam: true,
          ),
        ];

        final update = MatchDetailRealtimeUpdate.fromJson(const {
          'id': '5868013',
          'minute': "40'",
          'type': 'goal',
          'player_name': 'Player B',
          'is_home': false,
        });

        final res1 = RealtimeMergeEngine.mergeMatchDetailsEvents(
          existingEvents: existingEvents,
          update: update,
        );

        expect(res1.isUpdated, isTrue);
        expect(res1.data.length, 2);
        expect(res1.data.last.playerName, 'Player B');

        // Duplicate submission
        final res2 = RealtimeMergeEngine.mergeMatchDetailsEvents(
          existingEvents: res1.data,
          update: update,
        );

        expect(res2.isUpdated, isFalse);
        expect(res2.data.length, 2);
      },
    );

    test(
      'mergeTransfersWithRealtime prepends transfer and suppresses duplicate',
      () {
        const existing = [
          TransferEntity(
            id: '1',
            playerName: 'Existing Player',
            fromTeamName: 'Club A',
            toTeamName: 'Club B',
          ),
        ];

        final update = TransferUpdate.fromJson(const {
          'id': '2',
          'player_name': 'New Star',
          'from_team_name': 'Club X',
          'to_team_name': 'Club Y',
          'fee': '€50M',
        });

        final res1 = RealtimeMergeEngine.mergeTransfersWithRealtime(
          existingTransfers: existing,
          update: update,
        );

        expect(res1.isUpdated, isTrue);
        expect(res1.data.length, 2);
        expect(res1.data.first.playerName, 'New Star');

        // Duplicate submission
        final res2 = RealtimeMergeEngine.mergeTransfersWithRealtime(
          existingTransfers: res1.data,
          update: update,
        );

        expect(res2.isUpdated, isFalse);
        expect(res2.data.length, 2);
      },
    );
  });
}
