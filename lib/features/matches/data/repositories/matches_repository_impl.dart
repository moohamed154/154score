import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_datasource.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  final MatchesRemoteDataSource _remoteDataSource;
  final LocalStorageService _localStorageService;

  MatchesRepositoryImpl(this._remoteDataSource, this._localStorageService);

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getMatches({
    String? date,
    required String lang,
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final dtos = await _remoteDataSource.getMatches(
        date: date,
        lang: lang,
        utcOffset: utcOffset,
        status: status,
        leagueId: leagueId,
        sort: sort,
      );

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final entities = dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();

      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load matches: $e'));
    }
  }

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getLiveMatches({
    required String lang,
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final dtos = await _remoteDataSource.getLiveMatches(
        lang: lang,
        utcOffset: utcOffset,
        date: date,
        leagueId: leagueId,
        sort: sort,
      );

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final entities = dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();

      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load live matches: $e'));
    }
  }

  @override
  Future<ApiResult<List<MatchEntity>>> getLiveMatchesFlat({
    required String lang,
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final dtos = await _remoteDataSource.getLiveMatches(
        lang: lang,
        utcOffset: utcOffset,
        date: date,
        leagueId: leagueId,
        sort: sort,
      );

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final liveMatches = <MatchEntity>[];
      for (final league in dtos) {
        for (final m in league.matches) {
          liveMatches.add(
            m.toEntity(isFavorite: favoriteMatches.contains(m.id)),
          );
        }
      }

      return ApiSuccess(liveMatches);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load live matches: $e'));
    }
  }

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getMatchesByDate({
    required String date,
    required String lang,
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final dtos = await _remoteDataSource.getMatchesByDate(
        date: date,
        lang: lang,
        utcOffset: utcOffset,
        status: status,
        leagueId: leagueId,
        sort: sort,
      );

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final entities = dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();

      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load matches for date $date: $e'));
    }
  }
}
