import '../../../../core/network/api_result.dart';
import '../entities/standings_entity.dart';

abstract class StandingsRepository {
  Future<ApiResult<LeagueStandingsEntity>> getStandings(
    String leagueId, {
    required String lang,
  });
}
