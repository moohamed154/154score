import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/standings_entity.dart';
import '../../domain/repositories/standings_repository.dart';
import '../datasources/standings_remote_datasource.dart';

class StandingsRepositoryImpl implements StandingsRepository {
  final StandingsRemoteDataSource _remoteDataSource;
  final Map<String, ({LeagueStandingsEntity entity, DateTime timestamp})>
  _standingsCache = {};

  StandingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<LeagueStandingsEntity>> getStandings(
    String leagueId, {
    required String lang,
  }) async {
    final key = '$leagueId-$lang';
    final cached = _standingsCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(minutes: 5)) {
      return ApiSuccess(cached.entity);
    }

    try {
      final standings = await _remoteDataSource.getStandings(
        leagueId,
        lang: lang,
      );
      _standingsCache[key] = (entity: standings, timestamp: DateTime.now());
      return ApiSuccess(standings);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.entity);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.entity);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.entity);
      return ApiFailure(ServerFailure('Failed to load standings: $e'));
    }
  }
}
