import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/top_scorer_entity.dart';
import '../../domain/repositories/leagues_repository.dart';
import '../datasources/leagues_remote_datasource.dart';

class LeaguesRepositoryImpl implements LeaguesRepository {
  final LeaguesRemoteDataSource _dataSource;

  LeaguesRepositoryImpl(this._dataSource);

  @override
  Future<ApiResult<LeagueStandingsEntity>> getLeagueStandings(
    String leagueId, {
    required String lang,
  }) async {
    try {
      final res = await _dataSource.getStandings(leagueId, lang: lang);
      return ApiSuccess(res);
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<TopScorerEntity>>> getLeagueTopScorers(
    String leagueId, {
    required String lang,
  }) async {
    try {
      final res = await _dataSource.getTopScorers(leagueId, lang: lang);
      return ApiSuccess(res);
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<MatchEntity>>> getLeagueMatches(
    String leagueId, {
    required String lang,
    String? date,
  }) async {
    try {
      final res = await _dataSource.getMatches(
        leagueId,
        lang: lang,
        date: date,
      );
      return ApiSuccess(res);
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>?>> getLeagueProfile(
    String leagueId, {
    required String lang,
  }) async {
    try {
      final res = await _dataSource.getLeagueProfile(leagueId, lang: lang);
      return ApiSuccess(res);
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }
}
