import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/league_entity.dart';
import '../../domain/entities/top_scorer_entity.dart';
import '../../domain/repositories/leagues_repository.dart';
import '../datasources/leagues_remote_datasource.dart';

class LeaguesRepositoryImpl implements LeaguesRepository {
  final LeaguesRemoteDataSource _dataSource;
  final Map<String, ({LeagueDetailsEntity data, DateTime timestamp})>
  _detailsCache = {};

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
  Future<ApiResult<List<TopScorerEntity>>> getLeagueAssists(
    String leagueId, {
    required String lang,
  }) async {
    try {
      final res = await _dataSource.getAssists(leagueId, lang: lang);
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

  @override
  Future<ApiResult<LeagueDetailsEntity>> getLeagueFullDetails(
    String leagueId, {
    required String lang,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$leagueId-$lang';
    final cached = _detailsCache[cacheKey];

    // Return instant memory cache if fresh (< 5 mins) and not force refreshing
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(minutes: 5)) {
      return ApiSuccess(cached.data);
    }

    try {
      final details = await _dataSource.getLeagueFullDetails(
        leagueId,
        lang: lang,
      );
      _detailsCache[cacheKey] = (data: details, timestamp: DateTime.now());
      return ApiSuccess(details);
    } catch (e) {
      if (cached != null) {
        return ApiSuccess(cached.data);
      }
      return ApiFailure(ServerFailure(e.toString()));
    }
  }
}
