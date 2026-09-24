import '../../../../core/network/api_result.dart';
import '../../domain/entities/match_details_entity.dart';
import '../../domain/repositories/match_details_repository.dart';
import '../datasources/match_details_remote_datasource.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  _CacheEntry(this.data) : timestamp = DateTime.now();
  bool isFresh(Duration ttl) => DateTime.now().difference(timestamp) < ttl;
}

class MatchDetailsRepositoryImpl implements MatchDetailsRepository {
  final MatchDetailsRemoteDataSource _remoteDataSource;

  final Map<String, _CacheEntry<MatchEventsPayload>> _eventsCache = {};
  final Map<String, _CacheEntry<MatchDetailsPayload>> _detailsCache = {};
  final Map<String, _CacheEntry<List<MatchStatItemEntity>>> _statsCache = {};
  final Map<String, _CacheEntry<List<MatchNewsItemEntity>>> _newsCache = {};
  final Map<String, _CacheEntry<MatchLineupEntity?>> _lineupsCache = {};

  static const _eventsTtl = Duration(seconds: 20);
  static const _statsTtl = Duration(seconds: 30);
  static const _detailsTtl = Duration(minutes: 5);
  static const _newsTtl = Duration(minutes: 5);
  static const _lineupsTtl = Duration(minutes: 2);

  MatchDetailsRepositoryImpl(this._remoteDataSource);

  static String _cleanMatchId(String id) =>
      Uri.decodeComponent(id).replaceAll('match:', '').trim();

  @override
  Future<ApiResult<MatchEventsPayload>> getEventsPayload(
    String matchId, {
    required String lang,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    final key = '$cleanId-$lang';
    final cached = _eventsCache[key];
    if (cached != null && cached.isFresh(_eventsTtl)) {
      return ApiSuccess(cached.data);
    }

    try {
      final data = await _remoteDataSource.getEventsPayload(
        cleanId,
        lang: lang,
      );
      _eventsCache[key] = _CacheEntry(data);
      return ApiSuccess(data);
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.data);
      return const ApiSuccess(MatchEventsPayload());
    }
  }

  @override
  Future<ApiResult<List<MatchEventEntity>>> getEvents(
    String matchId, {
    required String lang,
  }) async {
    final payloadRes = await getEventsPayload(matchId, lang: lang);
    return ApiSuccess(payloadRes.dataOrNull?.events ?? const []);
  }

  @override
  Future<ApiResult<List<MatchStatItemEntity>>> getStats(
    String matchId, {
    required String lang,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    final key = '$cleanId-$lang';
    final cached = _statsCache[key];
    if (cached != null && cached.isFresh(_statsTtl)) {
      return ApiSuccess(cached.data);
    }

    try {
      final data = await _remoteDataSource.getStats(cleanId, lang: lang);
      _statsCache[key] = _CacheEntry(data);
      return ApiSuccess(data);
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.data);
      return const ApiSuccess([]);
    }
  }

  @override
  Future<ApiResult<List<MatchInfoSectionEntity>>> getDetails(
    String matchId, {
    required String lang,
    int? utcOffset,
  }) async {
    final payloadRes = await getDetailsPayload(
      matchId,
      lang: lang,
      utcOffset: utcOffset,
    );
    return ApiSuccess(payloadRes.dataOrNull?.sections ?? const []);
  }

  @override
  Future<ApiResult<MatchDetailsPayload>> getDetailsPayload(
    String matchId, {
    required String lang,
    int? utcOffset,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    final key = '$cleanId-$lang-${utcOffset ?? 0}';
    final cached = _detailsCache[key];
    if (cached != null && cached.isFresh(_detailsTtl)) {
      return ApiSuccess(cached.data);
    }

    try {
      final data = await _remoteDataSource.getDetailsPayload(
        cleanId,
        lang: lang,
        utcOffset: utcOffset,
      );
      _detailsCache[key] = _CacheEntry(data);
      return ApiSuccess(data);
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.data);
      return const ApiSuccess(MatchDetailsPayload());
    }
  }

  @override
  Future<ApiResult<List<MatchNewsItemEntity>>> getNews(
    String matchId, {
    required String lang,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    final key = '$cleanId-$lang';
    final cached = _newsCache[key];
    if (cached != null && cached.isFresh(_newsTtl)) {
      return ApiSuccess(cached.data);
    }

    try {
      final data = await _remoteDataSource.getNews(cleanId, lang: lang);
      _newsCache[key] = _CacheEntry(data);
      return ApiSuccess(data);
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.data);
      return const ApiSuccess([]);
    }
  }

  @override
  Future<ApiResult<MatchLineupEntity?>> getLineups(
    String matchId, {
    required String lang,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    final key = '$cleanId-$lang';
    final cached = _lineupsCache[key];
    if (cached != null && cached.isFresh(_lineupsTtl)) {
      return ApiSuccess(cached.data);
    }

    try {
      final data = await _remoteDataSource.getLineups(cleanId, lang: lang);
      _lineupsCache[key] = _CacheEntry(data);
      return ApiSuccess(data);
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.data);
      return const ApiSuccess(null);
    }
  }
}
