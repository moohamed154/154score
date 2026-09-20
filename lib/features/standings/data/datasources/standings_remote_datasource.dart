import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/standings_entity.dart';
import '../models/standings_dto.dart';

abstract class StandingsRemoteDataSource {
  Future<LeagueStandingsEntity> getStandings(
    String leagueId, {
    required String lang,
  });

  LeagueStandingsEntity parseStandings(
    dynamic response, {
    String? defaultLeagueId,
    String lang = 'en',
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
    return parseStandings(response, defaultLeagueId: leagueId);
  }

  @override
  LeagueStandingsEntity parseStandings(
    dynamic response, {
    String? defaultLeagueId,
    String lang = 'en',
  }) {

    final rows = <StandingRowEntity>[];
    final groups = <String, List<StandingRowEntity>>{};
    final stages = <TournamentStageEntity>[];
    final legends = <StandingLegendEntity>[];
    List<String>? rulesList;
    String leagueName = 'League Standings';

    dynamic dataNode;
    if (response is Map) {
      if (response['data'] is Map) {
        dataNode = response['data'] as Map;
      } else if (response['data'] is List) {
        dataNode = {'table': response['data']};
      } else {
        dataNode = response;
      }
    } else if (response is List) {
      dataNode = {'table': response};
    }

    if (dataNode is Map) {
      final data = dataNode;
      final raw = (data['raw'] is Map) ? (data['raw'] as Map) : data;

      if (data['league_name'] != null &&
          data['league_name'].toString().isNotEmpty) {
        leagueName = data['league_name'].toString();
      }

      // Parse structured colors (legends) if available
      final colorsData = data['colors'] ?? raw['color'] ?? data['color'];
      if (colorsData is List && colorsData.isNotEmpty) {
        for (final c in colorsData) {
          if (c is Map) {
            final color = c['color']?.toString();
            final desc = c['description']?.toString() ??
                c['league_to']?.toString() ??
                c['name']?.toString() ??
                '';
            if (color != null && color.isNotEmpty && desc.isNotEmpty) {
              legends.add(StandingLegendEntity(colorHex: color, description: desc));
            }
          }
        }
      }

      // Fallback: Parse Promotion / Qualification Legends from HTML or raw array
      if (legends.isEmpty) {
        final promotionData = raw['promotion'] ?? data['promotion'];
        legends.addAll(_parsePromotionLegends(promotionData));
      }

      // Parse rules_list / tiebreaker rules
      final rulesData = data['rules_list'] ?? raw['rules_list'] ?? data['tiebreak_rules'];
      if (rulesData is List && rulesData.isNotEmpty) {
        rulesList = rulesData
            .map((e) => e?.toString() ?? '')
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }

      // 1. Primary Source: data['table'] — flat list with full team data
      //    This is the most reliable source; always try it first.
      if (data['table'] is List && (data['table'] as List).isNotEmpty) {
        final tableList = data['table'] as List;

        // Check if items have meaningful team data (not just color stubs)
        final hasTeamData = tableList.any((item) =>
            item is Map &&
            (item['team_name'] != null ||
             item['team_id'] != null ||
             item['team'] != null ||
             item['name'] != null));

        if (hasTeamData) {
          for (int i = 0; i < tableList.length; i++) {
            final it = tableList[i];
            if (it is Map) {
              final row = StandingRowDto.fromJson(
                i + 1,
                Map<String, dynamic>.from(it),
              ).toEntity();
              rows.add(row);
              if (row.groupName != null && row.groupName!.isNotEmpty) {
                groups.putIfAbsent(row.groupName!, () => []).add(row);
              }
            }
          }
        }
      }

      // 2. Secondary Source: raw['list_match']
      //    Check if raw['list_match'] provides data or more complete rows than data['table']
      final rawMatch =
          (raw['list_match'] is List) ? (raw['list_match'] as List) : null;
      if (rawMatch != null && rawMatch.isNotEmpty) {
        final rawRows = <StandingRowEntity>[];
        final rawGroups = <String, List<StandingRowEntity>>{};

        // Determine if items are group-wrapper objects (Map of maps)
        // or flat team objects (Map with team_name / team_id fields)
        final isGrouped =
            rawMatch.first is Map &&
            !(rawMatch.first as Map).containsKey('team_name') &&
            !(rawMatch.first as Map).containsKey('team_id') &&
            !(rawMatch.first as Map).containsKey('play') &&
            !(rawMatch.first as Map).containsKey('wins');

        if (isGrouped) {
          // Each item is a group (Map or List of team rows)
          final hasMultiGroups = rawMatch.length > 1;
          for (int gIdx = 0; gIdx < rawMatch.length; gIdx++) {
            final groupItem = rawMatch[gIdx];
            final groupLetter = String.fromCharCode(65 + gIdx);
            final defaultGroupName =
                hasMultiGroups
                    ? (lang == 'ar'
                        ? 'المجموعة $groupLetter'
                        : 'Group $groupLetter')
                    : null;

            final groupRows = <StandingRowEntity>[];

            if (groupItem is Map) {
              groupItem.forEach((key, val) {
                final pos =
                    int.tryParse(key.toString()) ?? (groupRows.length + 1);
                if (val is Map) {
                  final row =
                      StandingRowDto.fromJson(
                        pos,
                        Map<String, dynamic>.from(val),
                        groupName: defaultGroupName,
                      ).toEntity();
                  rawRows.add(row);
                  groupRows.add(row);
                }
              });
            } else if (groupItem is List) {
              for (int i = 0; i < groupItem.length; i++) {
                final val = groupItem[i];
                if (val is Map) {
                  final row =
                      StandingRowDto.fromJson(
                        i + 1,
                        Map<String, dynamic>.from(val),
                        groupName: defaultGroupName,
                      ).toEntity();
                  rawRows.add(row);
                  groupRows.add(row);
                }
              }
            }

            if (hasMultiGroups &&
                defaultGroupName != null &&
                groupRows.isNotEmpty) {
              groupRows.sort((a, b) => a.position.compareTo(b.position));
              rawGroups[defaultGroupName] = groupRows;
            }
          }
        } else {
          // Flat list of team objects
          for (int i = 0; i < rawMatch.length; i++) {
            final val = rawMatch[i];
            if (val is Map) {
              final row =
                  StandingRowDto.fromJson(
                    i + 1,
                    Map<String, dynamic>.from(val),
                  ).toEntity();
              rawRows.add(row);
              if (row.groupName != null && row.groupName!.isNotEmpty) {
                rawGroups.putIfAbsent(row.groupName!, () => []).add(row);
              }
            }
          }
        }

        if (rawRows.length > rows.length) {
          rows.clear();
          rows.addAll(rawRows);
          groups.clear();
          groups.addAll(rawGroups);
        }
      }

      // 3. Third Source: data['groups'] list or map format
      if (data['groups'] is List && (data['groups'] as List).isNotEmpty) {
        final groupList = data['groups'] as List;
        for (final g in groupList) {
          if (g is Map) {
            final gTitle =
                g['name']?.toString() ?? g['title']?.toString() ?? 'Group';
            final gTable = g['table'] as List? ?? [];
            final gRows = <StandingRowEntity>[];
            for (int i = 0; i < gTable.length; i++) {
              final it = gTable[i];
              if (it is Map) {
                final row = StandingRowDto.fromJson(
                  i + 1,
                  Map<String, dynamic>.from(it),
                  groupName: gTitle,
                ).toEntity();
                if (rows.isEmpty) rows.add(row);
                gRows.add(row);
              }
            }
            if (gRows.isNotEmpty) {
              gRows.sort((a, b) => a.position.compareTo(b.position));
              groups[gTitle] = gRows;
            }
          }
        }
      } else if (data['groups'] is Map && (data['groups'] as Map).isNotEmpty) {
        final groupsMap = data['groups'] as Map;
        groupsMap.forEach((gTitle, gList) {
          if (gList is List && gList.isNotEmpty) {
            final gRows = <StandingRowEntity>[];
            for (int i = 0; i < gList.length; i++) {
              final it = gList[i];
              if (it is Map) {
                final row = StandingRowDto.fromJson(
                  i + 1,
                  Map<String, dynamic>.from(it),
                  groupName: gTitle.toString(),
                ).toEntity();
                if (rows.isEmpty) rows.add(row);
                gRows.add(row);
              }
            }
            if (gRows.isNotEmpty) {
              gRows.sort((a, b) => a.position.compareTo(b.position));
              groups[gTitle.toString()] = gRows;
            }
          }
        });
      }

      // 4. Parse Tournament Stages (Knockout brackets, rounds)
      final rawStages = data['stages'] ?? raw['stages'];
      if (rawStages is List && rawStages.isNotEmpty) {
        for (final s in rawStages) {
          if (s is Map) {
            final stageName =
                s['stage_name']?.toString() ?? s['name']?.toString() ?? '';
            final stageId = s['stage_id']?.toString();
            final round = s['round'] is int
                ? s['round'] as int
                : int.tryParse(s['round']?.toString() ?? '');
            final teamsNumber = s['teams_number'] is int
                ? s['teams_number'] as int
                : int.tryParse(s['teams_number']?.toString() ?? '');
            final matchesList = <StageMatchEntity>[];

            if (s['matches'] is List) {
              for (final m in s['matches']) {
                if (m is Map) {
                  final teamAMap = m['team_a'] is Map ? m['team_a'] as Map : {};
                  final teamBMap = m['team_b'] is Map ? m['team_b'] as Map : {};

                  final teamA = StageTeamEntity(
                    id: teamAMap['id']?.toString(),
                    name: teamAMap['name']?.toString() ?? '',
                    logo: teamAMap['logo']?.toString(),
                    score: teamAMap['score'] is int
                        ? teamAMap['score'] as int
                        : int.tryParse(teamAMap['score']?.toString() ?? ''),
                    isWinner: teamAMap['is_winner'] == true ||
                        teamAMap['winner'] == true,
                    worldRanking: teamAMap['world_ranking'] is int
                        ? teamAMap['world_ranking'] as int
                        : int.tryParse(
                            teamAMap['world_ranking']?.toString() ?? '',
                          ),
                  );

                  final teamB = StageTeamEntity(
                    id: teamBMap['id']?.toString(),
                    name: teamBMap['name']?.toString() ?? '',
                    logo: teamBMap['logo']?.toString(),
                    score: teamBMap['score'] is int
                        ? teamBMap['score'] as int
                        : int.tryParse(teamBMap['score']?.toString() ?? ''),
                    isWinner: teamBMap['is_winner'] == true ||
                        teamBMap['winner'] == true,
                    worldRanking: teamBMap['world_ranking'] is int
                        ? teamBMap['world_ranking'] as int
                        : int.tryParse(
                            teamBMap['world_ranking']?.toString() ?? '',
                          ),
                  );

                  matchesList.add(
                    StageMatchEntity(
                      matchId: m['match_id']?.toString(),
                      position: m['position']?.toString(),
                      teamGroup: m['team_group']?.toString(),
                      teamA: teamA,
                      teamB: teamB,
                      winnerId: m['winner_id']?.toString(),
                      matchDate: m['match_date']?.toString(),
                      matchTime: m['match_time']?.toString(),
                    ),
                  );
                }
              }
            }

            if (stageName.isNotEmpty) {
              stages.add(
                TournamentStageEntity(
                  stageName: stageName,
                  stageId: stageId,
                  round: round,
                  teamsNumber: teamsNumber,
                  matches: matchesList,
                ),
              );
            }
          }
        }
      }
    }

    // Sort all rows by position ascending
    rows.sort((a, b) => a.position.compareTo(b.position));

    return LeagueStandingsEntity(
      leagueId: (dataNode is Map && dataNode['league_id'] != null)
          ? dataNode['league_id'].toString()
          : (defaultLeagueId ?? ''),
      leagueTitle: leagueName,
      rows: rows,
      groups: groups.isNotEmpty ? groups : null,
      stages: stages.isNotEmpty ? stages : null,
      legends: legends.isNotEmpty ? legends : null,
      rulesList: rulesList != null && rulesList.isNotEmpty ? rulesList : null,
    );
  }

  List<StandingLegendEntity> _parsePromotionLegends(dynamic promotionData) {
    final items = <StandingLegendEntity>[];
    if (promotionData == null) return items;

    final rawStrings = <String>[];
    if (promotionData is List) {
      for (final item in promotionData) {
        if (item != null) rawStrings.add(item.toString());
      }
    } else if (promotionData is String) {
      rawStrings.add(promotionData);
    }

    final blockRegex = RegExp(
      r'<div[^>]*class="rank-key"[^>]*>([\s\S]*?)<\/div>',
      caseSensitive: false,
    );
    final fillRegex = RegExp(r"""fill=["'](#[0-9a-fA-F]{3,8})["']""");
    final textRegex = RegExp(
      r'<span[^>]*>([\s\S]*?)<\/span>',
      caseSensitive: false,
    );

    for (final raw in rawStrings) {
      final blocks = blockRegex.allMatches(raw);
      if (blocks.isNotEmpty) {
        for (final match in blocks) {
          final content = match.group(1) ?? '';
          final fillMatch = fillRegex.firstMatch(content);
          final textMatch = textRegex.firstMatch(content);
          final color = fillMatch?.group(1) ?? '#34C759';
          final text =
              textMatch?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ??
              '';
          if (text.isNotEmpty) {
            items.add(StandingLegendEntity(colorHex: color, description: text));
          }
        }
      } else {
        final spans = textRegex.allMatches(raw);
        for (final sp in spans) {
          final text =
              sp.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
          if (text.isNotEmpty) {
            items.add(
              StandingLegendEntity(colorHex: '#34C759', description: text),
            );
          }
        }
      }
    }

    return items;
  }
}
