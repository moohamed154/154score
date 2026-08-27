import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/standings_entity.dart';
import '../models/standings_dto.dart';

abstract class StandingsRemoteDataSource {
  Future<LeagueStandingsEntity> getStandings(
    String leagueId, {
    required String lang,
  });
}

class StandingsRemoteDataSourceImpl implements StandingsRemoteDataSource {
  final ApiClient _client;

  StandingsRemoteDataSourceImpl(this._client);

  @override
  Future<LeagueStandingsEntity> getStandings(
    String leagueId, {
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.leagueStandings(leagueId),
      queryParameters: {'lang': lang},
    );

    final rows = <StandingRowEntity>[];
    String leagueName = 'League Standings';

    if (response is Map && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['league_name'] != null &&
          data['league_name'].toString().isNotEmpty) {
        leagueName = data['league_name'].toString();
      }

      // 1. Direct table parsing from V4.2 contract
      if (data['table'] is List && (data['table'] as List).isNotEmpty) {
        final tableList = data['table'] as List;
        for (int i = 0; i < tableList.length; i++) {
          final it = tableList[i];
          if (it is Map<String, dynamic>) {
            rows.add(StandingRowDto.fromJson(i + 1, it).toEntity());
          } else if (it is Map) {
            rows.add(
              StandingRowDto.fromJson(
                i + 1,
                Map<String, dynamic>.from(it),
              ).toEntity(),
            );
          }
        }
      } else {
        // 2. Fallback to raw list_match structure
        List? listMatch;
        if (data['raw'] is Map && data['raw']['list_match'] is List) {
          listMatch = data['raw']['list_match'] as List;
        } else if (data['list_match'] is List) {
          listMatch = data['list_match'] as List;
        }

        if (listMatch != null) {
          for (final item in listMatch) {
            if (item is Map) {
              item.forEach((key, val) {
                final pos = int.tryParse(key.toString()) ?? (rows.length + 1);
                if (val is Map<String, dynamic>) {
                  rows.add(StandingRowDto.fromJson(pos, val).toEntity());
                } else if (val is Map) {
                  rows.add(
                    StandingRowDto.fromJson(
                      pos,
                      Map<String, dynamic>.from(val),
                    ).toEntity(),
                  );
                }
              });
            }
          }
        }
      }
    }

    // Sort by position ascending
    rows.sort((a, b) => a.position.compareTo(b.position));

    return LeagueStandingsEntity(
      leagueId: leagueId,
      leagueTitle: leagueName,
      rows: rows,
    );
  }
}
