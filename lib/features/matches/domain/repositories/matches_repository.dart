import '../../../../core/network/api_result.dart';
import '../entities/match_entity.dart';

abstract class MatchesRepository {
  Future<ApiResult<List<LeagueGroupEntity>>> getMatches({
    String? date,
    required String lang,
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  });

  Future<ApiResult<List<LeagueGroupEntity>>> getLiveMatches({
    required String lang,
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  });

  Future<ApiResult<List<MatchEntity>>> getLiveMatchesFlat({
    required String lang,
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  });

  Future<ApiResult<List<LeagueGroupEntity>>> getMatchesByDate({
    required String date,
    required String lang,
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  });
}
