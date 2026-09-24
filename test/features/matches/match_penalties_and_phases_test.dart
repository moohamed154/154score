import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/match_status_helper.dart';
import 'package:score154/core/utils/realtime_merge_engine.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/widgets/penalty_shootout_widget.dart';
import 'package:score154/features/matches/data/models/match_dto.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/live_match_card.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';

void main() {
  group('MatchStatusHelper - Phases & Status Codes', () {
    test('Correctly maps half-time break and extra-time break', () {
      expect(
        MatchStatusHelper.parseStatus(
          'استراحة',
          statusCode: 'HALFTIME',
          period: 'halftime',
        ),
        equals(MatchPhase.halfTime),
      );
      expect(
        MatchStatusHelper.parseStatus(
          'استراحة',
          statusCode: 'BREAK',
          period: 'break',
        ),
        equals(MatchPhase.halfTime),
      );
      expect(
        MatchStatusHelper.parseStatus(
          'استراحة إضافي',
          statusCode: 'HALFTIME',
          period: 'extra_break',
        ),
        equals(MatchPhase.halfTime),
      );
    });

    test('Correctly maps 1st Extra, 2nd Extra, and Penalties', () {
      expect(
        MatchStatusHelper.parseStatus(
          'الإضافي الأول',
          statusCode: 'EXTRA_TIME',
          period: '1st_extra',
        ),
        equals(MatchPhase.extraTime),
      );
      expect(
        MatchStatusHelper.parseStatus(
          'الإضافي الثاني',
          statusCode: 'EXTRA_TIME',
          period: '2nd_extra',
        ),
        equals(MatchPhase.extraTime),
      );
      expect(
        MatchStatusHelper.parseStatus(
          'ركلات الترجيح',
          statusCode: 'PENALTIES',
          period: 'penalties',
        ),
        equals(MatchPhase.penalties),
      );
    });
  });

  group('MatchDto & LiveMatchUpdate - Penalty Parsing', () {
    test('MatchDto parses penalty scores from object or direct fields', () {
      final json = {
        'match_id': '5406269',
        'team_1': 'Team A',
        'team_2': 'Team B',
        'score_1': '1',
        'score_2': '1',
        'status': 'انتهت',
        'status_code': 'FINISHED',
        'penalty_score_1': '4',
        'penalty_score_2': '5',
        'penalties': {'home': 4, 'away': 5},
      };

      final dto = MatchDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.hasPenalties, isTrue);
      expect(entity.penaltyScore1, equals('4'));
      expect(entity.penaltyScore2, equals('5'));
    });

    test('LiveMatchUpdate parses penalty scores and updates fingerprint', () {
      final json = {
        'match_id': '5406269',
        'team_1': 'Team A',
        'team_2': 'Team B',
        'score_1': '1',
        'score_2': '1',
        'status': 'ركلات الترجيح',
        'status_code': 'PENALTIES',
        'penalty_score_1': '3',
        'penalty_score_2': '2',
      };

      final update = LiveMatchUpdate.fromJson(json);
      expect(update.penaltyScore1, equals('3'));
      expect(update.penaltyScore2, equals('2'));
      expect(update.fingerprint, contains('3'));
      expect(update.fingerprint, contains('2'));
    });

    test('RealtimeMergeEngine merges penalty scores into MatchEntity', () {
      const initialMatch = MatchEntity(
        id: '100',
        team1: 'Home FC',
        team2: 'Away FC',
        score1: '2',
        score2: '2',
        status: 'الإضافي الثاني',
        statusCode: 'EXTRA_TIME',
      );

      const league = LeagueGroupEntity(
        leagueTitle: 'Champions League',
        matches: [initialMatch],
      );

      const update = LiveMatchUpdate(
        matchId: '100',
        score1: '2',
        score2: '2',
        penaltyScore1: '4',
        penaltyScore2: '3',
        status: 'ركلات الترجيح',
        statusCode: 'PENALTIES',
      );

      final result = RealtimeMergeEngine.mergeMatchesWithRealtime(
        existingLeagues: [league],
        update: update,
      );

      expect(result.isUpdated, isTrue);
      final merged = result.data.first.matches.first;
      expect(merged.hasPenalties, isTrue);
      expect(merged.penaltyScore1, equals('4'));
      expect(merged.penaltyScore2, equals('3'));
      expect(merged.statusCode, equals('PENALTIES'));
    });
  });

  group('MatchCard & LiveMatchCard - UI Penalty Rendering', () {
    testWidgets('MatchCard displays penalty shootout widget underneath score', (
      tester,
    ) async {
      const penaltyMatch = MatchEntity(
        id: '100',
        team1: 'Real Madrid',
        team2: 'Barcelona',
        score1: '1',
        score2: '1',
        penaltyScore1: '4',
        penaltyScore2: '5',
        status: 'انتهت',
        statusCode: 'FINISHED',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MatchCard(match: penaltyMatch)),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the penalty shootout display
      expect(find.byType(PenaltyShootoutWidget), findsOneWidget);
      expect(find.textContaining('4 - 5'), findsOneWidget);
    });

    testWidgets('LiveMatchCard displays penalty shootout score container', (
      tester,
    ) async {
      const penaltyMatch = MatchEntity(
        id: '200',
        team1: 'Arsenal',
        team2: 'Chelsea',
        score1: '2',
        score2: '2',
        penaltyScore1: '3',
        penaltyScore2: '2',
        status: 'ركلات الترجيح',
        statusCode: 'PENALTIES',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LiveMatchCard(match: penaltyMatch)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('3 - 2'), findsOneWidget);
    });
  });
}
