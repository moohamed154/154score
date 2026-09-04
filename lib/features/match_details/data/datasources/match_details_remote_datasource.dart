import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/commentator_resolver.dart';
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
  Future<MatchLineupEntity?> getLineups(
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
            e['type']?.toString() ?? (isStartEnd ? 'start-end-match' : 'event');

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
                      slug = content.trim().toLowerCase().replaceAll(
                        RegExp(r'\s+'),
                        '-',
                      );
                    }

                    // Resolve known commentators when backend omits id/slug
                    if (entityType == 'commentator' &&
                        (id == null || id.isEmpty || id == '0')) {
                      final resolvedId = CommentatorResolver.resolveId(content) ??
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

  @override
  Future<MatchLineupEntity?> getLineups(
    String matchId, {
    required String lang,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.matchLineups(matchId),
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
      final formType = dataMap['formation_type']?.toString();

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

      return MatchLineupEntity(
        matchId: mId,
        lineupsAvailable: available,
        formationType: formType,
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
          final candidateNames =
              _extractAllPlayerNamesFromUpstreamTeam(candidate);
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
      coach = LineupCoachEntity(
        coachId: cMap['coach_id']?.toString() ?? cMap['id']?.toString(),
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
          injuries.add(
            LineupInjuryEntity(
              playerId:
                  iMap['player_id']?.toString() ?? iMap['id']?.toString(),
              name: iMap['name']?.toString() ?? '',
              number: int.tryParse(iMap['number']?.toString() ?? ''),
              position: iMap['position']?.toString(),
              photo: UrlHelper.normalizeImageUrl(iMap['photo']?.toString()),
              absenceReason:
                  iMap['absence_reason']?.toString() ??
                  iMap['reason']?.toString(),
              absenceTypeId: int.tryParse(
                iMap['absence_type_id']?.toString() ?? '',
              ),
            ),
          );
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

    final id = map['player_id']?.toString() ??
        map['id']?.toString() ??
        pMap?['row_id']?.toString();

    final name = map['name']?.toString() ??
        map['player_name']?.toString() ??
        pMap?['title']?.toString() ??
        pMap?['name']?.toString() ??
        '';

    final numVal = int.tryParse(
      map['number']?.toString() ??
          pMap?['player_number']?.toString() ??
          '',
    );

    final pos = map['position']?.toString() ?? pMap?['position']?.toString();

    final posCode = map['position_code']?.toString() ??
        map['pos']?.toString() ??
        map['position']?.toString();

    final formPos = int.tryParse(
      map['formation_position']?.toString() ?? '',
    );

    final photo = UrlHelper.normalizeImageUrl(
      map['photo']?.toString() ??
          map['image']?.toString() ??
          pMap?['image']?.toString(),
    );

    final rating = map['rating']?.toString();

    final isCap = map['is_captain'] == true ||
        map['captain'] == true ||
        map['is_captain'] == 1 ||
        map['captain'] == 1;

    return LineupPlayerEntity(
      playerId: id,
      name: name,
      number: numVal,
      position: pos,
      positionCode: posCode,
      formationPosition: formPos,
      photo: photo,
      rating: rating,
      isCaptain: isCap,
      isStarter: map['is_starter'] == true || isStarter,
      isSubstitute: map['is_substitute'] == true || isSubstitute,
    );
  }
}

