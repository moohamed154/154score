import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/match_details_entity.dart';

abstract class MatchDetailsRemoteDataSource {
  Future<List<MatchEventEntity>> getEvents(
    String matchId, {
    required String lang,
  });
  Future<List<MatchStatItemEntity>> getStats(
    String matchId, {
    required String lang,
  });
  Future<List<MatchInfoSectionEntity>> getDetails(
    String matchId, {
    required String lang,
    int? utcOffset,
  });
  Future<List<MatchNewsItemEntity>> getNews(
    String matchId, {
    required String lang,
  });
}

class MatchDetailsRemoteDataSourceImpl implements MatchDetailsRemoteDataSource {
  final ApiClient _client;

  MatchDetailsRemoteDataSourceImpl(this._client);

  @override
  Future<List<MatchEventEntity>> getEvents(
    String matchId, {
    required String lang,
  }) async {
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
            List rawEventList = [];

            if (items is Map) {
              if (items['all_events'] is List) {
                rawEventList = items['all_events'] as List;
              } else if (items['featured_events'] is List) {
                rawEventList = items['featured_events'] as List;
              }
            } else if (items is List) {
              rawEventList = items;
            }

            for (final e in rawEventList) {
              if (e is Map) {
                final teamStr = e['team']?.toString().toLowerCase();
                final isHome =
                    teamStr == 'team-a' ||
                    teamStr == 'home' ||
                    e['is_home'] == true;

                final playerName =
                    e['text']?.toString() ??
                    e['player']?.toString() ??
                    e['name']?.toString() ??
                    '';

                final secondaryName =
                    e['subtitle']?.toString() ??
                    e['assist']?.toString() ??
                    e['player_out']?.toString();

                final minuteStr =
                    e['time']?.toString() ?? e['minute']?.toString() ?? '';

                final typeStr = e['type']?.toString() ?? 'event';
                final scoreStr = e['score']?.toString();

                events.add(
                  MatchEventEntity(
                    minute: minuteStr,
                    playerName: playerName,
                    secondaryPlayerName:
                        (secondaryName != null && secondaryName.isNotEmpty)
                        ? secondaryName
                        : null,
                    type: typeStr,
                    isHomeTeam: isHome,
                    score: scoreStr,
                  ),
                );
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
  Future<List<MatchStatItemEntity>> getStats(
    String matchId, {
    required String lang,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchStats(matchId),
        queryParameters: {'lang': lang},
      );

      final stats = <MatchStatItemEntity>[];
      if (response is Map && response['data'] is List) {
        final list = response['data'] as List;
        for (final entry in list) {
          if (entry is Map) {
            // Check if entry is a Section containing items
            if (entry['items'] is List) {
              final sectionItems = entry['items'] as List;
              for (final it in sectionItems) {
                if (it is Map) {
                  _parseAndAddStatItem(it, stats);
                }
              }
            } else {
              // Direct flat stat item fallback
              _parseAndAddStatItem(entry, stats);
            }
          }
        }
      }
      return stats;
    } catch (_) {
      return [];
    }
  }

  void _parseAndAddStatItem(Map item, List<MatchStatItemEntity> stats) {
    final title =
        item['title']?.toString() ?? item['name']?.toString() ?? 'Stat';

    final home =
        item['team_a']?.toString() ??
        item['home']?.toString() ??
        item['home_value']?.toString() ??
        '0';

    final away =
        item['team_b']?.toString() ??
        item['away']?.toString() ??
        item['away_value']?.toString() ??
        '0';

    double homePct = 0.5;

    final hNum =
        double.tryParse(item['team_a_val']?.toString() ?? '') ??
        double.tryParse(home.replaceAll('%', '').trim());
    final aNum =
        double.tryParse(item['team_b_val']?.toString() ?? '') ??
        double.tryParse(away.replaceAll('%', '').trim());

    if (hNum != null && aNum != null && (hNum + aNum) > 0) {
      homePct = hNum / (hNum + aNum);
    }
    if (homePct.isNaN || homePct.isInfinite) {
      homePct = 0.5;
    }

    stats.add(
      MatchStatItemEntity(
        title: title,
        homeValue: home,
        awayValue: away,
        homePercentage: homePct.clamp(0.0, 1.0),
      ),
    );
  }

  @override
  Future<List<MatchInfoSectionEntity>> getDetails(
    String matchId, {
    required String lang,
    int? utcOffset,
  }) async {
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
            final items = itemsRaw
                .map((it) {
                  if (it is Map) {
                    return MatchInfoItemEntity(
                      title: it['title']?.toString() ?? '',
                      content:
                          it['content']?.toString() ??
                          it['name']?.toString() ??
                          '',
                      id: it['id']?.toString(),
                      slug: it['slug']?.toString(),
                      link: it['link']?.toString(),
                    );
                  }
                  return const MatchInfoItemEntity(title: '', content: '');
                })
                .where((i) => i.title.isNotEmpty || i.content.isNotEmpty)
                .toList();

            sections.add(
              MatchInfoSectionEntity(section: sectionTitle, items: items),
            );
          }
        }
      }
      return sections;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MatchNewsItemEntity>> getNews(
    String matchId, {
    required String lang,
  }) async {
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
            final rawImg = item['image']?.toString();
            final normImg = UrlHelper.normalizeImageUrl(rawImg);

            newsList.add(
              MatchNewsItemEntity(
                title: item['title']?.toString() ?? '',
                image: normImg,
                link: item['link']?.toString(),
                date: item['date']?.toString(),
              ),
            );
          }
        }
      }
      return newsList;
    } catch (_) {
      return [];
    }
  }
}
