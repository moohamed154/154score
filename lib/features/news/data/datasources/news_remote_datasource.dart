import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/news_entity.dart';

abstract class NewsRemoteDataSource {
  Future<NewsFeedEntity> getNewsFeed({required String lang});
  Future<List<NewsArticleEntity>> getTeamNews({
    required String teamId,
    required String lang,
    int page = 1,
  });
  Future<NewsDetailEntity> getNewsDetail(String id,
      {String? slug, required String lang});
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final ApiClient _client;

  NewsRemoteDataSourceImpl(this._client);

  @override
  Future<NewsFeedEntity> getNewsFeed({required String lang}) async {
    final response = await _client.get(
      ApiEndpoints.news,
      queryParameters: {'lang': lang},
    );

    final data = response['data'] as Map? ?? {};

    NewsArticleEntity? main;
    final rawMain = data['main'];
    if (rawMain is Map) {
      main = _articleFromMap(rawMain);
    }

    final important = <NewsArticleEntity>[];
    final rawImportant = data['important'] as List? ?? [];
    for (final item in rawImportant) {
      if (item is Map) important.add(_articleFromMap(item));
    }

    final teams = <NewsTeamFilterEntity>[];
    final rawTeams = data['teams'] as List? ?? [];
    for (final item in rawTeams) {
      if (item is Map) {
        teams.add(
          NewsTeamFilterEntity(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            logo: item['logo']?.toString(),
          ),
        );
      }
    }

    final latest = <NewsArticleEntity>[];
    final rawLatest = data['latest'] as List? ?? [];
    for (final item in rawLatest) {
      if (item is Map) latest.add(_articleFromMap(item));
    }

    return NewsFeedEntity(
      main: main,
      important: important,
      teams: teams,
      latest: latest,
    );
  }

  @override
  Future<List<NewsArticleEntity>> getTeamNews({
    required String teamId,
    required String lang,
    int page = 1,
  }) async {
    final response = await _client.get(
      ApiEndpoints.teamNews(teamId),
      queryParameters: {'lang': lang, 'page': page},
    );

    final data = response['data'] as Map? ?? {};
    final news = data['news'] as List? ?? [];

    return news.whereType<Map>().map((item) => _articleFromMap(item)).toList();
  }

  @override
  Future<NewsDetailEntity> getNewsDetail(
    String id, {
    String? slug,
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.newsDetails(id, slug),
      queryParameters: {'lang': lang},
    );

    final data = response['data'] as Map? ?? {};

    final rawParagraphs = data['paragraphs'] as List? ?? [];
    final paragraphs = rawParagraphs.whereType<String>().toList();

    final rawTags = data['tags'] as List? ?? [];
    final tags = rawTags.whereType<String>().toList();

    return NewsDetailEntity(
      id: data['article_id']?.toString() ?? id,
      title: data['title']?.toString() ?? '',
      image: data['image']?.toString(),
      publishedAt: data['published_at']?.toString(),
      paragraphs: paragraphs,
      content: data['content']?.toString(),
      tags: tags,
      url: data['url']?.toString(),
    );
  }

  NewsArticleEntity _articleFromMap(Map item) {
    return NewsArticleEntity(
      id: (item['article_id'] ?? item['id'])?.toString() ?? '',
      title: item['title']?.toString() ?? '',
      description: item['description']?.toString(),
      image: item['image']?.toString(),
      thumbnail: item['thumbnail']?.toString(),
      publishedAt: item['published_at']?.toString(),
      slug: item['slug']?.toString(),
      url: item['url']?.toString(),
    );
  }
}
