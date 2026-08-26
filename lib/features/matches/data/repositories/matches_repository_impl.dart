import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/score_helper.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_datasource.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  final MatchesRemoteDataSource _remoteDataSource;
  final LocalStorageService _localStorageService;

  MatchesRepositoryImpl(this._remoteDataSource, this._localStorageService);

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getMatches({
    required String date,
    required String lang,
    int? utcOffset,
  }) async {
    try {
      final dtos = await _remoteDataSource.getMatches(
        date: date,
        lang: lang,
        utcOffset: utcOffset,
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
  Future<ApiResult<List<MatchEntity>>> getLiveMatches({
    required String lang,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final dtos = await _remoteDataSource.getMatches(date: dateStr, lang: lang);
      final favoriteMatches = _localStorageService.getFavoriteMatches();

      final liveMatches = <MatchEntity>[];
      for (final league in dtos) {
        for (final m in league.matches) {
          if (ScoreHelper.isLiveStatus(m.status)) {
            liveMatches.add(m.toEntity(isFavorite: favoriteMatches.contains(m.id)));
          }
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
}
