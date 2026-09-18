import '../../../../core/network/api_result.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../entities/team_entity.dart';

abstract class TeamsRepository {
  Future<ApiResult<TeamProfileEntity>> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  });

  Future<ApiResult<LeagueStandingsEntity>> getChampionshipStandings(
    String championshipId, {
    required String lang,
  });
}
