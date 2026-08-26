import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/standings_entity.dart';
import '../models/standings_dto.dart';

abstract class StandingsRemoteDataSource {
  Future<LeagueStandingsEntity> getStandings(String leagueId, {required String lang});
}

class StandingsRemoteDataSourceImpl implements StandingsRemoteDataSource {
  final ApiClient _client;

  StandingsRemoteDataSourceImpl(this._client);

  @override
  Future<LeagueStandingsEntity> getStandings(String leagueId, {required String lang}) async {
    final response = await _client.get(
      ApiEndpoints.leagueStandings(leagueId),
      queryParameters: {'lang': lang},
    );

    final rows = <StandingRowEntity>[];
    final leagueName = 'League';

    if (response is Map && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['list_match'] is List) {
        final list = data['list_match'] as List;
        for (final item in list) {
          if (item is Map) {
            item.forEach((key, val) {
              final pos = int.tryParse(key.toString()) ?? (rows.length + 1);
              if (val is Map<String, dynamic>) {
                rows.add(StandingRowDto.fromJson(pos, val).toEntity());
              }
            });
          }
        }
      }
    }

    // Sort by position
    rows.sort((a, b) => a.position.compareTo(b.position));

    return LeagueStandingsEntity(
      leagueId: leagueId,
      leagueTitle: leagueName,
      rows: rows,
    );
  }
}
