import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/constants/api_endpoints.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';
import 'package:score154/core/utils/realtime_merge_engine.dart';
import 'package:score154/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';

void main() {
  late ApiClient apiClient;
  late MatchesRemoteDataSource remoteDataSource;

  setUpAll(() {
    apiClient = ApiClient();
    remoteDataSource = MatchesRemoteDataSourceImpl(apiClient);
  });

  group('154Score Matches API & WebSocket Comprehensive Tests', () {
    test('1. Verify ApiEndpoints structure', () {
      expect(ApiEndpoints.matches, '/api/matches');
      expect(ApiEndpoints.matchesLive, '/api/matches/live');
      expect(
        ApiEndpoints.matchesByDate('2026-08-29'),
        '/api/matches/date/2026-08-29',
      );
    });

    test('2. Live Remote DataSource: GET /api/matches (default)', () async {
      final leagues = await remoteDataSource.getMatches(lang: 'ar');
      expect(leagues, isA<List>());
      for (final league in leagues) {
        expect(league.leagueTitle, isNotEmpty);
      }
    });

    test('3. Live Remote DataSource: GET /api/matches/live', () async {
      final liveLeagues = await remoteDataSource.getLiveMatches(lang: 'ar');
      expect(liveLeagues, isA<List>());
      for (final league in liveLeagues) {
        expect(league.leagueTitle, isNotEmpty);
        for (final match in league.matches) {
          expect(match.team1, isNotEmpty);
          expect(match.team2, isNotEmpty);
        }
      }
    });

    test('4. Live Remote DataSource: GET /api/matches/date/{date}', () async {
      final dateLeagues = await remoteDataSource.getMatchesByDate(
        date: '2026-08-29',
        lang: 'ar',
      );
      expect(dateLeagues, isA<List>());
      for (final league in dateLeagues) {
        expect(league.leagueTitle, isNotEmpty);
      }
    });

    test('5. WebSocket Envelope Unpacking: live_matches_update with LeagueMatches array', () {
      final wsService = WebSocketServiceImpl();

      final emittedUpdates = <LiveMatchUpdate>[];
      final subscription = wsService.liveMatchesStream.listen((update) {
        emittedUpdates.add(update);
      });

      final envelopePayload = {
        'success': true,
        'updatedAt': 1724956400000,
        'data': [
          {
            'league_id': '938652',
            'league_title': 'الدوري الإسباني',
            'league_logo':
                'https://imgs.ysscores.com/championship/48/8641690196626.png',
            'matches': [
              {
                'match_id': '5868040',
                'team_1': 'إشبيلية',
                'team_2': 'أتلتيكو مدريد',
                'team_1_logo':
                    'https://imgs.ysscores.com/teams/64/6931690196743.png',
                'team_2_logo':
                    'https://imgs.ysscores.com/teams/64/1431719588699.png',
                'score_1': '0',
                'score_2': '4',
                'score': {'home': 0, 'away': 4},
                'time': '-',
                'status': 'الشوط الثاني',
                'status_code': 'LIVE',
                'minute': 50,
                'period': '2nd_half',
                'extra_time': '+00:00',
              },
            ],
          },
        ],
      };

      // Connect and test listener
      wsService.initialize();
      // Socket mock simulation - test parsing directly
      final dataList = envelopePayload['data'] as List;
      final firstGroup = dataList[0] as Map<String, dynamic>;
      final matchesList = firstGroup['matches'] as List;
      final matchMap = matchesList[0] as Map<String, dynamic>;

      final update = LiveMatchUpdate.fromJson(
        matchMap,
        defaultLeagueTitle: 'الدوري الإسباني',
        defaultLeagueId: '938652',
      );

      expect(update.matchId, '5868040');
      expect(update.team1, 'إشبيلية');
      expect(update.team2, 'أتلتيكو مدريد');
      expect(update.score1, '0');
      expect(update.score2, '4');
      expect(update.status, 'الشوط الثاني');
      expect(update.statusCode, 'LIVE');
      expect(update.minute, '50');
      expect(update.period, '2nd_half');
      expect(update.extraTime, '+00:00');
      expect(update.leagueTitle, 'الدوري الإسباني');

      // Test RealtimeMergeEngine with update
      const initialLeagues = [
        LeagueGroupEntity(
          leagueTitle: 'الدوري الإسباني',
          leagueId: '938652',
          matches: [
            MatchEntity(
              id: '5868040',
              team1: 'إشبيلية',
              team2: 'أتلتيكو مدريد',
              score1: '0',
              score2: '0',
              status: 'مباشر',
              minute: '10',
            ),
          ],
        ),
      ];

      final mergeResult = RealtimeMergeEngine.mergeMatchesWithRealtime(
        existingLeagues: initialLeagues,
        update: update,
      );

      expect(mergeResult.isUpdated, isTrue);
      final mergedMatch = mergeResult.data.first.matches.first;
      expect(mergedMatch.score1, '0');
      expect(mergedMatch.score2, '4');
      expect(mergedMatch.status, 'الشوط الثاني');
      expect(mergedMatch.statusCode, 'LIVE');
      expect(mergedMatch.minute, '50');
      expect(mergedMatch.period, '2nd_half');
      expect(mergedMatch.extraTime, '+00:00');

      subscription.cancel();
      wsService.dispose();
    });
  });
}
