import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../matches/data/models/match_dto.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/data/datasources/standings_remote_datasource.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/team_entity.dart';

abstract class TeamsRemoteDataSource {
  Future<TeamProfileEntity> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  });

  Future<LeagueStandingsEntity> getChampionshipStandings(
    String championshipId, {
    required String lang,
  });
}

class TeamsRemoteDataSourceImpl implements TeamsRemoteDataSource {
  final ApiClient _client;
  final StandingsRemoteDataSource _standingsDataSource;

  TeamsRemoteDataSourceImpl(this._client, this._standingsDataSource);

  @override
  Future<LeagueStandingsEntity> getChampionshipStandings(
    String championshipId, {
    required String lang,
  }) async {
    return await _standingsDataSource.getStandings(championshipId, lang: lang);
  }

  MatchEntity _mapMatch(
    Map m,
    String? fallbackTeamName,
    String? fallbackLogo,
    String? leagueId,
  ) {
    final mId = m['match_id']?.toString() ?? '';
    final hTeam = m['home_team']?.toString() ?? '';
    final aTeam = m['away_team']?.toString() ?? '';
    final hLogo = UrlHelper.normalizeImageUrl(m['home_logo']?.toString());
    final aLogo = UrlHelper.normalizeImageUrl(m['away_logo']?.toString());
    final mStatus = m['status']?.toString() ?? '';
    final mStatusCode = m['status_code']?.toString();
    final mDate = m['date']?.toString();
    final mTime = m['time']?.toString();
    final champId = m['championship_id']?.toString() ?? leagueId;
    final champName = m['championship_name']?.toString();
    final champLogo = UrlHelper.normalizeImageUrl(
      m['championship_logo']?.toString(),
    );

    String? s1;
    String? s2;
    if (m['score'] is Map) {
      s1 = m['score']['home']?.toString();
      s2 = m['score']['away']?.toString();
    } else if (m['home_score'] != null && m['away_score'] != null) {
      s1 = m['home_score'].toString();
      s2 = m['away_score'].toString();
    } else {
      final rawScore = m['score']?.toString();
      if (rawScore != null && rawScore.contains('-')) {
        final parts = rawScore.split('-');
        s1 = parts[0].trim();
        s2 = parts.length > 1 ? parts[1].trim() : null;
      }
    }

    return MatchEntity(
      id: mId,
      date: mDate,
      time: mTime,
      status: mStatus,
      statusCode: mStatusCode,
      team1: hTeam,
      team2: aTeam,
      score1: s1,
      score2: s2,
      team1Logo:
          hLogo ??
          (fallbackTeamName != null &&
                  hTeam.toLowerCase().contains(fallbackTeamName.toLowerCase())
              ? fallbackLogo
              : null),
      team2Logo:
          aLogo ??
          (fallbackTeamName != null &&
                  aTeam.toLowerCase().contains(fallbackTeamName.toLowerCase())
              ? fallbackLogo
              : null),
      leagueId: champId,
      leagueTitle: champName,
      leagueLogo: champLogo,
    );
  }

  @override
  Future<TeamProfileEntity> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  }) async {
    // 1. Fetch from 154score API team endpoints
    if (teamId.isNotEmpty && int.tryParse(teamId) != null) {
      try {
        final profileFuture = _client
            .get(
              ApiEndpoints.teamProfile(teamId),
              queryParameters: {'lang': lang},
            )
            .catchError((_) => null);

        final playersFuture = _client
            .get(
              ApiEndpoints.teamPlayers(teamId),
              queryParameters: {'lang': lang},
            )
            .catchError((_) => null);

        final transfersFuture = _client
            .get(
              ApiEndpoints.teamTransfers(teamId),
              queryParameters: {'lang': lang},
            )
            .catchError((_) => null);

        final newsFuture = _client
            .get(ApiEndpoints.teamNews(teamId), queryParameters: {'lang': lang})
            .catchError((_) => null);

        final results = await Future.wait([
          profileFuture,
          playersFuture,
          transfersFuture,
          newsFuture,
        ]);

        final profileRes = results[0];
        final playersRes = results[1];
        final transfersRes = results[2];
        final newsRes = results[3];

        if (profileRes is Map && profileRes['data'] is Map) {
          final data = profileRes['data'] as Map;
          final effectiveName = data['name']?.toString() ?? teamName ?? 'Team';
          final effectiveLogo = UrlHelper.normalizeImageUrl(
            data['logo']?.toString(),
          );
          final country = data['country']?.toString();
          final countryFlag = UrlHelper.normalizeImageUrl(
            data['country_flag']?.toString(),
          );
          final countryCode = data['country_code']?.toString();
          final about = data['about']?.toString();
          final federation = data['federation']?.toString();
          final division = data['division']?.toString();
          final stadiumId = data['stadium_id']?.toString();
          final stadiumName = data['stadium_name']?.toString();
          final worldRanking = data['world_ranking'] is num
              ? (data['world_ranking'] as num).toInt()
              : null;

          // Championships
          final championships = <TeamChampionshipEntity>[];
          if (data['championships'] is List) {
            for (final c in data['championships']) {
              if (c is Map) {
                championships.add(
                  TeamChampionshipEntity(
                    id: c['id']?.toString() ?? '',
                    urlId: c['url_id']?.toString(),
                    title:
                        c['title']?.toString() ?? c['name']?.toString() ?? '',
                    logo: UrlHelper.normalizeImageUrl(
                      c['logo']?.toString() ?? c['image']?.toString(),
                    ),
                    type: c['type'] is num ? (c['type'] as num).toInt() : null,
                    ranking: c['ranking'] is num
                        ? (c['ranking'] as num).toInt()
                        : null,
                  ),
                );
              }
            }
          }

          // Cups (Trophies)
          final cups = <TeamCupEntity>[];
          if (data['cups'] is List) {
            for (final cup in data['cups']) {
              if (cup is Map) {
                final yearsList = <String>[];
                if (cup['years'] is List) {
                  for (final y in cup['years']) {
                    yearsList.add(y.toString());
                  }
                }
                cups.add(
                  TeamCupEntity(
                    title: cup['title']?.toString() ?? '',
                    logo: UrlHelper.normalizeImageUrl(cup['logo']?.toString()),
                    cupImage: UrlHelper.normalizeImageUrl(
                      cup['cup_image']?.toString(),
                    ),
                    count: cup['count'] is num
                        ? (cup['count'] as num).toInt()
                        : 0,
                    years: yearsList,
                  ),
                );
              }
            }
          }

          // Categorized Matches
          final online = <MatchEntity>[];
          final upcoming = <MatchEntity>[];
          final recent = <MatchEntity>[];
          final postponed = <MatchEntity>[];
          final form = <String>[];

          if (data['categorized_matches'] is Map) {
            final catM = data['categorized_matches'] as Map;
            if (catM['online'] is List) {
              for (final m in catM['online']) {
                if (m is Map)
                  online.add(
                    _mapMatch(m, effectiveName, effectiveLogo, leagueId),
                  );
              }
            }
            if (catM['coming'] is List) {
              for (final m in catM['coming']) {
                if (m is Map)
                  upcoming.add(
                    _mapMatch(m, effectiveName, effectiveLogo, leagueId),
                  );
              }
            }
            if (catM['end'] is List) {
              for (final m in catM['end']) {
                if (m is Map)
                  recent.add(
                    _mapMatch(m, effectiveName, effectiveLogo, leagueId),
                  );
              }
            }
            if (catM['postponed'] is List) {
              for (final m in catM['postponed']) {
                if (m is Map)
                  postponed.add(
                    _mapMatch(m, effectiveName, effectiveLogo, leagueId),
                  );
              }
            }
          } else {
            // Fallback parsing from flat matches
            final rawMatches = data['matches'] as List? ?? [];
            for (final rawM in rawMatches) {
              if (rawM is Map) {
                final match = _mapMatch(
                  rawM,
                  effectiveName,
                  effectiveLogo,
                  leagueId,
                );
                final statusLower = match.status?.toLowerCase() ?? '';
                final isFinished =
                    statusLower.contains('انتهت') ||
                    statusLower.contains('ft') ||
                    statusLower.contains('fin') ||
                    statusLower.contains('ended') ||
                    match.statusCode == '4';

                if (isFinished) {
                  recent.add(match);
                } else {
                  upcoming.add(match);
                }
              }
            }
          }

          // Calculate form from recent matches
          for (final m in recent) {
            final p1 = int.tryParse(m.score1 ?? '');
            final p2 = int.tryParse(m.score2 ?? '');
            if (p1 != null && p2 != null) {
              final isHome = m.team1.toLowerCase().contains(
                effectiveName.toLowerCase(),
              );
              final teamScore = isHome ? p1 : p2;
              final oppScore = isHome ? p2 : p1;
              if (teamScore > oppScore) {
                form.add('W');
              } else if (teamScore < oppScore) {
                form.add('L');
              } else {
                form.add('D');
              }
            }
          }

          // Players & Squad
          final squad = <TeamSquadPlayerEntity>[];
          TeamCategorizedSquadEntity? categorizedSquad;

          if (playersRes is Map && playersRes['data'] is Map) {
            final pData = playersRes['data'] as Map;

            TeamCoachEntity? coach;
            if (pData['coach'] is Map) {
              final cMap = pData['coach'] as Map;
              coach = TeamCoachEntity(
                id:
                    cMap['coach_id']?.toString() ??
                    cMap['id']?.toString() ??
                    '',
                name: cMap['name']?.toString() ?? '',
                photo: UrlHelper.normalizeImageUrl(cMap['photo']?.toString()),
              );
            }

            TeamSquadPlayerEntity mapPlayer(Map p) {
              final pId =
                  p['player_id']?.toString() ?? p['id']?.toString() ?? '';
              final pName = p['name']?.toString() ?? '';
              return TeamSquadPlayerEntity(
                id: pId,
                name: pName,
                number: p['number']?.toString(),
                position: p['position']?.toString(),
                category: p['category']?.toString(),
                photo: UrlHelper.normalizeImageUrl(p['photo']?.toString()),
                url: p['url']?.toString(),
              );
            }

            final gList = <TeamSquadPlayerEntity>[];
            final dList = <TeamSquadPlayerEntity>[];
            final mList = <TeamSquadPlayerEntity>[];
            final fList = <TeamSquadPlayerEntity>[];

            if (pData['categorized'] is Map) {
              final cat = pData['categorized'] as Map;
              if (cat['goalkeepers'] is List) {
                for (final p in cat['goalkeepers']) {
                  if (p is Map) gList.add(mapPlayer(p));
                }
              }
              if (cat['defenders'] is List) {
                for (final p in cat['defenders']) {
                  if (p is Map) dList.add(mapPlayer(p));
                }
              }
              if (cat['midfielders'] is List) {
                for (final p in cat['midfielders']) {
                  if (p is Map) mList.add(mapPlayer(p));
                }
              }
              if (cat['attackers'] is List) {
                for (final p in cat['attackers']) {
                  if (p is Map) fList.add(mapPlayer(p));
                }
              }
            }

            categorizedSquad = TeamCategorizedSquadEntity(
              coach: coach,
              goalkeepers: gList,
              defenders: dList,
              midfielders: mList,
              attackers: fList,
            );

            if (pData['players'] is List) {
              for (final p in pData['players']) {
                if (p is Map) squad.add(mapPlayer(p));
              }
            } else {
              squad.addAll([...gList, ...dList, ...mList, ...fList]);
            }
          }

          // Transfers
          TeamTransfersEntity? transfers;
          if (transfersRes is Map && transfersRes['data'] is Map) {
            final tData = transfersRes['data'] as Map;

            TeamTransferItemEntity? mapTransferItem(Map t) {
              final pMap = t['player'] as Map? ?? {};
              final inMap = t['team_in'] as Map? ?? {};
              final outMap = t['team_out'] as Map? ?? {};

              return TeamTransferItemEntity(
                player: TeamSquadPlayerEntity(
                  id: pMap['id']?.toString() ?? '',
                  name: pMap['name']?.toString() ?? '',
                  number: pMap['number']?.toString(),
                  position: pMap['position']?.toString(),
                  photo: UrlHelper.normalizeImageUrl(pMap['photo']?.toString()),
                ),
                teamIn: TeamTransferPartyEntity(
                  id: inMap['id']?.toString() ?? '',
                  name: inMap['name']?.toString() ?? '',
                  logo: UrlHelper.normalizeImageUrl(inMap['logo']?.toString()),
                ),
                teamOut: TeamTransferPartyEntity(
                  id: outMap['id']?.toString() ?? '',
                  name: outMap['name']?.toString() ?? '',
                  logo: UrlHelper.normalizeImageUrl(outMap['logo']?.toString()),
                ),
                value: t['value']?.toString() ?? '',
                type: t['type']?.toString() ?? 'Transfer',
                dateFrom: t['date_from']?.toString(),
                dateTo: t['date_to']?.toString(),
              );
            }

            final impList = <TeamTransferItemEntity>[];
            final allList = <TeamTransferItemEntity>[];

            if (tData['important'] is List) {
              for (final item in tData['important']) {
                if (item is Map) {
                  final t = mapTransferItem(item);
                  if (t != null) impList.add(t);
                }
              }
            }
            if (tData['all'] is List) {
              for (final item in tData['all']) {
                if (item is Map) {
                  final t = mapTransferItem(item);
                  if (t != null) allList.add(t);
                }
              }
            }

            transfers = TeamTransfersEntity(important: impList, all: allList);
          }

          // News
          final newsList = <TeamNewsItemEntity>[];
          if (newsRes is Map && newsRes['data'] is Map) {
            final nData = newsRes['data'] as Map;
            final rawNews = nData['news'] as List? ?? [];
            for (final n in rawNews) {
              if (n is Map) {
                newsList.add(
                  TeamNewsItemEntity(
                    id: n['id']?.toString() ?? '',
                    title: n['title']?.toString() ?? '',
                    slug: n['slug']?.toString(),
                    description: n['description']?.toString(),
                    image: UrlHelper.normalizeImageUrl(n['image']?.toString()),
                    createdAt: n['created_at']?.toString(),
                    url: n['url']?.toString(),
                  ),
                );
              }
            }
          }

          // Standings row for primary championship
          StandingRowEntity? standingRow;
          String? effectiveLeagueTitle;
          final targetLeagueId =
              leagueId ??
              (championships.isNotEmpty
                  ? (championships.first.urlId ?? championships.first.id)
                  : null);

          if (targetLeagueId != null && targetLeagueId.isNotEmpty) {
            try {
              final standings = await _standingsDataSource.getStandings(
                targetLeagueId,
                lang: lang,
              );
              effectiveLeagueTitle = standings.leagueTitle;
              final queryLower = effectiveName.toLowerCase();
              for (final row in standings.rows) {
                final rName = row.teamName.toLowerCase();
                if (rName == queryLower ||
                    (queryLower.length > 3 && rName.contains(queryLower)) ||
                    (rName.length > 3 && queryLower.contains(rName))) {
                  standingRow = row;
                  break;
                }
              }
            } catch (_) {}
          }

          return TeamProfileEntity(
            teamId: teamId,
            teamName: effectiveName,
            teamLogo: effectiveLogo,
            leagueId: targetLeagueId,
            leagueName:
                effectiveLeagueTitle ??
                (championships.isNotEmpty ? championships.first.title : null),
            country: country,
            countryFlag: countryFlag,
            countryCode: countryCode,
            about: about,
            federation: federation,
            division: division,
            stadiumId: stadiumId,
            stadiumName: stadiumName,
            worldRanking: worldRanking,
            championships: championships,
            cups: cups,
            onlineMatches: online,
            upcomingMatches: upcoming,
            recentMatches: recent,
            postponedMatches: postponed,
            standingsRow: standingRow,
            form: form.take(5).toList(),
            squad: squad,
            categorizedSquad: categorizedSquad,
            transfers: transfers,
            news: newsList,
          );
        }
      } catch (_) {}
    }

    // 2. Fallback: search matches across the day's leagues
    final queryParams = <String, dynamic>{'lang': lang};
    if (leagueId != null && leagueId.isNotEmpty) {
      queryParams['champ_id'] = leagueId;
    }

    final response = await _client.get(
      ApiEndpoints.matches,
      queryParameters: queryParams,
    );

    final allMatches = <MatchEntity>[];
    String effectiveName = teamName ?? 'Team';
    String? effectiveLogo;
    String? effectiveLeagueId = leagueId;
    String? effectiveLeagueTitle;

    if (response is Map && response['data'] is List) {
      final leagues = response['data'] as List;
      for (final l in leagues) {
        if (l is Map) {
          final lMatches = l['matches'] as List? ?? [];
          final lId = l['id']?.toString();
          final lTitle = l['title']?.toString();

          for (final m in lMatches) {
            if (m is Map) {
              final matchDto = MatchDto.fromJson(Map<String, dynamic>.from(m));
              final match = matchDto.toEntity();

              final t1Name = match.team1.toLowerCase();
              final t2Name = match.team2.toLowerCase();
              final queryLower = (teamName ?? teamId).toLowerCase();

              final isTeam1 =
                  t1Name == queryLower ||
                  (queryLower.length > 3 && t1Name.contains(queryLower));
              final isTeam2 =
                  t2Name == queryLower ||
                  (queryLower.length > 3 && t2Name.contains(queryLower));

              if (isTeam1 || isTeam2) {
                allMatches.add(match);
                if (isTeam1) {
                  effectiveName = match.team1;
                  effectiveLogo ??= match.team1Logo;
                } else {
                  effectiveName = match.team2;
                  effectiveLogo ??= match.team2Logo;
                }
                effectiveLeagueId ??= match.leagueId ?? lId;
                effectiveLeagueTitle ??= match.leagueTitle ?? lTitle;
              }
            }
          }
        }
      }
    }

    final upcoming = <MatchEntity>[];
    final recent = <MatchEntity>[];
    final form = <String>[];

    for (final match in allMatches) {
      final statusLower = match.status?.toLowerCase() ?? '';
      final isFinished =
          statusLower.contains('انتهت') ||
          statusLower.contains('ft') ||
          statusLower.contains('fin') ||
          statusLower.contains('ended') ||
          match.statusCode == '4';
      if (isFinished) {
        recent.add(match);
        final p1 = int.tryParse(match.score1 ?? '');
        final p2 = int.tryParse(match.score2 ?? '');
        if (p1 != null && p2 != null) {
          final isHome = match.team1.toLowerCase().contains(
            effectiveName.toLowerCase(),
          );
          final teamScore = isHome ? p1 : p2;
          final oppScore = isHome ? p2 : p1;
          if (teamScore > oppScore) {
            form.add('W');
          } else if (teamScore < oppScore) {
            form.add('L');
          } else {
            form.add('D');
          }
        }
      } else {
        upcoming.add(match);
      }
    }

    return TeamProfileEntity(
      teamId: teamId,
      teamName: effectiveName,
      teamLogo: effectiveLogo,
      leagueId: effectiveLeagueId,
      leagueName: effectiveLeagueTitle,
      upcomingMatches: upcoming,
      recentMatches: recent,
      form: form.take(5).toList(),
    );
  }
}
