import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/standings_entity.dart';
import '../../domain/repositories/standings_repository.dart';
import '../datasources/standings_remote_datasource.dart';

class StandingsRepositoryImpl implements StandingsRepository {
  final StandingsRemoteDataSource _remoteDataSource;

  StandingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<LeagueStandingsEntity>> getStandings(
    String leagueId, {
    required String lang,
  }) async {
    try {
      final standings = await _remoteDataSource.getStandings(
        leagueId,
        lang: lang,
      );
      return ApiSuccess(standings);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load standings: $e'));
    }
  }
}
