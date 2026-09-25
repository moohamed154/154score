import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/commentator_resolver.dart';
import '../../../../core/utils/match_event_helper.dart';
import '../../../../core/utils/match_minute_parser.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/match_details_entity.dart';

abstract class MatchDetailsRemoteDataSource {
  Future<List<MatchEventEntity>> getEvents(
    String matchId, {
    required String lang,
  });
  Future<MatchEventsPayload> getEventsPayload(
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
  Future<MatchDetailsPayload> getDetailsPayload(
    String matchId, {
    required String lang,
    int? utcOffset,
  });
  Future<List<MatchNewsItemEntity>> getNews(
    String matchId, {
    required String lang,
  });
  Future<MatchLineupEntity?> getLineups(String matchId, {required String lang});
}

class MatchDetailsRemoteDataSourceImpl implements MatchDetailsRemoteDataSource {
  final ApiClient _client;

  MatchDetailsRemoteDataSourceImpl(this._client);

  static String _cleanMatchId(String id) =>
      Uri.decodeComponent(id).replaceAll('match:', '').trim();

  @override
  Future<MatchEventsPayload> getEventsPayload(
    String matchId, {
    required String lang,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    return await _fetchEventsPayload(cleanId, lang: lang);
  }

  @override
  Future<List<MatchEventEntity>> getEvents(
    String matchId, {
    required String lang,
  }) async {
    final payload = await getEventsPayload(matchId, lang: lang);
    return payload.events;
  }

  Future<MatchEventsPayload> _fetchEventsPayload(
    String cleanId, {
    required String lang,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchEvents(cleanId),
        queryParameters: {'lang': lang},
      );

      dynamic parsed = response;
      if (parsed is String && parsed.trim().isNotEmpty) {
        try {
          parsed = jsonDecode(parsed);
        } catch (_) {}
      }

      final videos = MatchVideosEntity.fromJson(parsed, isArabic: lang != 'en');

      String? championshipId;
      Map<String, dynamic>? halfScores;

      if (parsed is List && parsed.isNotEmpty) {
        final first = parsed[0];
        if (first is Map && first['items'] is Map) {
          final items = first['items'] as Map;
          championshipId = items['championship_id']?.toString();
          if (items['half_scores'] is Map) {
            halfScores = Map<String, dynamic>.from(items['half_scores'] as Map);
          }
        }
      } else if (parsed is Map) {
        final data = parsed['data'] ?? parsed;
        if (data is Map) {
          championshipId =
              data['championship_id']?.toString() ??
              data['championship']?['url_id']?.toString();
          if (data['half_scores'] is Map) {
            halfScores = Map<String, dynamic>.from(data['half_scores'] as Map);
          }
        }
      }

      final rawEvents = _extractRawEvents(parsed);
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

        final rawPlayer = e['player_name'] ?? e['player'];
        String playerName;
        int? playerNum;
        String? playerPhoto;
        String? playerShortName;
        if (rawPlayer is Map) {
          playerName =
              rawPlayer['title']?.toString() ??
              rawPlayer['name']?.toString() ??
              '';
          playerNum = int.tryParse(rawPlayer['pn']?.toString() ?? '');
          playerPhoto = UrlHelper.normalizePlayerPhotoUrl(
            rawPlayer['image']?.toString() ?? rawPlayer['id']?.toString(),
          );
          playerShortName = rawPlayer['short_title']?.toString();
        } else {
          playerName =
              e['text']?.toString() ??
              e['player']?.toString() ??
              e['name']?.toString() ??
              rawPlayer?.toString() ??
              '';
          playerNum = int.tryParse(e['player_number']?.toString() ?? '');
          playerPhoto = UrlHelper.normalizePlayerPhotoUrl(
            e['player_photo']?.toString() ?? e['player_id']?.toString(),
          );
          playerShortName = e['player_short_name']?.toString();
        }

        final rawAssist = e['assist_player_name'] ?? e['assist'];
        String? secondaryName;
        int? secondaryNum;
        String? secondaryPhoto;
        String? secondaryShortName;
        if (rawAssist is Map) {
          secondaryName =
              rawAssist['title']?.toString() ?? rawAssist['name']?.toString();
          secondaryNum = int.tryParse(rawAssist['pn']?.toString() ?? '');
          secondaryPhoto = UrlHelper.normalizePlayerPhotoUrl(
            rawAssist['image']?.toString() ?? rawAssist['id']?.toString(),
          );
          secondaryShortName = rawAssist['short_title']?.toString();
        } else {
          secondaryName =
              e['subtitle']?.toString() ??
              rawAssist?.toString() ??
              e['player_out']?.toString() ??
              e['secondary_player']?.toString();
          secondaryNum = int.tryParse(
            e['assist_player_number']?.toString() ?? '',
          );
          secondaryPhoto = UrlHelper.normalizePlayerPhotoUrl(
            e['assist_player_photo']?.toString() ??
                e['substitute_out_photo']?.toString() ??
                e['assist_player_id']?.toString(),
          );
          secondaryShortName = e['assist_player_short_name']?.toString();
        }

        final rawTime = e['time']?.toString();
        final rawMinute = e['minute']?.toString();

        final parsedMinute = MatchMinuteParser.parse(
          (rawTime != null && rawTime.trim().isNotEmpty) ? rawTime : rawMinute,
        );

        final isPeriodMarker =
            e['is_period_marker'] == true || parsedMinute.isPeriodMarker;

        final isStartEnd =
            e['is_start_end'] == true ||
            e['is_start_end'] == 1 ||
            e['type'] == 'start-end-match' ||
            isPeriodMarker;

        if (isStartEnd || isPeriodMarker) {
          final statusVal = int.tryParse(e['status']?.toString() ?? '');
          final minuteVal = parsedMinute.mainMinute;
          if (statusVal == 1 ||
              (minuteVal == 0 &&
                  (playerName.isEmpty || playerName == 'نهاية الشوط'))) {
            playerName = 'بداية الشوط الأول';
          } else if (statusVal == 2) {
            playerName = 'نهاية الشوط الأول';
          } else if (statusVal == 3) {
            playerName = 'بداية الشوط الثاني';
          } else if (statusVal == 4 ||
              (minuteVal >= 90 && playerName == 'نهاية الشوط')) {
            playerName = 'نهاية المباراة';
          } else if (statusVal == 5) {
            playerName = 'بداية الشوط الإضافي الأول';
          } else if (statusVal == 6) {
            playerName = 'نهاية الشوط الإضافي الأول';
          } else if (statusVal == 7) {
            playerName = 'بداية الشوط الإضافي الثاني';
          } else if (statusVal == 8) {
            playerName = 'نهاية الشوط الإضافي الثاني';
          } else if (statusVal == 9) {
            playerName = 'ركلات الترجيح';
          }
        }

        final typeStr =
            e['type']?.toString() ?? (isStartEnd ? 'start-end-match' : 'event');

        final scoreStr = e['score']?.toString();

        final rawVideoUrl =
            e['video_url']?.toString() ??
            e['videoUrl']?.toString() ??
            e['video']?.toString() ??
            (e['video'] is Map ? e['video']['url']?.toString() : null);
        final videoUrl =
            (rawVideoUrl != null &&
                rawVideoUrl.trim().isNotEmpty &&
                rawVideoUrl.trim() != 'null' &&
                rawVideoUrl.trim() != 'undefined')
            ? rawVideoUrl.trim()
            : null;

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
            videoUrl: videoUrl,
            playerNumber: playerNum,
            playerPhoto: playerPhoto,
            playerShortName: playerShortName,
            secondaryPlayerNumber: secondaryNum,
            secondaryPlayerPhoto: secondaryPhoto,
            secondaryPlayerShortName: secondaryShortName,
            isPeriodMarker: isPeriodMarker,
          ),
        );
      }

      final normalizedEvents = MatchEventHelper.normalizeEvents(
        events,
        hasExtraTime: MatchEventHelper.hasExtraTimeInHalfScores(halfScores),
      );

      return MatchEventsPayload(
        events: normalizedEvents,
        videos: videos,
        championshipId: championshipId,
        halfScores: halfScores,
      );
    } catch (_) {
      return const MatchEventsPayload();
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
            if (itemsVal['all_events'] is List &&
                (itemsVal['all_events'] as List).isNotEmpty) {
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
        if (map.containsKey('featured_events') &&
            map['featured_events'] is List) {
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
    final cleanId = _cleanMatchId(matchId);
    return await _fetchStats(cleanId, lang: lang);
  }

  Future<List<MatchStatItemEntity>> _fetchStats(
    String cleanId, {
    required String lang,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchStats(cleanId),
        queryParameters: {'lang': lang},
      );

      dynamic parsed = response;
      if (parsed is String && parsed.trim().isNotEmpty) {
        try {
          parsed = jsonDecode(parsed);
        } catch (_) {}
      }

      final stats = <MatchStatItemEntity>[];
      List? entries;
      if (parsed is List) {
        entries = parsed;
      } else if (parsed is Map) {
        if (parsed['data'] is List) {
          entries = parsed['data'] as List;
        } else if (parsed['data'] is Map) {
          final dataMap = parsed['data'] as Map;
          if (dataMap['items'] is List) {
            entries = dataMap['items'] as List;
          } else if (dataMap['stats'] is List) {
            entries = dataMap['stats'] as List;
          } else if (dataMap['sections'] is List) {
            entries = dataMap['sections'] as List;
          } else {
            entries = dataMap.values
                .whereType<List>()
                .expand((x) => x)
                .toList();
          }
        } else if (parsed['items'] is List) {
          entries = parsed['items'] as List;
        } else if (parsed['stats'] is List) {
          entries = parsed['stats'] as List;
        }
      }

      if (entries != null) {
        for (final entry in entries) {
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
                entry.containsKey('home') ||
                entry.containsKey('home_value')) {
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
    final title = item['title']?.toString() ?? item['name']?.toString();

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
        !item.containsKey('team1') &&
        !item.containsKey('team_1') &&
        !item.containsKey('home_val') &&
        !item.containsKey('val1') &&
        !item.containsKey('value1') &&
        !item.containsKey('team_b') &&
        !item.containsKey('away') &&
        !item.containsKey('team_b_val') &&
        !item.containsKey('away_value') &&
        !item.containsKey('team2') &&
        !item.containsKey('team_2') &&
        !item.containsKey('away_val') &&
        !item.containsKey('val2') &&
        !item.containsKey('value2')) {
      return;
    }

    final home =
        item['team_a']?.toString() ??
        item['home']?.toString() ??
        item['home_value']?.toString() ??
        item['team1']?.toString() ??
        item['team_1']?.toString() ??
        item['home_val']?.toString() ??
        item['val1']?.toString() ??
        item['value1']?.toString() ??
        '0';

    final away =
        item['team_b']?.toString() ??
        item['away']?.toString() ??
        item['away_value']?.toString() ??
        item['team2']?.toString() ??
        item['team_2']?.toString() ??
        item['away_val']?.toString() ??
        item['val2']?.toString() ??
        item['value2']?.toString() ??
        '0';

    double homePct = 0.5;

    if (item.containsKey('home_percentage') &&
        item['home_percentage'] != null) {
      final p = double.tryParse(
        item['home_percentage'].toString().replaceAll('%', '').trim(),
      );
      if (p != null) {
        homePct = p > 1.0 ? p / 100.0 : p;
      }
    } else {
      final hNum =
          double.tryParse(item['team_a_val']?.toString() ?? '') ??
          double.tryParse(item['team1_val']?.toString() ?? '') ??
          double.tryParse(home.replaceAll('%', '').trim());
      final aNum =
          double.tryParse(item['team_b_val']?.toString() ?? '') ??
          double.tryParse(item['team2_val']?.toString() ?? '') ??
          double.tryParse(away.replaceAll('%', '').trim());

      if (hNum != null && aNum != null && (hNum + aNum) > 0) {
        homePct = hNum / (hNum + aNum);
      }
    }
    if (homePct.isNaN || homePct.isInfinite) {
      homePct = 0.5;
    }

    final resolvedCategory =
        category ?? item['category']?.toString() ?? item['section']?.toString();

    stats.add(
      MatchStatItemEntity(
        title: title,
        homeValue: home,
        awayValue: away,
        homePercentage: homePct.clamp(0.0, 1.0),
        category: resolvedCategory,
      ),
    );
  }

  @override
  Future<List<MatchInfoSectionEntity>> getDetails(
    String matchId, {
    required String lang,
    int? utcOffset,
  }) async {
    final payload = await getDetailsPayload(
      matchId,
      lang: lang,
      utcOffset: utcOffset,
    );
    return payload.sections;
  }

  @override
  Future<MatchDetailsPayload> getDetailsPayload(
    String matchId, {
    required String lang,
    int? utcOffset,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    try {
      final queryParams = <String, dynamic>{'lang': lang};
      if (utcOffset != null) {
        queryParams['utc-offset'] = utcOffset.toString();
      }

      final response = await _client.get(
        ApiEndpoints.matchDetails(cleanId),
        queryParameters: queryParams,
      );

      final sections = <MatchInfoSectionEntity>[];
      List? rawSectionsList;
      dynamic rawOverview;

      if (response is Map) {
        if (response['data'] is List) {
          rawSectionsList = response['data'] as List;
        } else if (response['data'] is Map) {
          final d = response['data'] as Map;
          if (d['sections'] is List) {
            rawSectionsList = d['sections'] as List;
          }
          rawOverview = d['overview'] ?? response['overview'];
        }
        rawOverview ??= response['overview'];
      } else if (response is List) {
        rawSectionsList = response;
      }

      if (rawSectionsList != null) {
        for (final sec in rawSectionsList) {
          if (sec is Map) {
            final sectionTitle = sec['section']?.toString() ?? 'Info';
            final itemsRaw = sec['items'] as List? ?? [];
            final items = itemsRaw
                .map((it) {
                  if (it is Map) {
                    final title = it['title']?.toString() ?? '';
                    final content =
                        it['content']?.toString() ??
                        it['value']?.toString() ??
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

                    String? entityType =
                        it['type']?.toString() ??
                        it['entity_type']?.toString() ??
                        _detectEntityType(title, link);

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
                      slug = content.trim().toLowerCase().replaceAll(
                        RegExp(r'\s+'),
                        '-',
                      );
                    }

                    // Resolve known commentators when backend omits id/slug
                    if (entityType == 'commentator' &&
                        (id == null || id.isEmpty || id == '0')) {
                      final resolvedId =
                          CommentatorResolver.resolveId(content) ??
                          CommentatorResolver.resolveId(slug);
                      if (resolvedId != null) {
                        id = resolvedId;
                        slug = CommentatorResolver.getSlug(resolvedId);
                      }
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

      final overview = _parseOverview(rawOverview, cleanId, sections);

      return MatchDetailsPayload(sections: sections, overview: overview);
    } catch (_) {
      return const MatchDetailsPayload();
    }
  }

  MatchOverviewDataEntity? _parseOverview(
    dynamic rawOverview,
    String matchId,
    List<MatchInfoSectionEntity> sections,
  ) {
    if (rawOverview is Map) {
      final map = Map<String, dynamic>.from(rawOverview);
      final (secHome, secAway) = _extractTeamNamesFromSections(sections);

      MatchReturnLegEntity? returnLeg;
      if (map['return_match'] is Map) {
        final r = map['return_match'] as Map;
        final scoreParts = (r['result']?.toString() ?? '').split('-');
        final hScore =
            int.tryParse(r['home_scores']?.toString() ?? '') ??
            (scoreParts.length == 2
                ? int.tryParse(scoreParts[0].trim()) ?? 0
                : 0);
        final aScore =
            int.tryParse(r['away_scores']?.toString() ?? '') ??
            (scoreParts.length == 2
                ? int.tryParse(scoreParts[1].trim()) ?? 0
                : 0);
        final rHome = (r['home_team']?.toString().trim().isNotEmpty == true)
            ? r['home_team']!.toString()
            : (secAway ?? '');
        final rAway = (r['away_team']?.toString().trim().isNotEmpty == true)
            ? r['away_team']!.toString()
            : (secHome ?? '');
        returnLeg = MatchReturnLegEntity(
          matchId: r['match_id']?.toString() ?? r['id']?.toString() ?? '',
          homeTeam: rHome,
          awayTeam: rAway,
          homeScores: hScore,
          awayScores: aScore,
          aggResult:
              r['agg_result']?.toString() ?? map['agg_result']?.toString(),
          penalties: r['penalties']?.toString() ?? map['penalties']?.toString(),
        );
      }

      MatchH2HSummaryEntity? h2hSummary;
      if (map['team_wins'] is Map) {
        final tw = map['team_wins'] as Map;
        h2hSummary = MatchH2HSummaryEntity(
          homeWins:
              int.tryParse(
                tw['team1_wins']?.toString() ??
                    tw['home_wins']?.toString() ??
                    '',
              ) ??
              0,
          awayWins:
              int.tryParse(
                tw['team2_wins']?.toString() ??
                    tw['away_wins']?.toString() ??
                    '',
              ) ??
              0,
          draws: int.tryParse(tw['draws']?.toString() ?? '') ?? 0,
          homeTeamName:
              tw['home_team_name']?.toString() ??
              tw['team1_name']?.toString() ??
              map['home_team']?['name']?.toString() ??
              map['home_team']?['title']?.toString() ??
              secHome,
          awayTeamName:
              tw['away_team_name']?.toString() ??
              tw['team2_name']?.toString() ??
              map['away_team']?['name']?.toString() ??
              map['away_team']?['title']?.toString() ??
              secAway,
        );
      }

      MatchRecentFormEntity? recentForm;
      if (map['played_result'] is Map) {
        final pr = map['played_result'] as Map;
        final homeList = <MatchFormItemEntity>[];
        final awayList = <MatchFormItemEntity>[];

        final rawHome = pr['home'];
        final homeMatches = rawHome is Map
            ? (rawHome['matches'] as List? ?? [])
            : (rawHome is List ? rawHome : []);
        final homeTeamName =
            (rawHome is Map ? rawHome['team_name']?.toString() : null) ??
            map['home_team']?['name']?.toString();

        final rawAway = pr['away'];
        final awayMatches = rawAway is Map
            ? (rawAway['matches'] as List? ?? [])
            : (rawAway is List ? rawAway : []);
        final awayTeamName =
            (rawAway is Map ? rawAway['team_name']?.toString() : null) ??
            map['away_team']?['name']?.toString();

        for (final item in homeMatches) {
          if (item is Map) {
            final res =
                item['result']?.toString() ??
                item['win_type']?.toString() ??
                'equal';
            homeList.add(
              MatchFormItemEntity(
                matchId:
                    item['match_id']?.toString() ??
                    item['id']?.toString() ??
                    '',
                opponentName:
                    item['opponent_name']?.toString() ??
                    item['away_team']?.toString() ??
                    item['home_team']?.toString() ??
                    '',
                opponentLogo:
                    item['opponent_logo']?.toString() ??
                    item['away_logo']?.toString() ??
                    item['home_logo']?.toString(),
                score:
                    item['score']?.toString() ??
                    '${item['home_scores'] ?? 0} - ${item['away_scores'] ?? 0}',
                winType: res,
                isHome: true,
              ),
            );
          }
        }

        for (final item in awayMatches) {
          if (item is Map) {
            final res =
                item['result']?.toString() ??
                item['win_type']?.toString() ??
                'equal';
            awayList.add(
              MatchFormItemEntity(
                matchId:
                    item['match_id']?.toString() ??
                    item['id']?.toString() ??
                    '',
                opponentName:
                    item['opponent_name']?.toString() ??
                    item['home_team']?.toString() ??
                    item['away_team']?.toString() ??
                    '',
                opponentLogo:
                    item['opponent_logo']?.toString() ??
                    item['home_logo']?.toString() ??
                    item['away_logo']?.toString(),
                score:
                    item['score']?.toString() ??
                    '${item['home_scores'] ?? 0} - ${item['away_scores'] ?? 0}',
                winType: res,
                isHome: false,
              ),
            );
          }
        }

        if (homeList.isNotEmpty || awayList.isNotEmpty) {
          recentForm = MatchRecentFormEntity(
            homeMatches: homeList,
            awayMatches: awayList,
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
          );
        }
      }

      MatchQuickStatsEntity? quickStats;
      if (map['quick_stats'] is Map) {
        final qs = map['quick_stats'] as Map;
        final home = qs['home'] is Map ? qs['home'] as Map : null;
        final away = qs['away'] is Map ? qs['away'] as Map : null;
        quickStats = MatchQuickStatsEntity(
          homePossession:
              qs['possession_home']?.toString() ??
              home?['ball_possession']?.toString(),
          awayPossession:
              qs['possession_away']?.toString() ??
              away?['ball_possession']?.toString(),
          homeShots: int.tryParse(
            qs['shots_home']?.toString() ??
                home?['total_shots']?.toString() ??
                '',
          ),
          awayShots: int.tryParse(
            qs['shots_away']?.toString() ??
                away?['total_shots']?.toString() ??
                '',
          ),
          homeFouls: int.tryParse(
            qs['fouls_home']?.toString() ?? home?['fouls']?.toString() ?? '',
          ),
          awayFouls: int.tryParse(
            qs['fouls_away']?.toString() ?? away?['fouls']?.toString() ?? '',
          ),
          homeOffsides: int.tryParse(
            qs['offsides_home']?.toString() ??
                home?['offsides']?.toString() ??
                '',
          ),
          awayOffsides: int.tryParse(
            qs['offsides_away']?.toString() ??
                away?['offsides']?.toString() ??
                '',
          ),
        );
      }

      final referees = <MatchRefereeItemEntity>[];
      if (map['referees'] is List) {
        for (final r in map['referees']) {
          if (r is Map) {
            referees.add(
              MatchRefereeItemEntity(
                id: r['id']?.toString(),
                name: r['name']?.toString() ?? '',
                role: r['role']?.toString() ?? '',
              ),
            );
          }
        }
      }

      final homeName =
          map['home_team']?['name']?.toString() ??
          map['home_team']?['title']?.toString() ??
          map['home_team']?['full_name']?.toString() ??
          secHome;
      final awayName =
          map['away_team']?['name']?.toString() ??
          map['away_team']?['title']?.toString() ??
          map['away_team']?['full_name']?.toString() ??
          secAway;
      final homeLogo = UrlHelper.normalizeImageUrl(
        map['home_team']?['logo']?.toString() ??
            map['home_team']?['image']?.toString(),
      );
      final awayLogo = UrlHelper.normalizeImageUrl(
        map['away_team']?['logo']?.toString() ??
            map['away_team']?['image']?.toString(),
      );
      final homeId =
          map['home_team']?['id']?.toString() ??
          map['home_team']?['row_id']?.toString();
      final awayId =
          map['away_team']?['id']?.toString() ??
          map['away_team']?['row_id']?.toString();

      final champId =
          map['championship']?['id']?.toString() ??
          map['championship']?['url_id']?.toString();
      final champTitle =
          map['championship']?['title']?.toString() ??
          map['championship']?['name']?.toString();
      final champLogo =
          UrlHelper.normalizeImageUrl(
            map['championship']?['image']?.toString() ??
                map['championship']?['logo']?.toString(),
          ) ??
          UrlHelper.resolveChampionshipLogo(champId);

      final score1 =
          map['home_scores']?.toString() ?? map['score1']?.toString();
      final score2 =
          map['away_scores']?.toString() ?? map['score2']?.toString();
      final status = map['status']?.toString();
      final time = map['time']?.toString();
      final date = map['date']?.toString();
      final round = map['round']?.toString();

      return MatchOverviewDataEntity(
        matchId: matchId,
        homeTeamName: homeName,
        awayTeamName: awayName,
        homeTeamLogo: homeLogo,
        awayTeamLogo: awayLogo,
        homeTeamId: homeId,
        awayTeamId: awayId,
        championshipId: champId,
        championshipTitle: champTitle,
        championshipLogo: champLogo,
        score1: score1,
        score2: score2,
        status: status,
        time: time,
        date: date,
        round: round,
        stadiumName: map['venue']?['name']?.toString(),
        stadiumId: map['venue']?['id']?.toString(),
        returnLeg: returnLeg,
        h2hSummary: h2hSummary,
        recentForm: recentForm,
        quickStats: quickStats,
        referees: referees,
      );
    }

    // Fallback: extract from enriched sections
    return _extractOverviewFromSections(sections, matchId);
  }

  static (String? home, String? away) _extractTeamNamesFromSections(
    List<MatchInfoSectionEntity> sections,
  ) {
    String? home;
    String? away;
    for (final sec in sections) {
      for (final it in sec.items) {
        final t = it.title.trim().toLowerCase();
        if (t.contains('صاحب الأرض') ||
            t.contains('صاحب الارض') ||
            t.contains('المضيف') ||
            t.contains('الفريق الأول') ||
            t.contains('home')) {
          home ??= it.content.trim();
        } else if (t == 'الضيف' ||
            t.contains('الفريق الضيف') ||
            t.contains('الفريق الثاني') ||
            t.contains('away')) {
          away ??= it.content.trim();
        }
      }
    }
    return (home, away);
  }

  MatchOverviewDataEntity? _extractOverviewFromSections(
    List<MatchInfoSectionEntity> sections,
    String matchId,
  ) {
    if (sections.isEmpty) return null;
    final (secHome, secAway) = _extractTeamNamesFromSections(sections);

    MatchH2HSummaryEntity? h2h;
    final h2hSec = sections.firstWhere(
      (s) =>
          s.section.contains('المواجهات المباشرة') ||
          s.section.toLowerCase().contains('head-to-head'),
      orElse: () => const MatchInfoSectionEntity(section: '', items: []),
    );
    if (h2hSec.items.length >= 3) {
      h2h = MatchH2HSummaryEntity(
        homeWins: int.tryParse(h2hSec.items[0].content) ?? 0,
        draws: int.tryParse(h2hSec.items[1].content) ?? 0,
        awayWins: int.tryParse(h2hSec.items[2].content) ?? 0,
        homeTeamName: secHome,
        awayTeamName: secAway,
      );
    }

    MatchReturnLegEntity? returnLeg;
    for (final sec in sections) {
      for (final it in sec.items) {
        if (it.title.contains('الذهاب') ||
            it.title.toLowerCase().contains('leg')) {
          String rHome = secAway ?? '';
          String rAway = secHome ?? '';
          int rHScore = 0;
          int rAScore = 0;

          // Parse e.g. "غريميو 5 - 3 بوتافوغو" or "5 - 3"
          final match = RegExp(r'^(.+?)\s+(\d+)\s*[-–:]\s*(\d+)\s+(.+)$')
              .firstMatch(it.content.trim());
          if (match != null) {
            rHome = match.group(1)?.trim() ?? rHome;
            rHScore = int.tryParse(match.group(2) ?? '') ?? 0;
            rAScore = int.tryParse(match.group(3) ?? '') ?? 0;
            rAway = match.group(4)?.trim() ?? rAway;
          } else {
            final scoreMatch = RegExp(r'(\d+)\s*[-–:]\s*(\d+)')
                .firstMatch(it.content.trim());
            if (scoreMatch != null) {
              rHScore = int.tryParse(scoreMatch.group(1) ?? '') ?? 0;
              rAScore = int.tryParse(scoreMatch.group(2) ?? '') ?? 0;
            }
          }

          returnLeg = MatchReturnLegEntity(
            matchId: it.entityId ?? '',
            homeTeam: rHome,
            awayTeam: rAway,
            homeScores: rHScore,
            awayScores: rAScore,
            aggResult: it.content,
          );
          break;
        }
      }
      if (returnLeg != null) break;
    }

    String? time;
    String? date;
    String? champTitle;
    String? champId;
    String? round;
    String? stadiumName;
    String? stadiumId;
    String? status;

    final infoSec = sections.firstWhere(
      (s) =>
          s.section.contains('معلومات اللقاء') ||
          s.section.contains('معلومات المباراة') ||
          s.section.toLowerCase().contains('match info'),
      orElse: () => const MatchInfoSectionEntity(section: '', items: []),
    );
    for (final item in infoSec.items) {
      final t = item.title.trim().toLowerCase();
      if (t.contains('وقت') || t.contains('time')) {
        time ??= item.content.trim();
      } else if (t.contains('تاريخ') || t.contains('date')) {
        date ??= item.content.trim();
      } else if (t.contains('بطولة') ||
          t.contains('دوري') ||
          t.contains('league') ||
          t.contains('championship')) {
        champTitle ??= item.content.trim();
        champId ??=
            item.entityId ??
            item.link
                ?.split('/')
                .lastWhere((e) => e.isNotEmpty, orElse: () => '');
      } else if (t.contains('جولة') || t.contains('round')) {
        round ??= item.content.trim();
      } else if (t.contains('ملعب') ||
          t.contains('استاد') ||
          t.contains('stadium') ||
          t.contains('venue')) {
        stadiumName ??= item.content.trim();
        stadiumId ??= item.entityId;
      } else if (t.contains('حالة') || t.contains('status')) {
        status ??= item.content.trim();
      }
    }

    return MatchOverviewDataEntity(
      matchId: matchId,
      homeTeamName: secHome,
      awayTeamName: secAway,
      h2hSummary: h2h,
      returnLeg: returnLeg,
      time: time,
      date: date,
      championshipTitle: champTitle,
      championshipId: champId,
      championshipLogo: champId != null
          ? UrlHelper.resolveChampionshipLogo(champId)
          : null,
      round: round,
      stadiumName: stadiumName,
      stadiumId: stadiumId,
      status: status,
    );
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
    final cleanId = _cleanMatchId(matchId);
    try {
      final response = await _client.get(
        ApiEndpoints.matchNews(cleanId),
        queryParameters: {'lang': lang},
      );

      var newsList = _parseNewsResponse(response);

      // Fallback: If match-specific news is empty, fetch general news
      if (newsList.isEmpty) {
        try {
          final generalResponse = await _client.get(
            ApiEndpoints.news,
            queryParameters: {'lang': lang},
          );
          newsList = _parseNewsResponse(generalResponse);
        } catch (_) {}
      }

      return newsList;
    } catch (_) {
      try {
        final generalResponse = await _client.get(
          ApiEndpoints.news,
          queryParameters: {'lang': lang},
        );
        return _parseNewsResponse(generalResponse);
      } catch (_) {
        return [];
      }
    }
  }

  static List<MatchNewsItemEntity> _parseNewsResponse(dynamic response) {
    dynamic parsed = response;
    if (parsed is String && parsed.trim().isNotEmpty) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {}
    }

    final rawItems = <Map<String, dynamic>>[];

    void extractArticles(dynamic node) {
      if (node == null) return;
      if (node is List) {
        for (final item in node) {
          extractArticles(item);
        }
      } else if (node is Map) {
        final map = Map<String, dynamic>.from(node);

        // If this is a section wrapper: { "section": "...", "items": [...] }
        if (map.containsKey('items')) {
          extractArticles(map['items']);
          return;
        }

        // If this is an envelope: { "data": [...] }
        if (map.containsKey('data')) {
          extractArticles(map['data']);
          return;
        }

        final title =
            (map['title']?.toString() ??
                    map['news_title']?.toString() ??
                    map['name']?.toString() ??
                    '')
                .trim();
        final link = (map['url'] ?? map['link'])?.toString() ?? '';

        final isDownloadPromo =
            title.contains('تحميل تطبيق يلا شووت') ||
            title.contains('تحميل تطبيق يلا شوت') ||
            title.contains('تحميل تطبيق يلاشووت') ||
            title.contains('تحميل تطبيق') ||
            title.toLowerCase().contains('download yalla shoot') ||
            title.toLowerCase().contains('download-yalla-shoot') ||
            title.toLowerCase().contains('download ysscores') ||
            title.toLowerCase().contains('download-ysscores') ||
            link.toLowerCase().contains('download-yalla-shoot') ||
            link.toLowerCase().contains('download-ysscores') ||
            link.toLowerCase().contains('download-app');

        if (title.isNotEmpty && !isDownloadPromo) {
          rawItems.add(map);
        }
      }
    }

    extractArticles(parsed);

    final newsList = <MatchNewsItemEntity>[];
    final seenTitles = <String>{};

    for (final item in rawItems) {
      final title =
          (item['title']?.toString() ??
                  item['news_title']?.toString() ??
                  item['name']?.toString() ??
                  '')
              .trim();

      if (title.isEmpty || seenTitles.contains(title)) continue;
      seenTitles.add(title);

      final rawImg =
          item['image']?.toString() ??
          item['thumbnail']?.toString() ??
          item['img']?.toString();
      final normImg = UrlHelper.normalizeImageUrl(rawImg);

      final link =
          item['url']?.toString() ??
          item['link']?.toString() ??
          (item['article_id'] != null ? '/news/${item['article_id']}' : null);

      final date =
          item['published_at']?.toString() ??
          item['date']?.toString() ??
          item['time']?.toString() ??
          item['created_at']?.toString();

      final description =
          item['description']?.toString() ??
          item['summary']?.toString() ??
          item['news_desc']?.toString();

      final rawArticleId =
          item['article_id']?.toString() ?? item['id']?.toString();
      final rawSlug = item['slug']?.toString();
      final parsed = UrlHelper.parseNewsUrl(rawArticleId ?? link);
      final articleId = rawArticleId ?? parsed.id;
      final slug = rawSlug ?? parsed.slug;

      newsList.add(
        MatchNewsItemEntity(
          title: title,
          image: normImg,
          link: link,
          date: date,
          description: description,
          articleId: articleId,
          slug: slug,
        ),
      );
    }

    return newsList;
  }

  @override
  Future<MatchLineupEntity?> getLineups(
    String matchId, {
    required String lang,
  }) async {
    final cleanId = _cleanMatchId(matchId);
    try {
      final response = await _client.get(
        ApiEndpoints.matchLineups(cleanId),
        queryParameters: {'lang': lang},
      );

      final Map<String, dynamic>? dataMap;
      if (response is Map) {
        if (response['data'] is Map) {
          dataMap = Map<String, dynamic>.from(response['data'] as Map);
        } else {
          dataMap = Map<String, dynamic>.from(response);
        }
      } else {
        dataMap = null;
      }

      if (dataMap == null) return null;

      final mId = dataMap['match_id']?.toString() ?? matchId;
      final available = dataMap['lineups_available'] == true;
      String? formType = dataMap['formation_type']?.toString();
      int? formTypeId = int.tryParse(
        dataMap['formation_type_id']?.toString() ??
            dataMap['type_formation']?.toString() ??
            '',
      );
      String? formTypeText = dataMap['formation_type_text']?.toString();

      TeamLineupEntity? homeLineup = _parseTeamLineup(dataMap['home']);
      TeamLineupEntity? awayLineup = _parseTeamLineup(dataMap['away']);

      // Auto-heal missing players (e.g. striker skipped by upstream scraper)
      if (available &&
          ((homeLineup != null &&
                  homeLineup.startingXi.length >= 8 &&
                  homeLineup.startingXi.length < 11) ||
              (awayLineup != null &&
                  awayLineup.startingXi.length >= 8 &&
                  awayLineup.startingXi.length < 11))) {
        final healed = await _healMissingLineupPlayers(
          matchId: mId,
          lang: lang,
          home: homeLineup,
          away: awayLineup,
        );
        homeLineup = healed.$1;
        awayLineup = healed.$2;
      }

      final hasSubstitutes =
          (homeLineup?.substitutes.isNotEmpty ?? false) ||
          (awayLineup?.substitutes.isNotEmpty ?? false);

      final bool isConfirmed;
      if (dataMap['is_confirmed'] == false ||
          formTypeId == 2 ||
          formType?.toLowerCase() == 'probable' ||
          formType?.toLowerCase() == 'predicted' ||
          dataMap['type_formation'] == 2) {
        isConfirmed = false;
        formTypeId ??= 2;
        formType = 'probable';
        formTypeText = (lang == 'en') ? 'Probable Lineup' : 'تشكيلة متوقعة';
      } else if (!hasSubstitutes) {
        // Lineup with 0 substitutes on both teams is a probable/expected lineup
        isConfirmed = false;
        formTypeId = 2;
        formType = 'probable';
        formTypeText = (lang == 'en') ? 'Probable Lineup' : 'تشكيلة متوقعة';
      } else {
        final bool rawConfirmed =
            (dataMap['is_confirmed'] as bool?) ??
            (formTypeId == 0 || formType?.toLowerCase() == 'confirmed');
        if (rawConfirmed) {
          isConfirmed = true;
          formTypeId ??= 0;
          formType = 'confirmed';
          formTypeText = (lang == 'en') ? 'Confirmed Lineup' : 'تشكيلة مؤكدة';
        } else {
          isConfirmed = false;
          formTypeId = 2;
          formType = 'probable';
          formTypeText = (lang == 'en') ? 'Probable Lineup' : 'تشكيلة متوقعة';
        }
      }

      return MatchLineupEntity(
        matchId: mId,
        lineupsAvailable: available,
        formationType: formType,
        formationTypeId: formTypeId,
        formationTypeText: formTypeText,
        isConfirmed: isConfirmed,
        home: homeLineup,
        away: awayLineup,
      );
    } catch (_) {
      return null;
    }
  }

  Future<(TeamLineupEntity?, TeamLineupEntity?)> _healMissingLineupPlayers({
    required String matchId,
    required String lang,
    required TeamLineupEntity? home,
    required TeamLineupEntity? away,
  }) async {
    try {
      final langPrefix = (lang == 'en') ? 'en' : 'ar';
      final upstreamUrl =
          'https://www.ysscores.com/$langPrefix/match_lineup?match_code=$matchId';
      final response = await _client.get(
        upstreamUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      if (response is! Map) return (home, away);

      final rawLineup = response['lineup'];
      if (rawLineup is! Map) return (home, away);

      final rawInfo = response['info'] is Map ? response['info'] as Map : null;
      final homeTeamId = rawInfo?['home_team']?.toString() ?? home?.teamId;
      final awayTeamId = rawInfo?['away_team']?.toString() ?? away?.teamId;

      TeamLineupEntity? healedHome = home;
      TeamLineupEntity? healedAway = away;

      if (healedHome != null &&
          healedHome.startingXi.length >= 8 &&
          healedHome.startingXi.length < 11) {
        healedHome = _enrichTeamLineup(healedHome, homeTeamId, rawLineup);
      }

      if (healedAway != null &&
          healedAway.startingXi.length >= 8 &&
          healedAway.startingXi.length < 11) {
        healedAway = _enrichTeamLineup(healedAway, awayTeamId, rawLineup);
      }

      return (healedHome, healedAway);
    } catch (_) {
      return (home, away);
    }
  }

  TeamLineupEntity _enrichTeamLineup(
    TeamLineupEntity team,
    String? teamId,
    Map rawLineup,
  ) {
    dynamic teamLineupData;
    if (teamId != null && rawLineup.containsKey(teamId)) {
      teamLineupData = rawLineup[teamId];
    } else if (team.teamId != null && rawLineup.containsKey(team.teamId)) {
      teamLineupData = rawLineup[team.teamId];
    } else {
      // Find the group that contains existing players of this team
      for (final candidate in rawLineup.values) {
        if (candidate is Map) {
          final candidateNames = _extractAllPlayerNamesFromUpstreamTeam(
            candidate,
          );
          final matchCount = team.startingXi
              .where((p) => candidateNames.contains(p.name.trim()))
              .length;
          if (matchCount >= 2) {
            teamLineupData = candidate;
            break;
          }
        }
      }
      teamLineupData ??= rawLineup.values.first;
    }

    if (teamLineupData is! Map) return team;

    final currentStarters = List<LineupPlayerEntity>.from(team.startingXi);
    final existingIds = currentStarters
        .map((p) => p.playerId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();
    final existingNames = currentStarters.map((p) => p.name.trim()).toSet();

    // Iterate through tactical groups in order: G, D, M, F, S
    for (final grpKey in ['G', 'D', 'M', 'F', 'S']) {
      final grp = teamLineupData[grpKey];
      if (grp is Map) {
        for (final item in grp.values) {
          if (item is Map) {
            final itemMap = Map<String, dynamic>.from(item);
            itemMap['position_code'] ??=
                itemMap['position']?.toString() ?? grpKey;
            final parsed = _parseLineupPlayer(itemMap, isStarter: true);
            final pId = parsed.playerId;
            final pName = parsed.name.trim();

            final alreadyExists =
                (pId != null && existingIds.contains(pId)) ||
                (pName.isNotEmpty && existingNames.contains(pName));

            if (!alreadyExists) {
              currentStarters.add(parsed);
              if (pId != null) existingIds.add(pId);
              if (pName.isNotEmpty) existingNames.add(pName);
            }
          }
        }
      }
    }

    final sortedStarters = _sortStartersTactically(currentStarters);

    return TeamLineupEntity(
      teamId: team.teamId,
      teamName: team.teamName,
      teamLogo: team.teamLogo,
      formation: team.formation,
      coach: team.coach,
      startingXi: sortedStarters,
      substitutes: team.substitutes,
      injuries: team.injuries,
    );
  }

  Set<String> _extractAllPlayerNamesFromUpstreamTeam(Map teamData) {
    final names = <String>{};
    for (final val in teamData.values) {
      if (val is Map) {
        for (final item in val.values) {
          if (item is Map) {
            final p = item['player'];
            if (p is Map) {
              final n = p['title']?.toString() ?? p['name']?.toString();
              if (n != null && n.trim().isNotEmpty) names.add(n.trim());
            }
          }
        }
      }
    }
    return names;
  }

  static List<LineupPlayerEntity> _sortStartersTactically(
    List<LineupPlayerEntity> starters,
  ) {
    if (starters.length <= 1) return starters;
    final sorted = List<LineupPlayerEntity>.from(starters);
    sorted.sort((a, b) {
      final wA = _tacticalWeight(a);
      final wB = _tacticalWeight(b);
      return wA.compareTo(wB);
    });
    return sorted;
  }

  static int _tacticalWeight(LineupPlayerEntity p) {
    if (p.isGoalkeeper || p.positionCode == 'G') return 0;
    if (p.positionCode == 'D') return 1;
    if (p.positionCode == 'M') return 2;
    if (p.positionCode == 'F') return 3;
    if (p.positionCode == 'S') return 4;
    final pos = (p.position ?? '').toLowerCase();
    if (pos.contains('دفاع') ||
        pos.contains('ظهير') ||
        pos.contains('back') ||
        pos.contains('defender')) {
      return 1;
    }
    if (pos.contains('وسط') || pos.contains('midfield')) return 2;
    if (pos.contains('هجوم') ||
        pos.contains('جناح') ||
        pos.contains('forward') ||
        pos.contains('winger') ||
        pos.contains('striker')) {
      return 3;
    }
    return 2;
  }

  TeamLineupEntity? _parseTeamLineup(dynamic rawTeam) {
    if (rawTeam == null || rawTeam is! Map) return null;
    final map = Map<String, dynamic>.from(rawTeam);

    final teamId = map['team_id']?.toString() ?? map['id']?.toString();
    final rawName =
        map['team_name']?.toString() ?? map['name']?.toString() ?? '';
    final teamName = TeamLineupEntity.sanitizeTeamName(rawName);
    final teamLogo = UrlHelper.normalizeImageUrl(
      map['team_logo']?.toString() ?? map['logo']?.toString(),
    );
    final formation = map['formation']?.toString();

    // Parse Coach
    LineupCoachEntity? coach;
    if (map['coach'] is Map) {
      final cMap = Map<String, dynamic>.from(map['coach'] as Map);
      var cId = cMap['coach_id']?.toString() ?? cMap['id']?.toString();
      if ((cId == null || cId.isEmpty || cId == '0') && cMap['link'] != null) {
        final linkStr = cMap['link'].toString();
        final match = RegExp(r'/coach/(\d+)').firstMatch(linkStr);
        if (match != null) {
          cId = match.group(1);
        }
      }
      coach = LineupCoachEntity(
        coachId: cId,
        name: cMap['name']?.toString() ?? '',
        photo: UrlHelper.normalizeImageUrl(cMap['photo']?.toString()),
        link: cMap['link']?.toString(),
      );
    }

    // Parse Starting XI
    final starters = <LineupPlayerEntity>[];
    if (map['starting_xi'] is List) {
      for (final it in map['starting_xi'] as List) {
        if (it is Map) {
          starters.add(_parseLineupPlayer(it, isStarter: true));
        }
      }
    }

    // Parse Substitutes
    final substitutes = <LineupPlayerEntity>[];
    if (map['substitutes'] is List) {
      for (final it in map['substitutes'] as List) {
        if (it is Map) {
          substitutes.add(
            _parseLineupPlayer(it, isStarter: false, isSubstitute: true),
          );
        }
      }
    }

    // Parse Injuries
    final injuries = <LineupInjuryEntity>[];
    if (map['injuries'] is List) {
      for (final it in map['injuries'] as List) {
        if (it is Map) {
          final iMap = Map<String, dynamic>.from(it);
          final pMap = iMap['player'] is Map
              ? Map<String, dynamic>.from(iMap['player'] as Map)
              : null;
          injuries.add(
            LineupInjuryEntity(
              playerId:
                  iMap['player_id']?.toString() ??
                  iMap['id']?.toString() ??
                  pMap?['row_id']?.toString(),
              name:
                  iMap['name']?.toString() ??
                  pMap?['title']?.toString() ??
                  pMap?['name']?.toString() ??
                  '',
              shortName:
                  iMap['short_name']?.toString() ??
                  iMap['short_title']?.toString() ??
                  pMap?['short_title']?.toString() ??
                  pMap?['short_name']?.toString(),
              number: int.tryParse(
                iMap['number']?.toString() ??
                    pMap?['player_number']?.toString() ??
                    '',
              ),
              position:
                  iMap['position']?.toString() ?? pMap?['position']?.toString(),
              photo: UrlHelper.normalizeImageUrl(
                iMap['photo']?.toString() ??
                    iMap['image']?.toString() ??
                    pMap?['image']?.toString(),
              ),
              absenceReason:
                  iMap['absence_reason']?.toString() ??
                  iMap['type_name']?.toString() ??
                  iMap['reason']?.toString(),
              absenceTypeId: int.tryParse(
                iMap['absence_type_id']?.toString() ??
                    iMap['type']?.toString() ??
                    '',
              ),
            ),
          );
        }
      }
    }

    // Enrich starters with subbed out times from substitutes if missing
    for (int i = 0; i < starters.length; i++) {
      final starter = starters[i];
      if (starter.substituteOut) {
        LineupPlayerEntity? matchingSub;
        for (final sub in substitutes) {
          if (sub.substituteIn &&
              ((sub.subbedForId != null &&
                      sub.subbedForId == starter.playerId) ||
                  (sub.subbedForName != null &&
                      (sub.subbedForName == starter.name ||
                          sub.subbedForName == starter.shortName)))) {
            matchingSub = sub;
            break;
          }
        }
        if (matchingSub != null && matchingSub.substituteTime != null) {
          starters[i] = starter.copyWith(
            substituteTime: matchingSub.substituteTime,
            substitutePlus: matchingSub.substitutePlus,
          );
        }
      }
    }

    // Enrich substitutes subbedForName from starters if missing
    for (int i = 0; i < substitutes.length; i++) {
      final sub = substitutes[i];
      if (sub.substituteIn &&
          (sub.subbedForName == null || sub.subbedForName!.isEmpty)) {
        if (sub.subbedForId != null) {
          for (final s in starters) {
            if (s.playerId == sub.subbedForId) {
              substitutes[i] = sub.copyWith(subbedForName: s.displayName);
              break;
            }
          }
        }
      }
    }

    return TeamLineupEntity(
      teamId: teamId,
      teamName: teamName,
      teamLogo: teamLogo,
      formation: formation,
      coach: coach,
      startingXi: _sortStartersTactically(starters),
      substitutes: substitutes,
      injuries: injuries,
    );
  }

  LineupPlayerEntity _parseLineupPlayer(
    Map raw, {
    bool isStarter = true,
    bool isSubstitute = false,
  }) {
    final map = Map<String, dynamic>.from(raw);
    final pMap = map['player'] is Map
        ? Map<String, dynamic>.from(map['player'] as Map)
        : null;

    final id =
        map['player_id']?.toString() ??
        map['id']?.toString() ??
        pMap?['row_id']?.toString();

    final name =
        map['name']?.toString() ??
        map['player_name']?.toString() ??
        pMap?['title']?.toString() ??
        pMap?['name']?.toString() ??
        '';

    final numVal = int.tryParse(
      map['number']?.toString() ?? pMap?['player_number']?.toString() ?? '',
    );

    final pos = map['position']?.toString() ?? pMap?['position']?.toString();

    final posCode =
        map['position_code']?.toString() ??
        map['pos']?.toString() ??
        map['position']?.toString();

    final formPos = int.tryParse(map['formation_position']?.toString() ?? '');

    final photo = UrlHelper.normalizePlayerPhotoUrl(
      map['photo']?.toString() ??
          map['image']?.toString() ??
          pMap?['image']?.toString() ??
          id,
    );

    final rating = map['rating']?.toString();

    final isCap =
        map['is_captain'] == true ||
        map['captain'] == true ||
        map['is_captain'] == 1 ||
        map['captain'] == 1;

    final detailedPos = map['detailed_position']?.toString() ?? pos;
    final isMotm =
        map['man_of_match'] == true ||
        map['man_of_match'] == 1 ||
        map['man_match'] == true ||
        map['man_match'] == 1;
    int evGoals = 0;
    int evAssists = 0;
    int evYellows = 0;
    int evReds = 0;
    final eventsRaw = map['events'] ?? pMap?['events'];
    if (eventsRaw is List) {
      for (final ev in eventsRaw) {
        if (ev is Map) {
          final t = ev['type']?.toString().toLowerCase() ?? '';
          if (t.contains('goal') || t == 'g') evGoals++;
          if (t.contains('assist') || t == 'a') evAssists++;
          if (t.contains('yellow')) evYellows++;
          if (t.contains('red')) evReds++;
        }
      }
    }

    final parsedYellows =
        int.tryParse(
          map['yellow_cards']?.toString() ??
              map['yellow_card']?.toString() ??
              pMap?['yellow_cards']?.toString() ??
              pMap?['yellow_card']?.toString() ??
              '',
        ) ??
        0;
    final yellowCards = evYellows > parsedYellows ? evYellows : parsedYellows;

    final parsedReds =
        int.tryParse(
          map['red_cards']?.toString() ??
              map['red_card']?.toString() ??
              pMap?['red_cards']?.toString() ??
              pMap?['red_card']?.toString() ??
              '',
        ) ??
        0;
    final redCards = evReds > parsedReds ? evReds : parsedReds;

    final parsedGoals =
        int.tryParse(
          map['goals']?.toString() ??
              map['goal']?.toString() ??
              map['goals_count']?.toString() ??
              map['goal_count']?.toString() ??
              pMap?['goals']?.toString() ??
              pMap?['goal']?.toString() ??
              '',
        ) ??
        0;
    final goals = evGoals > parsedGoals ? evGoals : parsedGoals;

    final parsedAssists =
        int.tryParse(
          map['assists']?.toString() ??
              map['assist']?.toString() ??
              map['assists_count']?.toString() ??
              map['assist_count']?.toString() ??
              pMap?['assists']?.toString() ??
              pMap?['assist']?.toString() ??
              '',
        ) ??
        0;
    final assists = evAssists > parsedAssists ? evAssists : parsedAssists;

    final shortName =
        map['short_name']?.toString() ??
        map['short_title']?.toString() ??
        pMap?['short_title']?.toString() ??
        pMap?['short_name']?.toString();

    final ownGoals =
        int.tryParse(
          map['own_goals']?.toString() ?? map['own_goal']?.toString() ?? '',
        ) ??
        0;

    final isActuallyStarter = map['is_starter'] == true || isStarter;
    final isActuallySub = map['is_substitute'] == true || isSubstitute;

    // Starters start the game on the pitch and can never be subbed in.
    final subIn =
        !isActuallyStarter &&
        (map['substitute_in'] == true ||
            map['substitute_in'] == 1 ||
            map['sub_in'] == true ||
            map['sub_in'] == 1 ||
            (isActuallySub &&
                (map['substitute_time'] != null || map['subbed_for'] != null)));

    // A starter who has substitute_time or subbed_for is being substituted OUT.
    final subOut =
        map['substitute_out'] == true ||
        map['substitute_out'] == 1 ||
        map['sub_out'] == true ||
        map['sub_out'] == 1 ||
        map['substitute'] == true ||
        map['substitute'] == 1 ||
        (isActuallyStarter &&
            (map['substitute_time'] != null || map['subbed_for'] != null));

    final subTime = int.tryParse(
      map['substitute_time']?.toString() ?? map['sub_time']?.toString() ?? '',
    );

    final subPlus = int.tryParse(map['substitute_plus']?.toString() ?? '');

    String? subbedFor;
    String? subbedForId;
    if (map['subbed_for'] is Map) {
      final sMap = Map<String, dynamic>.from(map['subbed_for'] as Map);
      subbedForId = sMap['player_id']?.toString() ?? sMap['id']?.toString();
      subbedFor =
          sMap['short_name']?.toString() ??
          sMap['name']?.toString() ??
          sMap['title']?.toString() ??
          sMap['short_title']?.toString();
    } else if (map['subbed_for'] is String &&
        (map['subbed_for'] as String).trim().isNotEmpty) {
      subbedFor = map['subbed_for'] as String;
    } else if (map['player_lineup'] is Map) {
      final sMap = Map<String, dynamic>.from(map['player_lineup'] as Map);
      subbedForId = sMap['player_id']?.toString() ?? sMap['id']?.toString();
      subbedFor =
          sMap['short_title']?.toString() ??
          sMap['title']?.toString() ??
          sMap['name']?.toString();
    } else if (map['player_out'] is Map) {
      final sMap = Map<String, dynamic>.from(map['player_out'] as Map);
      subbedForId = sMap['player_id']?.toString() ?? sMap['id']?.toString();
      subbedFor = sMap['short_name']?.toString() ?? sMap['name']?.toString();
    } else if (map['player_out'] is String) {
      subbedFor = map['player_out'] as String;
    }

    return LineupPlayerEntity(
      playerId: id,
      name: name,
      shortName: shortName,
      number: numVal,
      position: pos,
      positionCode: posCode,
      detailedPosition: detailedPos,
      formationPosition: formPos,
      photo: photo,
      rating: ((map['is_substitute'] == true || isSubstitute) && !subIn)
          ? null
          : rating,
      isCaptain: isCap,
      isStarter: map['is_starter'] == true || isStarter,
      isSubstitute: map['is_substitute'] == true || isSubstitute,
      isManOfMatch: isMotm,
      yellowCards: yellowCards,
      redCards: redCards,
      goals: goals,
      ownGoals: ownGoals,
      assists: assists,
      substituteIn: subIn,
      substituteOut: subOut,
      substituteTime: subTime,
      substitutePlus: subPlus,
      subbedForName: subbedFor,
      subbedForId: subbedForId,
    );
  }
}
