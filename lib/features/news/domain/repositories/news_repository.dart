import '../../../../core/network/api_result.dart';
import '../entities/news_entity.dart';

abstract class NewsRepository {
  Future<ApiResult<NewsFeedEntity>> getNewsFeed({required String lang});

  NewsFeedEntity? getCachedNewsFeed({required String lang});

  Future<ApiResult<List<NewsArticleEntity>>> getTeamNews({
    required String teamId,
    required String lang,
    int page = 1,
  });

  Future<ApiResult<NewsDetailEntity>> getNewsDetail(
    String id, {
    String? slug,
    required String lang,
  });
}
