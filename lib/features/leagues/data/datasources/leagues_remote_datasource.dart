import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../matches/data/models/match_dto.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/data/datasources/standings_remote_datasource.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/top_scorer_entity.dart';
import '../models/top_scorer_dto.dart';

abstract class LeaguesRemoteDataSource {
  Future<LeagueStandingsEntity> getStandings(
    String leagueId, {
    required String lang,
  });

  Future<List<TopScorerEntity>> getTopScorers(
    String leagueId, {
    required String lang,
  });

  Future<List<TopScorerEntity>> getAssists(
    String leagueId, {
    required String lang,
  });

  Future<List<MatchEntity>> getMatches(
    String leagueId, {
    required String lang,
    String? date,
  });

  Future<Map<String, dynamic>?> getLeagueProfile(
    String leagueId, {
    required String lang,
  });
}

class LeaguesRemoteDataSourceImpl implements LeaguesRemoteDataSource {
  final ApiClient _client;
  final StandingsRemoteDataSource _standingsDataSource;

  LeaguesRemoteDataSourceImpl(this._client, this._standingsDataSource);

  @override
  Future<LeagueStandingsEntity> getStandings(
    String leagueId, {
    required String lang,
  }) {
    return _standingsDataSource.getStandings(leagueId, lang: lang);
  }

  @override
  Future<List<TopScorerEntity>> getTopScorers(
    String leagueId, {
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.leagueTopScorers(leagueId),
      queryParameters: {'lang': lang},
    );

    final list = <TopScorerEntity>[];

    if (response is Map && response['data'] != null) {
      final data = response['data'];
      List rawList = [];

      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        if (data['goals'] is List) {
          rawList = data['goals'] as List;
        } else if (data['scorers'] is List) {
          rawList = data['scorers'] as List;
        } else if (data['table'] is List) {
          rawList = data['table'] as List;
        }
      }

      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          list.add(TopScorerDto.fromJson(i + 1, item).toEntity());
        } else if (item is Map) {
          list.add(
            TopScorerDto.fromJson(
              i + 1,
              Map<String, dynamic>.from(item),
            ).toEntity(),
          );
        }
      }
    }

    return list;
  }

  @override
  Future<List<TopScorerEntity>> getAssists(
    String leagueId, {
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.leagueAssists(leagueId),
      queryParameters: {'lang': lang},
    );

    final list = <TopScorerEntity>[];

    if (response is Map && response['data'] != null) {
      final data = response['data'];
      List rawList = [];

      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        if (data['assists'] is List) {
          rawList = data['assists'] as List;
        } else if (data['table'] is List) {
          rawList = data['table'] as List;
        } else if (data['scorers'] is List) {
          rawList = data['scorers'] as List;
        }
      }

      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          list.add(TopScorerDto.fromJson(i + 1, item).toEntity());
        } else if (item is Map) {
          list.add(
            TopScorerDto.fromJson(
              i + 1,
              Map<String, dynamic>.from(item),
            ).toEntity(),
          );
        }
      }
    }

    return list;
  }

  String _normalizeLeagueId(String id) {
    return switch (id) {
      '937599' || '284' => '6811', // Premier League
      '938652' || '285' => '1933', // LaLiga
      '936357' || '287' => '3734', // Serie A
      '938769' || '286' => '2606', // Bundesliga
      '943230' || '288' => '12048', // UEFA Champions League
      _ => id,
    };
  }

  @override
  Future<List<MatchEntity>> getMatches(
    String leagueId, {
    required String lang,
    String? date,
  }) async {
    final candidateIds = <String>{
      if (leagueId.isNotEmpty) _normalizeLeagueId(leagueId),
      if (leagueId.isNotEmpty) leagueId,
    };

    // 1. Try dedicated championship matches endpoint with candidate IDs
    for (final candidateId in candidateIds) {
      try {
        final directResponse = await _client.get(
          ApiEndpoints.leagueMatches(candidateId),
          queryParameters: {'lang': lang},
        );

        if (directResponse is Map && directResponse['data'] != null) {
          final data = directResponse['data'];
          List rawMatches = [];
          String? leagueTitle;
          String? leagueLogo;

          if (data is List) {
            rawMatches = data;
          } else if (data is Map) {
            leagueTitle =
                data['name']?.toString() ?? data['league_title']?.toString();
            leagueLogo =
                data['logo']?.toString() ?? data['league_logo']?.toString();
            if (data['matches'] is List) {
              rawMatches = data['matches'] as List;
            }
          }

          if (rawMatches.isNotEmpty) {
            final matches = <MatchEntity>[];
            for (final m in rawMatches) {
              if (m is Map) {
                matches.add(
                  MatchDto.fromJson(
                    Map<String, dynamic>.from(m),
                    leagueTitle: leagueTitle,
                    leagueLogo: leagueLogo,
                    leagueId: leagueId,
                  ).toEntity(),
                );
              }
            }
            return matches;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to general matches endpoint filtered by league_id
    final queryParams = <String, dynamic>{'lang': lang};
    if (leagueId.isNotEmpty) {
      queryParams['league_id'] = leagueId;
    }
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final response = await _client.get(
      ApiEndpoints.matches,
      queryParameters: queryParams,
    );

    final matches = <MatchEntity>[];

    if (response is Map && response['data'] is List) {
      final rawLeagues = response['data'] as List;
      for (final l in rawLeagues) {
        if (l is Map) {
          final lId = l['league_id']?.toString() ?? l['id']?.toString();
          final lTitle =
              l['league_title']?.toString() ??
              l['title']?.toString() ??
              l['name']?.toString();
          final lLogo =
              l['league_logo']?.toString() ?? l['logo']?.toString();
          final lMatches = l['matches'] as List? ?? [];

          for (final m in lMatches) {
            if (m is Map<String, dynamic>) {
              matches.add(
                MatchDto.fromJson(
                  m,
                  leagueTitle: lTitle,
                  leagueLogo: lLogo,
                  leagueId: lId,
                ).toEntity(),
              );
            } else if (m is Map) {
              matches.add(
                MatchDto.fromJson(
                  Map<String, dynamic>.from(m),
                  leagueTitle: lTitle,
                  leagueLogo: lLogo,
                  leagueId: lId,
                ).toEntity(),
              );
            }
          }
        }
      }
    }

    return matches;
  }

  @override
  Future<Map<String, dynamic>?> getLeagueProfile(
    String leagueId, {
    required String lang,
  }) async {
    final candidateIds = <String>{
      if (leagueId.isNotEmpty) _normalizeLeagueId(leagueId),
      if (leagueId.isNotEmpty) leagueId,
    };

    for (final candidateId in candidateIds) {
      try {
        final response = await _client.get(
          ApiEndpoints.leagueProfile(candidateId),
          queryParameters: {'lang': lang},
        );

        if (response is Map && response['data'] is Map) {
          return Map<String, dynamic>.from(response['data'] as Map);
        }
      } catch (_) {}
    }
    return null;
  }
}
