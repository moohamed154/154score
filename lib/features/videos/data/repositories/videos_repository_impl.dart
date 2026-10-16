import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/videos_repository.dart';
import '../datasources/videos_remote_datasource.dart';

class VideosRepositoryImpl implements VideosRepository {
  final VideosRemoteDataSource _remoteDataSource;
  final Map<String, ({List<VideoItemEntity> videos, DateTime timestamp})>
      _videosCache = {};
  final Map<String,
          ({List<VideoCategoryEntity> categories, DateTime timestamp})>
      _categoriesCache = {};

  VideosRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<VideoItemEntity>>> getVideos({
    required String champId,
    required String lang,
  }) async {
    final key = '$champId-$lang';
    final cached = _videosCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(minutes: 5)) {
      return ApiSuccess(cached.videos);
    }

    try {
      final (videos, _) = await _remoteDataSource.getVideosAndCategories(
        champId: champId,
        lang: lang,
      );
      _videosCache[key] = (videos: videos, timestamp: DateTime.now());
      return ApiSuccess(videos);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.videos);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.videos);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.videos);
      return ApiFailure(ServerFailure('Failed to load videos: $e'));
    }
  }

  @override
  Future<ApiResult<List<VideoCategoryEntity>>> getCategories({
    required String lang,
  }) async {
    final cached = _categoriesCache[lang];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(minutes: 10)) {
      return ApiSuccess(cached.categories);
    }

    try {
      final (_, categories) = await _remoteDataSource.getVideosAndCategories(
        champId: 'all',
        lang: lang,
      );
      _categoriesCache[lang] = (
        categories: categories,
        timestamp: DateTime.now(),
      );
      return ApiSuccess(categories);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.categories);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.categories);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.categories);
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
