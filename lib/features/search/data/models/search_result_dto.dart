import '../../domain/entities/search_result_entity.dart';

/// Maps raw JSON from `/api/search` into [SearchResultsEntity].
class SearchResultDto {
  static SearchResultsEntity fromJson(Map<String, dynamic> json, String query) {
    final rawData = json['data'];
    final Map<String, dynamic> data = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;

    final championships = _mapList(
      data['championships'] as List<dynamic>? ??
          data['championship'] as List<dynamic>? ??
          [],
      _mapChampionship,
    );

    final teams = _mapList(
      data['teams'] as List<dynamic>? ?? data['team'] as List<dynamic>? ?? [],
      _mapTeam,
    );

    final players = _mapList(
      data['players'] as List<dynamic>? ??
          data['player'] as List<dynamic>? ??
          [],
      _mapPlayer,
    );

    return SearchResultsEntity(
      query: (data['query'] as String?) ?? query,
      championships: championships,
      teams: teams,
      players: players,
    );
  }

  static List<SearchResultEntity> _mapList(
    List<dynamic> raw,
    SearchResultEntity Function(Map<String, dynamic>) mapper,
  ) {
    final result = <SearchResultEntity>[];
    for (final item in raw) {
      try {
        if (item is Map<String, dynamic>) {
          result.add(mapper(item));
        }
      } catch (_) {}
    }
    return result;
  }

  static SearchResultEntity _mapChampionship(Map<String, dynamic> m) {
    return SearchResultEntity(
      id: m['id']?.toString() ?? '',
      type: 'championship',
      title: m['title']?.toString() ?? '',
      logo: m['logo']?.toString(),
    );
  }

  static SearchResultEntity _mapTeam(Map<String, dynamic> m) {
    final country = m['country'];
    String? countryTitle;
    String? countryCode;
    if (country is Map) {
      countryTitle = country['title']?.toString();
      countryCode = country['code']?.toString();
    } else if (country is String) {
      countryTitle = country;
    }

    return SearchResultEntity(
      id: m['id']?.toString() ?? '',
      type: 'team',
      title: m['title']?.toString() ?? '',
      fullTitle: m['full_title']?.toString(),
      logo: m['logo']?.toString(),
      country: countryTitle,
      countryCode: countryCode,
    );
  }

  static SearchResultEntity _mapPlayer(Map<String, dynamic> m) {
    var logo = (m['logo'] ?? m['photo'] ?? m['image'])?.toString();
    if (logo != null && logo.contains('/players/')) {
      logo = logo.replaceAll('/players/', '/player/');
    }

    return SearchResultEntity(
      id: m['id']?.toString() ?? '',
      type: 'player',
      title: m['title']?.toString() ?? '',
      fullTitle: m['full_title']?.toString(),
      logo: logo,
      position: m['position']?.toString(),
    );
  }
}
