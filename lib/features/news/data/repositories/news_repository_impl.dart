import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource _remoteDataSource;

  final Map<String, ({NewsFeedEntity feed, DateTime timestamp})> _cachedFeeds = {};

  final Map<String, ({List<NewsArticleEntity> items, DateTime timestamp})>
  _teamNewsCache = {};

  final Map<String, ({NewsDetailEntity detail, DateTime timestamp})>
  _detailCache = {};

  NewsRepositoryImpl(this._remoteDataSource);

  @override
  NewsFeedEntity? getCachedNewsFeed({required String lang}) {
    return _cachedFeeds[lang]?.feed;
  }

  @override
  Future<ApiResult<NewsFeedEntity>> getNewsFeed({required String lang}) async {
    final cached = _cachedFeeds[lang];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(minutes: 5)) {
      _prewarmOtherLanguage(lang);
      return ApiSuccess(cached.feed);
    }

    try {
      final feed = await _remoteDataSource.getNewsFeed(lang: lang);
      _cachedFeeds[lang] = (feed: feed, timestamp: DateTime.now());
      _prewarmOtherLanguage(lang);
      return ApiSuccess(feed);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.feed);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.feed);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.feed);
      return ApiFailure(ServerFailure('Failed to load news feed: $e'));
    }
  }

  void _prewarmOtherLanguage(String currentLang) {
    final otherLang = currentLang == 'ar' ? 'en' : 'ar';
    final otherCached = _cachedFeeds[otherLang];
    if (otherCached == null ||
        DateTime.now().difference(otherCached.timestamp) >= const Duration(minutes: 10)) {
      _remoteDataSource
          .getNewsFeed(lang: otherLang)
          .then((otherFeed) {
            _cachedFeeds[otherLang] = (feed: otherFeed, timestamp: DateTime.now());
          })
          .catchError((_) {});
    }
  }

  @override
  Future<ApiResult<List<NewsArticleEntity>>> getTeamNews({
    required String teamId,
    required String lang,
    int page = 1,
  }) async {
    final key = '$teamId-$lang-$page';
    final cached = _teamNewsCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(minutes: 5)) {
      return ApiSuccess(cached.items);
    }

    try {
      final items = await _remoteDataSource.getTeamNews(
        teamId: teamId,
        lang: lang,
        page: page,
      );
      _teamNewsCache[key] = (items: items, timestamp: DateTime.now());
      return ApiSuccess(items);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.items);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.items);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.items);
      return ApiFailure(ServerFailure('Failed to load team news: $e'));
    }
  }

  @override
  Future<ApiResult<NewsDetailEntity>> getNewsDetail(
    String id, {
    String? slug,
    required String lang,
  }) async {
    final key = '$id-$lang';
    final cached = _detailCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(minutes: 10)) {
      return ApiSuccess(cached.detail);
    }

    try {
      final detail = await _remoteDataSource.getNewsDetail(
        id,
        slug: slug,
        lang: lang,
      );
      _detailCache[key] = (detail: detail, timestamp: DateTime.now());
      return ApiSuccess(detail);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.detail);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.detail);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.detail);
      return ApiFailure(ServerFailure('Failed to load news detail: $e'));
    }
  }
}
