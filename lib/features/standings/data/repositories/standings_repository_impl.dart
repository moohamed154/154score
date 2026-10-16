import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/standings_entity.dart';
import '../../domain/repositories/standings_repository.dart';
import '../datasources/standings_remote_datasource.dart';

class StandingsRepositoryImpl implements StandingsRepository {
  final StandingsRemoteDataSource _remoteDataSource;
  final LocalStorageService? _localStorageService;
  final Map<String, ({LeagueStandingsEntity entity, DateTime timestamp})>
  _standingsCache = {};

  StandingsRepositoryImpl(
    this._remoteDataSource, [
    this._localStorageService,
  ]);

  @override
  Future<ApiResult<LeagueStandingsEntity>> getStandings(
    String leagueId, {
    required String lang,
  }) async {
    final key = '$leagueId-$lang';
    final cached = _standingsCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(minutes: 5)) {
      return ApiSuccess(cached.entity);
    }

    // Attempt restoring from local persistent storage if in-memory cache was empty
    if (cached == null && _localStorageService != null) {
      final localFallback = _tryGetLocalStandings(leagueId, lang: lang);
      if (localFallback != null) {
        _standingsCache[key] = (entity: localFallback, timestamp: DateTime.now().subtract(const Duration(minutes: 3)));
      }
    }

    try {
      final standings = await _remoteDataSource.getStandings(
        leagueId,
        lang: lang,
      );
      _standingsCache[key] = (entity: standings, timestamp: DateTime.now());
      return ApiSuccess(standings);
    } on NetworkException catch (e) {
      final fallback = _standingsCache[key]?.entity ?? _tryGetLocalStandings(leagueId, lang: lang);
      if (fallback != null) return ApiSuccess(fallback);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      final fallback = _standingsCache[key]?.entity ?? _tryGetLocalStandings(leagueId, lang: lang);
      if (fallback != null) return ApiSuccess(fallback);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      final fallback = _standingsCache[key]?.entity ?? _tryGetLocalStandings(leagueId, lang: lang);
      if (fallback != null) return ApiSuccess(fallback);
      return ApiFailure(ServerFailure('Failed to load standings: $e'));
    }
  }

  LeagueStandingsEntity? _tryGetLocalStandings(String leagueId, {required String lang}) {
    if (_localStorageService == null) return null;
    try {
      final raw = _localStorageService.getCachedLeagueStandings(leagueId, lang: lang);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        return _remoteDataSource.parseStandings(decoded, defaultLeagueId: leagueId, lang: lang);
      }
    } catch (_) {}
    return null;
  }
}

