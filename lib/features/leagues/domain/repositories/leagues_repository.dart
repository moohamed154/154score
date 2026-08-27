import '../../../../core/network/api_result.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../entities/top_scorer_entity.dart';

abstract class LeaguesRepository {
  Future<ApiResult<LeagueStandingsEntity>> getLeagueStandings(
    String leagueId, {
    required String lang,
  });

  Future<ApiResult<List<TopScorerEntity>>> getLeagueTopScorers(
    String leagueId, {
    required String lang,
  });

  Future<ApiResult<List<MatchEntity>>> getLeagueMatches(
    String leagueId, {
    required String lang,
    String? date,
  });
}
