import '../../../../core/network/api_result.dart';
import '../entities/standings_entity.dart';

abstract class StandingsRepository {
  void clearCache([String? leagueId]) {}

  Future<ApiResult<LeagueStandingsEntity>> getStandings(
    String leagueId, {
    required String lang,
  });

  Future<ApiResult<dynamic>> getRankings({
    required String lang,
    String search = '',
  }) async =>
      const ApiSuccess(null);
}
