import 'package:flutter_test/flutter_test.dart';
import 'package:ysscores/features/players/data/models/player_profile_dto.dart';

void main() {
  group('PlayerProfileDto', () {
    test(
      'correctly parses full mobile app response with statistics and transfers',
      () {
        final sampleJson = {
          'status': true,
          'data': {
            'id': 701154,
            'player_status': 1,
            'title': 'كيليان مبابي',
            'image': '17874868195644.png',
            'image_cover': '17877182348654.png',
            'team_name': {
              'row_id': 8633,
              'title': 'ريال مدريد',
              'full_title': 'ريال مدريد',
              'image': '1871690196746.png',
              'status': 1,
              'world_ranking': 0,
            },
            'club_number': 10,
            'country': {
              'id': 6723,
              'title': 'فرنسا',
              'code': 'FR',
              'image': '2961763078000.png',
            },
            'inter_number': 10,
            'height': 180,
            'weight': 75,
            'birth_day': '1998-12-20',
            'position': 'CF',
            'position_name': 'مهاجم',
            'foot': 'R',
            'foot_name': 'يمين',
            'age': 27,
            'retired': 0,
            'died': 0,
            'player_statistics': [
              {
                'league': {
                  'id': 12048,
                  'url_id': 943230,
                  'title': 'دوري أبطال أوروبا',
                  'image': '3141696514284.png',
                  'ranking': 2,
                  'followed': 1,
                },
                'appearances': 1,
                'goals': 1,
                'assist': 0,
                'score_penalty': 0,
                'miss_penalty': 0,
                'yellow_card': 1,
                'red_card': 0,
                'clean_sheets': 0,
                'man_match': 0,
              },
            ],
            'transfers': [
              {
                'team_in': {
                  'row_id': 8633,
                  'title': 'ريال مدريد',
                  'image': '1871690196746.png',
                },
                'trans': 'انتقال حر',
                'value': '0',
                'active': 1,
                'important': 1,
                'date_from': '2024-07-01',
                'date_to': '2029-06-30',
              },
            ],
          },
        };

        final profile = PlayerProfileDto.fromJson(sampleJson, lang: 'ar');

        expect(profile.id, '701154');
        expect(profile.name, 'كيليان مبابي');
        expect(profile.clubNumber, 10);
        expect(profile.interNumber, 10);
        expect(profile.height, 180);
        expect(profile.weight, 75);
        expect(profile.age, 27);
        expect(profile.position, 'CF');
        expect(profile.positionName, 'مهاجم');
        expect(profile.footName, 'يمين');
        expect(profile.team?.name, 'ريال مدريد');
        expect(profile.country?.name, 'فرنسا');
        expect(profile.cover, isNotNull);

        // Statistics
        expect(profile.statistics.length, 1);
        final stat = profile.statistics.first;
        expect(stat.league.name, 'دوري أبطال أوروبا');
        expect(stat.appearances, 1);
        expect(stat.goals, 1);
        expect(stat.yellowCards, 1);

        // Transfers
        expect(profile.transfers.length, 1);
        final tr = profile.transfers.first;
        expect(tr.team?.name, 'ريال مدريد');
        expect(tr.type, 'انتقال حر');
        expect(tr.active, true);
        expect(tr.important, true);
      },
    );

    test('gracefully handles empty and fallback fields', () {
      final emptyJson = <String, dynamic>{'data': {}};
      final profile = PlayerProfileDto.fromJson(
        emptyJson,
        fallbackId: '123',
        fallbackName: 'Unknown Player',
      );

      expect(profile.id, '123');
      expect(profile.name, 'Unknown Player');
      expect(profile.statistics, isEmpty);
      expect(profile.transfers, isEmpty);
      expect(profile.retired, false);
      expect(profile.died, false);
    });
  });
}
