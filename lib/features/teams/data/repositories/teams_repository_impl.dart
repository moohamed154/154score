import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/repositories/teams_repository.dart';
import '../datasources/teams_remote_datasource.dart';

class TeamsRepositoryImpl implements TeamsRepository {
  final TeamsRemoteDataSource _dataSource;

  TeamsRepositoryImpl(this._dataSource);

  @override
  Future<ApiResult<TeamProfileEntity>> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  }) async {
    try {
      final profile = await _dataSource.getTeamProfile(
        teamId,
        teamName: teamName,
        leagueId: leagueId,
        lang: lang,
      );
      return ApiSuccess(profile);
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<LeagueStandingsEntity>> getChampionshipStandings(
    String championshipId, {
    required String lang,
  }) async {
    try {
      final standings = await _dataSource.getChampionshipStandings(
        championshipId,
        lang: lang,
      );
      return ApiSuccess(standings);
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }
}
