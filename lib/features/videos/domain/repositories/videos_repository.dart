import '../../../../core/network/api_result.dart';
import '../entities/video_entity.dart';

abstract class VideosRepository {
  Future<ApiResult<List<VideoItemEntity>>> getVideos({
    required String champId,
    required String lang,
  });
  Future<ApiResult<List<VideoCategoryEntity>>> getCategories({
    required String lang,
  });
  Future<ApiResult<VideoDetailEntity>> getVideoDetail(
    String id, {
    required String lang,
  });
}
