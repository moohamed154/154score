import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/match_dto.dart';

abstract class MatchesRemoteDataSource {
  Future<List<LeagueGroupDto>> getMatches({
    String? date,
    String lang = 'ar',
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  });

  Future<List<LeagueGroupDto>> getLiveMatches({
    String lang = 'ar',
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  });

  Future<List<LeagueGroupDto>> getMatchesByDate({
    required String date,
    String lang = 'ar',
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  });
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final ApiClient _client;

  MatchesRemoteDataSourceImpl(this._client);

  List<LeagueGroupDto> _parseLeagueGroups(
    dynamic response, {
    String? defaultDate,
  }) {
    if (response is Map && response['data'] is List) {
      final list = response['data'] as List;
      final responseDate = response['date']?.toString() ?? defaultDate;
      return list.map((item) {
        if (item is Map) {
          return LeagueGroupDto.fromJson(
            Map<String, dynamic>.from(item),
            date: responseDate,
          );
        }
        return const LeagueGroupDto(leagueTitle: 'League', matches: []);
      }).toList();
    } else if (response is List) {
      return response.map((item) {
        if (item is Map) {
          return LeagueGroupDto.fromJson(
            Map<String, dynamic>.from(item),
            date: defaultDate,
          );
        }
        return const LeagueGroupDto(leagueTitle: 'League', matches: []);
      }).toList();
    }
    return [];
  }

  @override
  Future<List<LeagueGroupDto>> getMatches({
    String? date,
    String lang = 'ar',
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{'lang': lang};
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (utcOffset != null) queryParams['utc-offset'] = utcOffset.toString();
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (leagueId != null && leagueId.isNotEmpty) {
      queryParams['league_id'] = leagueId;
    }
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

    final response = await _client.get(
      ApiEndpoints.matches,
      queryParameters: queryParams,
    );

    return _parseLeagueGroups(
      response,
      defaultDate: date ?? DateFormatter.toApiDateString(DateTime.now()),
    );
  }

  @override
  Future<List<LeagueGroupDto>> getLiveMatches({
    String lang = 'ar',
    int? utcOffset,
    String? date,
    String? leagueId,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{'lang': lang};
    if (utcOffset != null) queryParams['utc-offset'] = utcOffset.toString();
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (leagueId != null && leagueId.isNotEmpty) {
      queryParams['league_id'] = leagueId;
    }
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

    final response = await _client.get(
      ApiEndpoints.matchesLive,
      queryParameters: queryParams,
    );

    return _parseLeagueGroups(response, defaultDate: date);
  }

  @override
  Future<List<LeagueGroupDto>> getMatchesByDate({
    required String date,
    String lang = 'ar',
    int? utcOffset,
    String? status,
    String? leagueId,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{'lang': lang};
    if (utcOffset != null) queryParams['utc-offset'] = utcOffset.toString();
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (leagueId != null && leagueId.isNotEmpty) {
      queryParams['league_id'] = leagueId;
    }
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

    final response = await _client.get(
      ApiEndpoints.matchesByDate(date),
      queryParameters: queryParams,
    );

    return _parseLeagueGroups(response, defaultDate: date);
  }
}
