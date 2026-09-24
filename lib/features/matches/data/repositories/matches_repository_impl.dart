import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_datasource.dart';
import '../models/match_dto.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  final MatchesRemoteDataSource _remoteDataSource;
  final LocalStorageService _localStorageService;

  MatchesRepositoryImpl(this._remoteDataSource, this._localStorageService);

  List<LeagueGroupDto> _reconcileWithLiveMatches(
    List<LeagueGroupDto> groups,
    List<LeagueGroupDto> liveGroups,
  ) {
    if (liveGroups.isEmpty) return groups;

    final liveById = <String, MatchDto>{};
    final liveByTeams = <String, MatchDto>{};

    for (final lg in liveGroups) {
      for (final m in lg.matches) {
        if (m.id != null && m.id!.isNotEmpty) {
          liveById[m.id!] = m;
        }
        final key =
            '${m.team1.trim().toLowerCase()}_${m.team2.trim().toLowerCase()}';
        liveByTeams[key] = m;
      }
    }

    return groups.map((g) {
      final updatedMatches = g.matches.map((m) {
        final key =
            '${m.team1.trim().toLowerCase()}_${m.team2.trim().toLowerCase()}';
        final liveMatch =
            (m.id != null ? liveById[m.id] : null) ?? liveByTeams[key];

        if (liveMatch == null) return m;

        return m.copyWith(
          minute:
              (liveMatch.minute != null &&
                  liveMatch.minute!.isNotEmpty &&
                  liveMatch.minute != 'null')
              ? liveMatch.minute
              : m.minute,
          period: (liveMatch.period != null && liveMatch.period!.isNotEmpty)
              ? liveMatch.period
              : m.period,
          extraTime:
              (liveMatch.extraTime != null && liveMatch.extraTime!.isNotEmpty)
              ? liveMatch.extraTime
              : m.extraTime,
          status: (liveMatch.status != null && liveMatch.status!.isNotEmpty)
              ? liveMatch.status
              : m.status,
          statusCode:
              (liveMatch.statusCode != null && liveMatch.statusCode!.isNotEmpty)
              ? liveMatch.statusCode
              : m.statusCode,
          score1: (liveMatch.score1 != null && liveMatch.score1!.isNotEmpty)
              ? liveMatch.score1
              : m.score1,
          score2: (liveMatch.score2 != null && liveMatch.score2!.isNotEmpty)
              ? liveMatch.score2
              : m.score2,
          penaltyScore1:
              (liveMatch.penaltyScore1 != null &&
                  liveMatch.penaltyScore1!.isNotEmpty)
              ? liveMatch.penaltyScore1
              : m.penaltyScore1,
          penaltyScore2:
              (liveMatch.penaltyScore2 != null &&
                  liveMatch.penaltyScore2!.isNotEmpty)
              ? liveMatch.penaltyScore2
              : m.penaltyScore2,
        );
      }).toList();

      return g.copyWith(matches: updatedMatches);
    }).toList();
  }

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getMatches({
    String? date,
    required String lang,
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final isLiveOrToday =
          date == null ||
          date.isEmpty ||
          date == DateFormatter.toApiDateString(DateTime.now());

      final matchesFuture = _remoteDataSource.getMatches(
        date: date,
        lang: lang,
        utcOffset: utcOffset,
        status: status,
        leagueId: leagueId,
        sort: sort,
      );

      final liveFuture = isLiveOrToday
          ? _remoteDataSource
                .getLiveMatches(
                  lang: lang,
                  utcOffset: utcOffset,
                  date: date,
                  leagueId: leagueId,
                  sort: sort,
                )
                .catchError((_) => <LeagueGroupDto>[])
          : Future.value(<LeagueGroupDto>[]);

      final results = await Future.wait([matchesFuture, liveFuture]);
      var dtos = results[0];
      final liveDtos = results[1];

      if (liveDtos.isNotEmpty) {
        dtos = _reconcileWithLiveMatches(dtos, liveDtos);
      }

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final entities = dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();

      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load matches: $e'));
    }
  }

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getLiveMatches({
    required String lang,
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final dtos = await _remoteDataSource.getLiveMatches(
        lang: lang,
        utcOffset: utcOffset,
        date: date,
        leagueId: leagueId,
        sort: sort,
      );

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final entities = dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();

      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load live matches: $e'));
    }
  }

  @override
  Future<ApiResult<List<MatchEntity>>> getLiveMatchesFlat({
    required String lang,
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  }) async {
    try {
      final dtos = await _remoteDataSource.getLiveMatches(
        lang: lang,
        utcOffset: utcOffset,
        date: date,
        leagueId: leagueId,
        sort: sort,
      );

      final favoriteMatches = _localStorageService.getFavoriteMatches();
      final liveMatches = <MatchEntity>[];
      for (final league in dtos) {
        for (final m in league.matches) {
          liveMatches.add(
            m.toEntity(isFavorite: favoriteMatches.contains(m.id)),
          );
        }
      }

      return ApiSuccess(liveMatches);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load live matches: $e'));
    }
  }

  final Map<String, ({List<LeagueGroupDto> dtos, DateTime timestamp})>
  _dateMatchesCache = {};

  @override
  Future<ApiResult<List<LeagueGroupEntity>>> getMatchesByDate({
    required String date,
    required String lang,
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  }) async {
    final isToday = date == DateFormatter.toApiDateString(DateTime.now());
    final cacheKey = '$date-$lang-${utcOffset ?? 0}-$status-$leagueId-$sort';
    final ttl = isToday
        ? const Duration(seconds: 20)
        : const Duration(minutes: 5);

    final cached = _dateMatchesCache[cacheKey];
    final favoriteMatches = _localStorageService.getFavoriteMatches();

    if (cached != null && DateTime.now().difference(cached.timestamp) < ttl) {
      final entities = cached.dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();
      return ApiSuccess(entities);
    }

    try {
      final matchesFuture = _remoteDataSource.getMatchesByDate(
        date: date,
        lang: lang,
        utcOffset: utcOffset,
        status: status,
        leagueId: leagueId,
        sort: sort,
      );

      final liveFuture = isToday
          ? _remoteDataSource
                .getLiveMatches(
                  lang: lang,
                  utcOffset: utcOffset,
                  date: date,
                  leagueId: leagueId,
                  sort: sort,
                )
                .catchError((_) => <LeagueGroupDto>[])
          : Future.value(<LeagueGroupDto>[]);

      final results = await Future.wait([matchesFuture, liveFuture]);
      var dtos = results[0];
      final liveDtos = results[1];

      if (liveDtos.isNotEmpty) {
        dtos = _reconcileWithLiveMatches(dtos, liveDtos);
      }

      _dateMatchesCache[cacheKey] = (dtos: dtos, timestamp: DateTime.now());

      final entities = dtos
          .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
          .toList();

      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      if (cached != null) {
        final entities = cached.dtos
            .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
            .toList();
        return ApiSuccess(entities);
      }
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) {
        final entities = cached.dtos
            .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
            .toList();
        return ApiSuccess(entities);
      }
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) {
        final entities = cached.dtos
            .map((dto) => dto.toEntity(favoriteMatches: favoriteMatches))
            .toList();
        return ApiSuccess(entities);
      }
      return ApiFailure(
        ServerFailure('Failed to load matches for date $date: $e'),
      );
    }
  }
}
