import 'package:flutter_test/flutter_test.dart';
import 'package:score154/features/matches/data/models/match_dto.dart';
import 'package:score154/core/utils/url_helper.dart';

void main() {
  group('MatchDto & URL Normalization Tests', () {
    test('UrlHelper correctly normalizes protocol-relative and http URLs', () {
      expect(
        UrlHelper.normalizeImageUrl('//imgs.ysscores.com/teams/64/123.png'),
        'https://imgs.ysscores.com/teams/64/123.png',
      );
      expect(
        UrlHelper.normalizeImageUrl(
          'http://imgs.ysscores.com/teams/64/123.png',
        ),
        'https://imgs.ysscores.com/teams/64/123.png',
      );
      expect(
        UrlHelper.normalizeImageUrl(
          'https://imgs.ysscores.com/teams/64/123.png',
        ),
        'https://imgs.ysscores.com/teams/64/123.png',
      );
      expect(
        UrlHelper.normalizeImageUrl('https://imgs..com/teams/64/123.png'),
        'https://imgs.ysscores.com/teams/64/123.png',
      );
      expect(
        UrlHelper.normalizePlayerPhotoUrl('https://imgs..com/player/150/456.png'),
        'https://imgs.ysscores.com/player/150/456.png',
      );
      expect(
        UrlHelper.normalizeImageUrl('https://imgs..com/championship/64/789.png'),
        'https://imgs.ysscores.com/championship/64/789.png',
      );
      expect(UrlHelper.normalizeImageUrl('   '), isNull);
      expect(UrlHelper.normalizeImageUrl('null'), isNull);
      expect(UrlHelper.normalizeImageUrl(null), isNull);
    });

    test('MatchDto correctly parses full V4.2 response contract', () {
      final json = {
        'match_id': '5868013',
        'team_1': 'سيلتا فيغو',
        'team_2': 'أوساسونا',
        'team_1_logo': 'https://imgs.ysscores.com/teams/64/9611690196747.png',
        'team_2_logo': 'https://imgs.ysscores.com/teams/64/7961690196745.png',
        'team_1_id': '9611690196747',
        'team_2_id': '7961690196745',
        'score_1': '1',
        'score_2': '1',
        'score': {'home': 1, 'away': 1},
        'time': '-',
        'status': 'الشوط الثاني',
        'status_code': 'LIVE',
        'minute': 62,
        'period': '2nd_half',
        'extra_time': '+00:00',
        'teams': {
          'home': {
            'id': '9611690196747',
            'name': 'سيلتا فيغو',
            'logo': 'https://imgs.ysscores.com/teams/64/9611690196747.png',
          },
          'away': {
            'id': '7961690196745',
            'name': 'أوساسونا',
            'logo': 'https://imgs.ysscores.com/teams/64/7961690196745.png',
          },
        },
        'league': {
          'id': '938652',
          'name': 'الدوري الإسباني',
          'logo': 'https://imgs.ysscores.com/championship/48/8641690196626.png',
        },
      };

      final dto = MatchDto.fromJson(json);

      expect(dto.id, '5868013');
      expect(dto.team1, 'سيلتا فيغو');
      expect(dto.team2, 'أوساسونا');
      expect(
        dto.team1Logo,
        'https://imgs.ysscores.com/teams/64/9611690196747.png',
      );
      expect(
        dto.team2Logo,
        'https://imgs.ysscores.com/teams/64/7961690196745.png',
      );
      expect(dto.score1, '1');
      expect(dto.score2, '1');
      expect(dto.status, 'الشوط الثاني');
      expect(dto.statusCode, 'LIVE');
      expect(dto.minute, '62');
      expect(dto.period, '2nd_half');
      expect(dto.leagueTitle, 'الدوري الإسباني');
      expect(
        dto.leagueLogo,
        'https://imgs.ysscores.com/championship/48/8641690196626.png',
      );
      expect(dto.leagueId, '938652');

      final entity = dto.toEntity(isFavorite: true);
      expect(entity.id, '5868013');
      expect(entity.isFavorite, isTrue);
    });

    test('MatchDto handles nullable / missing / unexpected values safely', () {
      final json = <String, dynamic>{
        'match_id': null,
        'team_1': null,
        'team_2': null,
        'score': null,
        'score_1': null,
        'score_2': null,
      };

      final dto = MatchDto.fromJson(json);
      expect(dto.id, isNotEmpty);
      expect(dto.team1, 'Team 1');
      expect(dto.team2, 'Team 2');
      expect(dto.score1, isNull);
      expect(dto.score2, isNull);
      expect(dto.time, '-');
      expect(dto.status, 'Not Started');
    });

    test('LeagueGroupDto parses groups and matches without crashing', () {
      final groupJson = {
        'league_id': '938652',
        'league_title': 'الدوري الإسباني',
        'league_logo':
            'https://imgs.ysscores.com/championship/48/8641690196626.png',
        'matches': [
          {
            'match_id': '5868013',
            'team_1': 'سيلتا فيغو',
            'team_2': 'أوساسونا',
            'score_1': '1',
            'score_2': '1',
            'status': 'الشوط الثاني',
          },
        ],
      };

      final group = LeagueGroupDto.fromJson(groupJson);
      expect(group.leagueTitle, 'الدوري الإسباني');
      expect(group.leagueId, '938652');
      expect(group.matches.length, 1);
      expect(group.matches.first.id, '5868013');

      final entity = group.toEntity(favoriteMatches: ['5868013']);
      expect(entity.matches.first.isFavorite, isTrue);
    });
  });
}
