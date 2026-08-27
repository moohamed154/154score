import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/videos_repository.dart';
import '../datasources/videos_remote_datasource.dart';

class VideosRepositoryImpl implements VideosRepository {
  final VideosRemoteDataSource _remoteDataSource;

  VideosRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<VideoItemEntity>>> getVideos({
    required String champId,
    required String lang,
  }) async {
    try {
      final (videos, _) = await _remoteDataSource.getVideosAndCategories(
        champId: champId,
        lang: lang,
      );
      return ApiSuccess(videos);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load videos: $e'));
    }
  }

  @override
  Future<ApiResult<List<VideoCategoryEntity>>> getCategories({
    required String lang,
  }) async {
    try {
      final (_, categories) = await _remoteDataSource.getVideosAndCategories(
        champId: 'all',
        lang: lang,
      );
      return ApiSuccess(categories);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load categories: $e'));
    }
  }

  @override
  Future<ApiResult<VideoDetailEntity>> getVideoDetail(
    String id, {
    required String lang,
  }) async {
    try {
      final detail = await _remoteDataSource.getVideoDetail(id, lang: lang);
      return ApiSuccess(detail);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load video detail: $e'));
    }
  }
}
