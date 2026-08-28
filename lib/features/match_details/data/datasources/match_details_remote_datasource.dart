import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/match_minute_parser.dart';
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

      final rawEvents = _extractRawEvents(response);
      final events = <MatchEventEntity>[];

      for (final e in rawEvents) {
        final teamStr = e['team']?.toString().toLowerCase();
        final isHome =
            teamStr == 'team-a' ||
            teamStr == 'team_a' ||
            teamStr == 'team1' ||
            teamStr == 'team-1' ||
            teamStr == 'team_1' ||
            teamStr == 'home' ||
            teamStr == 'home_team' ||
            teamStr == '1' ||
            e['is_home'] == true ||
            e['isHome'] == true;

        final playerName =
            e['text']?.toString() ??
            e['player']?.toString() ??
            e['name']?.toString() ??
            e['player_name']?.toString() ??
            '';

        final secondaryName =
            e['subtitle']?.toString() ??
            e['assist']?.toString() ??
            e['player_out']?.toString() ??
            e['secondary_player']?.toString();

        final rawTime = e['time']?.toString();
        final rawMinute = e['minute']?.toString();

        final parsedMinute = MatchMinuteParser.parse(
          (rawTime != null && rawTime.trim().isNotEmpty) ? rawTime : rawMinute,
        );

        final isStartEnd =
            e['is_start_end'] == true ||
            e['is_start_end'] == 1 ||
            e['type'] == 'start-end-match' ||
            parsedMinute.isPeriodMarker;

        final typeStr =
            e['type']?.toString() ??
            (isStartEnd ? 'start-end-match' : 'event');

        final scoreStr = e['score']?.toString();

        events.add(
          MatchEventEntity(
            minute: parsedMinute.formatted,
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

      return events;
    } catch (_) {
      return [];
    }
  }

  /// Traverses any production API envelope (List, Map, nested items, all_events, flat arrays)
  /// to extract raw event maps without missing items.
  List<Map<String, dynamic>> _extractRawEvents(dynamic json) {
    final results = <Map<String, dynamic>>[];

    void process(dynamic node) {
      if (node == null) return;

      if (node is List) {
        for (final item in node) {
          process(item);
        }
      } else if (node is Map) {
        final map = Map<String, dynamic>.from(node);

        // Check if this map represents an event record
        final hasEventFields =
            map.containsKey('text') ||
            map.containsKey('player') ||
            map.containsKey('player_name') ||
            map.containsKey('time') ||
            map.containsKey('minute') ||
            map.containsKey('is_start_end') ||
            (map.containsKey('type') && map['type'] != 'section');

        if (hasEventFields &&
            !map.containsKey('items') &&
            !map.containsKey('all_events')) {
          results.add(map);
          return;
        }

        // Otherwise traverse nested containers
        if (map.containsKey('data')) {
          process(map['data']);
          return;
        }
        if (map.containsKey('items')) {
          final itemsVal = map['items'];
          if (itemsVal is Map) {
            if (itemsVal['all_events'] is List && (itemsVal['all_events'] as List).isNotEmpty) {
              process(itemsVal['all_events']);
            } else if (itemsVal['featured_events'] is List) {
              process(itemsVal['featured_events']);
            } else {
              process(itemsVal);
            }
          } else {
            process(itemsVal);
          }
          return;
        }
        if (map.containsKey('all_events') && map['all_events'] is List) {
          process(map['all_events']);
          return;
        }
        if (map.containsKey('featured_events') && map['featured_events'] is List) {
          process(map['featured_events']);
          return;
        }
        if (map.containsKey('events')) {
          process(map['events']);
          return;
        }
      }
    }

    process(json);
    return results;
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
            final sectionName =
                entry['section']?.toString() ??
                entry['name']?.toString() ??
                entry['title']?.toString();

            if (entry['items'] is List) {
              final sectionItems = entry['items'] as List;
              for (final it in sectionItems) {
                if (it is Map) {
                  _parseAndAddStatItem(it, stats, category: sectionName);
                }
              }
            } else if (entry.containsKey('title') ||
                entry.containsKey('name') ||
                entry.containsKey('team_a') ||
                entry.containsKey('home')) {
              _parseAndAddStatItem(entry, stats, category: sectionName);
            }
          }
        }
      }
      return stats;
    } catch (_) {
      return [];
    }
  }

  void _parseAndAddStatItem(
    Map item,
    List<MatchStatItemEntity> stats, {
    String? category,
  }) {
    final title =
        item['title']?.toString() ?? item['name']?.toString();

    // Ignore if there is no valid stat title or if it's promotional text
    if (title == null ||
        title.trim().isEmpty ||
        title.trim().toLowerCase() == 'stat' ||
        title.contains('تطبيق') ||
        title.contains('تحميل') ||
        title.contains('يلا شووت') ||
        title.toLowerCase().contains('yalla')) {
      return;
    }

    // Must have at least one stat value field
    if (!item.containsKey('team_a') &&
        !item.containsKey('home') &&
        !item.containsKey('team_a_val') &&
        !item.containsKey('home_value') &&
        !item.containsKey('team_b') &&
        !item.containsKey('away') &&
        !item.containsKey('team_b_val') &&
        !item.containsKey('away_value')) {
      return;
    }

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
        category: category,
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
                    final title = it['title']?.toString() ?? '';
                    final content =
                        it['content']?.toString() ??
                        it['name']?.toString() ??
                        '';

                    String? id =
                        it['id']?.toString() ??
                        it['entity_id']?.toString() ??
                        it['referee_id']?.toString() ??
                        it['stadium_id']?.toString() ??
                        it['commentator_id']?.toString();
                    String? slug =
                        it['slug']?.toString() ?? it['entity_slug']?.toString();
                    final link = it['link']?.toString();

                    String? entityType = _detectEntityType(title, link);

                    // If id or slug are not explicitly present, extract from link if available
                    if (link != null && link.isNotEmpty) {
                      final linkMatch = RegExp(
                        r'/(referee|commentator|stadium)/(\d+)/?([^/?#]*)',
                      ).firstMatch(link);
                      if (linkMatch != null) {
                        entityType ??= linkMatch.group(1);
                        id ??= linkMatch.group(2);
                        final linkSlug = linkMatch.group(3);
                        if (slug == null || slug.isEmpty) {
                          if (linkSlug != null && linkSlug.isNotEmpty) {
                            slug = linkSlug;
                          }
                        }
                      }
                    }

                    // Fallback slug from content if entity is navigable
                    if ((slug == null || slug.isEmpty) && content.isNotEmpty) {
                      slug = content
                          .trim()
                          .toLowerCase()
                          .replaceAll(RegExp(r'\s+'), '-');
                    }

                    return MatchInfoItemEntity(
                      title: title,
                      content: content,
                      entityType: entityType,
                      entityId: id,
                      slug: slug,
                      link: link,
                    );
                  }
                  return const MatchInfoItemEntity(title: '', content: '');
                })
                .where((i) => i.title.isNotEmpty || i.content.isNotEmpty)
                .toList();

            if (items.isNotEmpty) {
              sections.add(
                MatchInfoSectionEntity(section: sectionTitle, items: items),
              );
            }
          }
        }
      }
      return sections;
    } catch (_) {
      return [];
    }
  }

  String? _detectEntityType(String title, String? link) {
    if (link != null && link.isNotEmpty) {
      if (link.contains('/referee/')) return 'referee';
      if (link.contains('/commentator/')) return 'commentator';
      if (link.contains('/stadium/')) return 'stadium';
    }
    final lower = title.toLowerCase();
    if (lower.contains('حكم') || lower.contains('referee')) return 'referee';
    if (lower.contains('معلق') || lower.contains('commentator')) {
      return 'commentator';
    }
    if (lower.contains('ملعب') ||
        lower.contains('stadium') ||
        lower.contains('استاد') ||
        lower.contains('venue')) {
      return 'stadium';
    }
    return null;
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
            final title = item['title']?.toString() ?? '';
            if (title.isNotEmpty) {
              final rawImg = item['image']?.toString();
              final normImg = UrlHelper.normalizeImageUrl(rawImg);

              newsList.add(
                MatchNewsItemEntity(
                  title: title,
                  image: normImg,
                  link: item['link']?.toString(),
                  date: item['date']?.toString(),
                ),
              );
            }
          }
        }
      }
      return newsList;
    } catch (_) {
      return [];
    }
  }
}
