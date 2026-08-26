import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/match_dto.dart';

abstract class MatchesRemoteDataSource {
  Future<List<LeagueGroupDto>> getMatches({
    required String date,
    required String lang,
    int? utcOffset,
  });
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final ApiClient _client;

  MatchesRemoteDataSourceImpl(this._client);

  @override
  Future<List<LeagueGroupDto>> getMatches({
    required String date,
    required String lang,
    int? utcOffset,
  }) async {
    final queryParams = <String, dynamic>{
      'lang': lang,
      'date': date,
    };
    if (utcOffset != null) {
      queryParams['utc-offset'] = utcOffset;
    }

    final response = await _client.get(
      ApiEndpoints.matches,
      queryParameters: queryParams,
    );

    if (response is Map && response['data'] is List) {
      final list = response['data'] as List;
      return list.map((item) {
        if (item is Map<String, dynamic>) {
          return LeagueGroupDto.fromJson(item, date: date);
        }
        return const LeagueGroupDto(leagueTitle: 'League', matches: []);
      }).toList();
    }

    return [];
  }
}
