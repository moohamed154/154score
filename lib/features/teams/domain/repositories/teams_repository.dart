import '../../../../core/network/api_result.dart';
import '../entities/team_entity.dart';

abstract class TeamsRepository {
  Future<ApiResult<TeamProfileEntity>> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  });
}
