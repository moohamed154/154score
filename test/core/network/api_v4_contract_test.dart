import 'package:flutter_test/flutter_test.dart';
import 'package:ysscores/core/constants/api_endpoints.dart';
import 'package:ysscores/core/network/api_client.dart';
import 'package:ysscores/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:ysscores/features/match_details/data/datasources/match_details_remote_datasource.dart';
import 'package:ysscores/features/standings/data/datasources/standings_remote_datasource.dart';
import 'package:ysscores/features/transfers/data/datasources/transfers_remote_datasource.dart';
import 'package:ysscores/features/videos/data/datasources/videos_remote_datasource.dart';
import 'package:ysscores/features/profiles/data/datasources/profiles_remote_datasource.dart';

void main() {
  group('154Score V4.2 Production API Contract Tests', () {
    late ApiClient apiClient;
    late MatchesRemoteDataSource matchesDataSource;
    late MatchDetailsRemoteDataSource matchDetailsDataSource;
    late StandingsRemoteDataSource standingsDataSource;
    late TransfersRemoteDataSource transfersDataSource;
    late VideosRemoteDataSource videosDataSource;
    late ProfilesRemoteDataSource profilesDataSource;

    setUpAll(() {
      apiClient = ApiClient();
      matchesDataSource = MatchesRemoteDataSourceImpl(apiClient);
      matchDetailsDataSource = MatchDetailsRemoteDataSourceImpl(apiClient);
      standingsDataSource = StandingsRemoteDataSourceImpl(apiClient);
      transfersDataSource = TransfersRemoteDataSourceImpl(apiClient);
      videosDataSource = VideosRemoteDataSourceImpl(apiClient);
      profilesDataSource = ProfilesRemoteDataSourceImpl(apiClient);
    });

    test('1. GET /ping — Keepalive Health Check', () async {
      final res = await apiClient.get(ApiEndpoints.ping);
      expect(res, isNotNull);
    });

    test('2. GET /api/openapi.json — OpenAPI 3.1 Spec', () async {
      final res = await apiClient.get(ApiEndpoints.openapi);
      expect(res, isA<Map>());
      expect(res['openapi'], isNotNull);
    });

    test('3. GET /api/config — System Configuration', () async {
      final res = await apiClient.get(ApiEndpoints.config);
      expect(res, isA<Map>());
      expect(res['success'], isTrue);
      expect(res['data'], isNotNull);
    });

    test('4. GET /api/metrics — Telemetry & Monitoring', () async {
      final res = await apiClient.get(ApiEndpoints.metrics);
      expect(res, isA<Map>());
      expect(res['success'], isTrue);
    });

    test('5. GET /api/matches — Football Matches & Grouped Leagues', () async {
      final groups = await matchesDataSource.getMatches(
        date: '2026-08-27',
        lang: 'ar',
      );
      expect(groups, isA<List>());
      if (groups.isNotEmpty) {
        final firstGroup = groups.first;
        expect(firstGroup.leagueTitle, isNotEmpty);
        if (firstGroup.matches.isNotEmpty) {
          final firstMatch = firstGroup.matches.first;
          expect(firstMatch.id, isNotNull);
          expect(firstMatch.team1, isNotEmpty);
          expect(firstMatch.team2, isNotEmpty);
          if (firstMatch.team1Logo != null) {
            expect(firstMatch.team1Logo!.startsWith('https://'), isTrue);
          }
          if (firstMatch.team2Logo != null) {
            expect(firstMatch.team2Logo!.startsWith('https://'), isTrue);
          }
        }
      }
    });

    test('6. GET /api/matches/{id}/details — Match Overview Details', () async {
      final sections = await matchDetailsDataSource.getDetails(
        '5868013',
        lang: 'ar',
      );
      expect(sections, isA<List>());
      if (sections.isNotEmpty) {
        expect(sections.first.section, isNotEmpty);
      }
    });

    test('7. GET /api/matches/{id}/events — Match Events Timeline', () async {
      final events = await matchDetailsDataSource.getEvents(
        '5868013',
        lang: 'ar',
      );
      expect(events, isA<List>());
      for (final event in events) {
        expect(event.playerName, isNotNull);
        expect(event.minute, isNotNull);
      }
    });

    test('8. GET /api/matches/{id}/stats — Match Statistics', () async {
      final stats = await matchDetailsDataSource.getStats(
        '5868013',
        lang: 'ar',
      );
      expect(stats, isA<List>());
      for (final s in stats) {
        expect(s.title, isNotEmpty);
        expect(s.homePercentage.isNaN, isFalse);
        expect(s.homePercentage.isInfinite, isFalse);
        expect(s.homePercentage, inInclusiveRange(0.0, 1.0));
      }
    });

    test('9. GET /api/matches/{id}/news — Match News', () async {
      final news = await matchDetailsDataSource.getNews('5868013', lang: 'ar');
      expect(news, isA<List>());
    });

    test('10. GET /api/transfers — Player Transfers', () async {
      final transfers = await transfersDataSource.getTransfers(lang: 'ar');
      expect(transfers, isA<List>());
      if (transfers.isNotEmpty) {
        final t = transfers.first;
        expect(t.playerName, isNotEmpty);
        if (t.fromTeamImage != null) {
          expect(t.fromTeamImage!.startsWith('https://'), isTrue);
        }
        if (t.toTeamImage != null) {
          expect(t.toTeamImage!.startsWith('https://'), isTrue);
        }
      }
    });

    test('11. GET /api/videos — Video Highlights & Clips', () async {
      final (videos, categories) = await videosDataSource
          .getVideosAndCategories(champId: 'all', lang: 'ar');
      expect(videos, isA<List>());
      expect(categories, isA<List>());
      if (videos.isNotEmpty) {
        final v = videos.first;
        expect(v.id, isNotEmpty);
        expect(v.title, isNotEmpty);
      }
    });

    test('12. GET /api/videos/{id} — Video Clip Details & Embed', () async {
      final detail = await videosDataSource.getVideoDetail(
        '352509',
        lang: 'ar',
      );
      expect(detail.id, '352509');
      expect(detail.title, isNotEmpty);
    });

    test(
      '13. GET /api/leagues/{id}/standings — League Standings Table',
      () async {
        final standings = await standingsDataSource.getStandings(
          '938652',
          lang: 'ar',
        );
        expect(standings.leagueId, '938652');
        expect(standings.rows, isNotEmpty);
        final firstRow = standings.rows.first;
        expect(firstRow.position, 1);
        expect(firstRow.teamName, isNotEmpty);
        expect(firstRow.points, greaterThanOrEqualTo(0));
        if (firstRow.teamLogo != null) {
          expect(firstRow.teamLogo!.startsWith('https://'), isTrue);
        }
      },
    );

    test(
      '14. GET /api/leagues/{id}/top-scorers — League Top Scorers',
      () async {
        final res = await apiClient.get(
          ApiEndpoints.leagueTopScorers('938652'),
          queryParameters: {'lang': 'ar'},
        );
        expect(res, isA<Map>());
        expect(res['success'], isTrue);
        expect(res['data'], isA<List>());
      },
    );

    test('15. GET /api/stadium/{id}/{slug} — Stadium Profile', () async {
      final profile = await profilesDataSource.getProfile(
        ApiEndpoints.stadium('962', 'hard-rock-stadium'),
        '962',
        'hard-rock-stadium',
        lang: 'ar',
      );
      expect(profile.id, '962');
      expect(profile.name, isNotEmpty);
      expect(profile.sections, isNotEmpty);
    });

    test('16. GET /api/referee/{id}/{slug} — Referee Profile', () async {
      final profile = await profilesDataSource.getProfile(
        ApiEndpoints.referee('770414', 'espen-eskaas'),
        '770414',
        'espen-eskaas',
        lang: 'ar',
      );
      expect(profile.id, '770414');
      expect(profile.name, isNotEmpty);
      expect(profile.sections, isNotEmpty);
    });

    test(
      '17. GET /api/commentator/{id}/{slug} — Commentator Profile',
      () async {
        final profile = await profilesDataSource.getProfile(
          ApiEndpoints.commentator('16', 'jawad-badda'),
          '16',
          'jawad-badda',
          lang: 'ar',
        );
        expect(profile.id, '16');
        expect(profile.name, isNotEmpty);
        expect(profile.sections, isNotEmpty);
      },
    );
  });
}
