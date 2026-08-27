import '../../../../core/network/api_result.dart';
import '../../domain/entities/match_details_entity.dart';
import '../../domain/repositories/match_details_repository.dart';
import '../datasources/match_details_remote_datasource.dart';

class MatchDetailsRepositoryImpl implements MatchDetailsRepository {
  final MatchDetailsRemoteDataSource _remoteDataSource;

  MatchDetailsRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<MatchEventEntity>>> getEvents(
    String matchId, {
    required String lang,
  }) async {
    try {
      final data = await _remoteDataSource.getEvents(matchId, lang: lang);
      return ApiSuccess(data);
    } catch (e) {
      return const ApiSuccess([]);
    }
  }

  @override
  Future<ApiResult<List<MatchStatItemEntity>>> getStats(
    String matchId, {
    required String lang,
  }) async {
    try {
      final data = await _remoteDataSource.getStats(matchId, lang: lang);
      return ApiSuccess(data);
    } catch (e) {
      return const ApiSuccess([]);
    }
  }

  @override
  Future<ApiResult<List<MatchInfoSectionEntity>>> getDetails(
    String matchId, {
    required String lang,
    int? utcOffset,
  }) async {
    try {
      final data = await _remoteDataSource.getDetails(
        matchId,
        lang: lang,
        utcOffset: utcOffset,
      );
      return ApiSuccess(data);
    } catch (e) {
      return const ApiSuccess([]);
    }
  }

  @override
  Future<ApiResult<List<MatchNewsItemEntity>>> getNews(
    String matchId, {
    required String lang,
  }) async {
    try {
      final data = await _remoteDataSource.getNews(matchId, lang: lang);
      return ApiSuccess(data);
    } catch (e) {
      return const ApiSuccess([]);
    }
  }
}
