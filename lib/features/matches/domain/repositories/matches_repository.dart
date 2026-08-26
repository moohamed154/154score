import '../../../../core/network/api_result.dart';
import '../entities/match_entity.dart';

abstract class MatchesRepository {
  Future<ApiResult<List<LeagueGroupEntity>>> getMatches({
    required String date,
    required String lang,
    int? utcOffset,
  });

  Future<ApiResult<List<MatchEntity>>> getLiveMatches({
    required String lang,
  });
}
