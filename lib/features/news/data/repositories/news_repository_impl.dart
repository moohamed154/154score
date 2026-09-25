import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource _remoteDataSource;

  NewsFeedEntity? _cachedFeed;
  DateTime? _feedCachedAt;

  final Map<String, ({List<NewsArticleEntity> items, DateTime timestamp})>
  _teamNewsCache = {};

  final Map<String, ({NewsDetailEntity detail, DateTime timestamp})>
  _detailCache = {};

  NewsRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<NewsFeedEntity>> getNewsFeed({required String lang}) async {
    if (_cachedFeed != null &&
        _feedCachedAt != null &&
        DateTime.now().difference(_feedCachedAt!) < const Duration(minutes: 5)) {
      return ApiSuccess(_cachedFeed!);
    }

    try {
      final feed = await _remoteDataSource.getNewsFeed(lang: lang);
      _cachedFeed = feed;
      _feedCachedAt = DateTime.now();
      return ApiSuccess(feed);
    } on NetworkException catch (e) {
      if (_cachedFeed != null) return ApiSuccess(_cachedFeed!);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (_cachedFeed != null) return ApiSuccess(_cachedFeed!);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (_cachedFeed != null) return ApiSuccess(_cachedFeed!);
      return ApiFailure(ServerFailure('Failed to load news feed: $e'));
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
