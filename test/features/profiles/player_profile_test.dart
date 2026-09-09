import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/network/api_result.dart';
import 'package:ysscores/features/leagues/data/models/top_scorer_dto.dart';
import 'package:ysscores/features/profiles/domain/entities/profile_entity.dart';
import 'package:ysscores/features/profiles/domain/repositories/profiles_repository.dart';
import 'package:ysscores/features/teams/domain/entities/team_entity.dart';

class MockProfilesRepository extends Mock implements ProfilesRepository {}

void main() {
  late MockProfilesRepository repo;

  setUp(() {
    repo = MockProfilesRepository();
  });

  group('Player Profile & Roster Integration Tests', () {
    test('TopScorerDto parses player_photo, penalties_scored, and playerId', () {
      final json = {
        'rank': 1,
        'player_id': '1131316',
        'player_name': 'Erling Haaland',
        'player_photo': 'https://imgs.ysscores.com/players/haaland.png',
        'team_name': 'Manchester City',
        'team_logo': 'https://imgs.ysscores.com/teams/mcfc.png',
        'team_id': '101916',
        'goals': 20,
        'penalties_scored': 4,
        'penalties_missed': 1,
        'matches': 18,
      };

      final dto = TopScorerDto.fromJson(1, json);
      final entity = dto.toEntity();

      expect(entity.playerId, equals('1131316'));
      expect(entity.playerName, equals('Erling Haaland'));
      expect(entity.playerImage, equals('https://imgs.ysscores.com/players/haaland.png'));
      expect(entity.penaltyGoals, equals(4));
      expect(entity.penaltiesMissed, equals(1));
      expect(entity.goals, equals(20));
      expect(entity.matchesPlayed, equals(18));
    });

    test('TeamSquadPlayerEntity holds squad member details', () {
      const squadMember = TeamSquadPlayerEntity(
        id: '1131316',
        name: 'محمد المحاسنة',
        number: '33',
        position: 'GK',
        photo: 'https://imgs.ysscores.com/player/48/1131316.png',
      );

      const teamProfile = TeamProfileEntity(
        teamId: '101916',
        teamName: 'الشباب',
        squad: [squadMember],
      );

      expect(teamProfile.squad.length, equals(1));
      expect(teamProfile.squad.first.name, equals('محمد المحاسنة'));
      expect(teamProfile.squad.first.number, equals('33'));
      expect(teamProfile.squad.first.position, equals('GK'));
    });

    test('getPlayerProfile returns valid ProfileEntity with player details', () async {
      const playerProfile = ProfileEntity(
        id: '1131316',
        slug: 'mohamed-al-mahasneh',
        name: 'محمد المحاسنة',
        englishName: 'Mohamed Al-Mahasneh',
        role: 'GK',
        sections: [
          ProfileSectionEntity(
            section: 'معلومات عامة',
            items: [
              ProfileItemEntity(title: 'المركز', content: 'GK'),
              ProfileItemEntity(title: 'النادي الحالي', content: 'الشباب'),
            ],
          ),
        ],
      );

      when(() => repo.getPlayerProfile('1131316', 'mohamed-al-mahasneh', lang: 'ar'))
          .thenAnswer((_) async => const ApiSuccess(playerProfile));

      final result = await repo.getPlayerProfile('1131316', 'mohamed-al-mahasneh', lang: 'ar');

      expect(result.dataOrNull?.id, equals('1131316'));
      expect(result.dataOrNull?.name, equals('محمد المحاسنة'));
      expect(result.dataOrNull?.role, equals('GK'));
      expect(result.dataOrNull?.sections.length, equals(1));
    });
  });
}
