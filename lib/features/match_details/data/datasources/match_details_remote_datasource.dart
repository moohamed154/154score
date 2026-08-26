import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/match_details_entity.dart';

abstract class MatchDetailsRemoteDataSource {
  Future<List<MatchEventEntity>> getEvents(String matchId, {required String lang});
  Future<List<MatchStatItemEntity>> getStats(String matchId, {required String lang});
  Future<List<MatchInfoSectionEntity>> getDetails(String matchId, {required String lang, int? utcOffset});
  Future<List<MatchNewsItemEntity>> getNews(String matchId, {required String lang});
}

class MatchDetailsRemoteDataSourceImpl implements MatchDetailsRemoteDataSource {
  final ApiClient _client;

  MatchDetailsRemoteDataSourceImpl(this._client);

  @override
  Future<List<MatchEventEntity>> getEvents(String matchId, {required String lang}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchEvents(matchId),
        queryParameters: {'lang': lang},
      );

      final events = <MatchEventEntity>[];
      if (response is Map && response['data'] is List) {
        final list = response['data'] as List;
        for (final section in list) {
          if (section is Map && section['items'] != null) {
            final items = section['items'];
            if (items is Map) {
              final allEvents = items['all_events'] as List? ?? [];
              for (final e in allEvents) {
                if (e is Map) {
                  events.add(MatchEventEntity(
                    minute: e['minute']?.toString() ?? e['time']?.toString() ?? '',
                    playerName: e['player']?.toString() ?? e['name']?.toString() ?? '',
                    secondaryPlayerName: e['assist']?.toString() ?? e['player_out']?.toString(),
                    type: e['type']?.toString() ?? 'goal',
                    isHomeTeam: e['team']?.toString() == 'home' || e['is_home'] == true,
                    score: e['score']?.toString(),
                  ));
                }
              }
            } else if (items is List) {
              for (final e in items) {
                if (e is Map) {
                  events.add(MatchEventEntity(
                    minute: e['minute']?.toString() ?? e['time']?.toString() ?? '',
                    playerName: e['player']?.toString() ?? e['name']?.toString() ?? '',
                    secondaryPlayerName: e['assist']?.toString() ?? e['player_out']?.toString(),
                    type: e['type']?.toString() ?? 'goal',
                    isHomeTeam: e['team']?.toString() == 'home' || e['is_home'] == true,
                    score: e['score']?.toString(),
                  ));
                }
              }
            }
          }
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MatchStatItemEntity>> getStats(String matchId, {required String lang}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchStats(matchId),
        queryParameters: {'lang': lang},
      );

      final stats = <MatchStatItemEntity>[];
      if (response is Map && response['data'] is List) {
        final list = response['data'] as List;
        for (final item in list) {
          if (item is Map) {
            final title = item['title']?.toString() ?? item['name']?.toString() ?? 'Stat';
            final home = item['home']?.toString() ?? item['home_value']?.toString() ?? '0';
            final away = item['away']?.toString() ?? item['away_value']?.toString() ?? '0';

            double homePct = 0.5;
            final hNum = double.tryParse(home.replaceAll('%', ''));
            final aNum = double.tryParse(away.replaceAll('%', ''));
            if (hNum != null && aNum != null && (hNum + aNum) > 0) {
              homePct = hNum / (hNum + aNum);
            }

            stats.add(MatchStatItemEntity(
              title: title,
              homeValue: home,
              awayValue: away,
              homePercentage: homePct.clamp(0.0, 1.0),
            ));
          }
        }
      }
      return stats;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MatchInfoSectionEntity>> getDetails(String matchId, {required String lang, int? utcOffset}) async {
    try {
      final queryParams = <String, dynamic>{'lang': lang};
      if (utcOffset != null) {
        queryParams['utc-offset'] = utcOffset;
      }

      final response = await _client.get(
        ApiEndpoints.matchDetails(matchId),
        queryParameters: queryParams,
      );

      final sections = <MatchInfoSectionEntity>[];
      if (response is Map && response['data'] is List) {
        final list = response['data'] as List;
        for (final sec in list) {
          if (sec is Map) {
            final sectionTitle = sec['section']?.toString() ?? 'Info';
            final itemsRaw = sec['items'] as List? ?? [];
            final items = itemsRaw.map((it) {
              if (it is Map) {
                return MatchInfoItemEntity(
                  title: it['title']?.toString() ?? '',
                  content: it['content']?.toString() ?? it['name']?.toString() ?? '',
                  id: it['id']?.toString(),
                  slug: it['slug']?.toString(),
                  link: it['link']?.toString(),
                );
              }
              return const MatchInfoItemEntity(title: '', content: '');
            }).where((i) => i.title.isNotEmpty || i.content.isNotEmpty).toList();

            sections.add(MatchInfoSectionEntity(
              section: sectionTitle,
              items: items,
            ));
          }
        }
      }
      return sections;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MatchNewsItemEntity>> getNews(String matchId, {required String lang}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchNews(matchId),
        queryParameters: {'lang': lang},
      );

      final newsList = <MatchNewsItemEntity>[];
      if (response is Map && response['data'] is List) {
        final list = response['data'] as List;
        for (final item in list) {
          if (item is Map) {
            newsList.add(MatchNewsItemEntity(
              title: item['title']?.toString() ?? '',
              image: item['image']?.toString(),
              link: item['link']?.toString(),
              date: item['date']?.toString(),
            ));
          }
        }
      }
      return newsList;
    } catch (_) {
      return [];
    }
  }
}
