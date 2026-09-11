import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/standings_entity.dart';
import '../models/standings_dto.dart';

abstract class StandingsRemoteDataSource {
  Future<LeagueStandingsEntity> getStandings(
    String leagueId, {
    required String lang,
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

    final rows = <StandingRowEntity>[];
    final groups = <String, List<StandingRowEntity>>{};
    final legends = <StandingLegendEntity>[];
    String leagueName = 'League Standings';

    if (response is Map && response['data'] is Map) {
      final data = response['data'] as Map;
      final raw = (data['raw'] is Map) ? (data['raw'] as Map) : data;

      if (data['league_name'] != null &&
          data['league_name'].toString().isNotEmpty) {
        leagueName = data['league_name'].toString();
      }

      // Parse Promotion / Qualification Legends from HTML or raw array
      final promotionData = raw['promotion'] ?? data['promotion'];
      legends.addAll(_parsePromotionLegends(promotionData));

      // 1. Primary Source: data['table'] — flat list with full team data
      //    This is the most reliable source; always try it first.
      if (data['table'] is List && (data['table'] as List).isNotEmpty) {
        final tableList = data['table'] as List;

        // Check if items have meaningful team data (not just color stubs)
        final hasTeamData = tableList.any((item) =>
            item is Map &&
            (item['team_name'] != null || item['team_id'] != null));

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

      // 2. Secondary Source: raw['list_match'] as a flat list
      //    Each item is a direct team record (not a group wrapper).
      //    Only use if data['table'] didn't yield results.
      if (rows.isEmpty &&
          raw['list_match'] is List &&
          (raw['list_match'] as List).isNotEmpty) {
        final listMatch = raw['list_match'] as List;

        // Determine if items are group-wrapper objects (Map of maps)
        // or flat team objects (Map with team_name / team_id fields)
        final isGrouped = listMatch.isNotEmpty &&
            listMatch.first is Map &&
            !(listMatch.first as Map).containsKey('team_name') &&
            !(listMatch.first as Map).containsKey('team_id') &&
            !(listMatch.first as Map).containsKey('play') &&
            !(listMatch.first as Map).containsKey('wins');

        if (isGrouped) {
          // Each item is a group (Map or List of team rows)
          final hasMultiGroups = listMatch.length > 1;
          for (int gIdx = 0; gIdx < listMatch.length; gIdx++) {
            final groupItem = listMatch[gIdx];
            final groupLetter = String.fromCharCode(65 + gIdx);
            final defaultGroupName = hasMultiGroups
                ? (lang == 'ar' ? 'المجموعة $groupLetter' : 'Group $groupLetter')
                : null;

            final groupRows = <StandingRowEntity>[];

            if (groupItem is Map) {
              groupItem.forEach((key, val) {
                final pos =
                    int.tryParse(key.toString()) ?? (groupRows.length + 1);
                if (val is Map) {
                  final row = StandingRowDto.fromJson(
                    pos,
                    Map<String, dynamic>.from(val),
                    groupName: defaultGroupName,
                  ).toEntity();
                  rows.add(row);
                  groupRows.add(row);
                }
              });
            } else if (groupItem is List) {
              for (int i = 0; i < groupItem.length; i++) {
                final val = groupItem[i];
                if (val is Map) {
                  final row = StandingRowDto.fromJson(
                    i + 1,
                    Map<String, dynamic>.from(val),
                    groupName: defaultGroupName,
                  ).toEntity();
                  rows.add(row);
                  groupRows.add(row);
                }
              }
            }

            if (hasMultiGroups &&
                defaultGroupName != null &&
                groupRows.isNotEmpty) {
              groupRows.sort((a, b) => a.position.compareTo(b.position));
              groups[defaultGroupName] = groupRows;
            }
          }
        } else {
          // Flat list of team objects
          for (int i = 0; i < listMatch.length; i++) {
            final val = listMatch[i];
            if (val is Map) {
              final row = StandingRowDto.fromJson(
                i + 1,
                Map<String, dynamic>.from(val),
              ).toEntity();
              rows.add(row);
              if (row.groupName != null && row.groupName!.isNotEmpty) {
                groups.putIfAbsent(row.groupName!, () => []).add(row);
              }
            }
          }
        }
      }

      // 3. Third Source: data['groups'] list format
      if (rows.isEmpty &&
          data['groups'] is List &&
          (data['groups'] as List).isNotEmpty) {
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
                rows.add(row);
                gRows.add(row);
              }
            }
            if (gRows.isNotEmpty) {
              gRows.sort((a, b) => a.position.compareTo(b.position));
              groups[gTitle] = gRows;
            }
          }
        }
      }
    }

    // Sort all rows by position ascending
    rows.sort((a, b) => a.position.compareTo(b.position));

    return LeagueStandingsEntity(
      leagueId: leagueId,
      leagueTitle: leagueName,
      rows: rows,
      groups: groups.length > 1 ? groups : null,
      legends: legends.isNotEmpty ? legends : null,
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
