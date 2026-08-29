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

  Future<List<MatchEntity>> getMatches(
    String leagueId, {
    required String lang,
    String? date,
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

    if (response is Map && response['data'] is List) {
      final rawList = response['data'] as List;
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
  Future<List<MatchEntity>> getMatches(
    String leagueId, {
    required String lang,
    String? date,
  }) async {
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
          if (leagueId.isEmpty || lId == leagueId) {
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
    }

    return matches;
  }
}
