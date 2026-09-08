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
}

class TeamsRemoteDataSourceImpl implements TeamsRemoteDataSource {
  final ApiClient _client;
  final StandingsRemoteDataSource _standingsDataSource;

  TeamsRemoteDataSourceImpl(this._client, this._standingsDataSource);

  @override
  Future<TeamProfileEntity> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  }) async {
    // 1. First, attempt to fetch directly from the official team profile endpoint
    if (teamId.isNotEmpty && int.tryParse(teamId) != null) {
      try {
        final profileRes = await _client.get(
          ApiEndpoints.teamProfile(teamId),
          queryParameters: {'lang': lang},
        );

        if (profileRes is Map && profileRes['data'] is Map) {
          final data = profileRes['data'] as Map;
          final effectiveName =
              data['name']?.toString() ?? teamName ?? 'Team';
          final effectiveLogo = UrlHelper.normalizeImageUrl(
            data['logo']?.toString(),
          );
          final country = data['country']?.toString();
          final rawMatches = data['matches'] as List? ?? [];

          final upcoming = <MatchEntity>[];
          final recent = <MatchEntity>[];
          final form = <String>[];

          for (final rawM in rawMatches) {
            if (rawM is Map) {
              final mId = rawM['match_id']?.toString() ?? '';
              final hTeam = rawM['home_team']?.toString() ?? '';
              final aTeam = rawM['away_team']?.toString() ?? '';
              final mStatus = rawM['status']?.toString() ?? '';
              final mDate = rawM['date']?.toString();
              final rawScore = rawM['score']?.toString();

              String? s1;
              String? s2;
              if (rawScore != null && rawScore.contains('-')) {
                final parts = rawScore.split('-');
                s1 = parts[0].trim();
                s2 = parts.length > 1 ? parts[1].trim() : null;
              }

              final match = MatchEntity(
                id: mId,
                date: mDate,
                status: mStatus,
                team1: hTeam,
                team2: aTeam,
                score1: s1,
                score2: s2,
                team1Logo: hTeam.toLowerCase().contains(effectiveName.toLowerCase())
                    ? effectiveLogo
                    : null,
                team2Logo: aTeam.toLowerCase().contains(effectiveName.toLowerCase())
                    ? effectiveLogo
                    : null,
                leagueId: leagueId,
              );

              final statusLower = mStatus.toLowerCase();
              final isFinished =
                  statusLower.contains('انتهت') ||
                  statusLower.contains('ft') ||
                  statusLower.contains('fin') ||
                  statusLower.contains('ended');

              if (isFinished) {
                recent.add(match);
                final p1 = int.tryParse(s1 ?? '');
                final p2 = int.tryParse(s2 ?? '');
                if (p1 != null && p2 != null) {
                  final isHome = hTeam.toLowerCase().contains(
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
          }

          // Load standings if leagueId is available
          StandingRowEntity? standingRow;
          String? effectiveLeagueTitle;
          if (leagueId != null && leagueId.isNotEmpty) {
            try {
              final standings = await _standingsDataSource.getStandings(
                leagueId,
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
            leagueId: leagueId,
            leagueName: effectiveLeagueTitle,
            country: country,
            upcomingMatches: upcoming,
            recentMatches: recent,
            standingsRow: standingRow,
            form: form.take(5).toList(),
          );
        }
      } catch (_) {
        // Fall back to matches search
      }
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

    // Split upcoming and recent matches
    final upcoming = <MatchEntity>[];
    final recent = <MatchEntity>[];
    final form = <String>[];

    for (final m in allMatches) {
      final status = m.status?.toLowerCase() ?? '';
      final isFinished =
          status.contains('انتهت') ||
          status.contains('ft') ||
          status.contains('fin') ||
          status.contains('ended');

      if (isFinished) {
        recent.add(m);
        // Calculate W/D/L for form
        final s1 = int.tryParse(m.score1 ?? '');
        final s2 = int.tryParse(m.score2 ?? '');
        if (s1 != null && s2 != null) {
          final isHome = m.team1.toLowerCase().contains(
            effectiveName.toLowerCase(),
          );
          final teamScore = isHome ? s1 : s2;
          final oppScore = isHome ? s2 : s1;

          if (teamScore > oppScore) {
            form.add('W');
          } else if (teamScore < oppScore) {
            form.add('L');
          } else {
            form.add('D');
          }
        }
      } else {
        upcoming.add(m);
      }
    }

    // Attempt to load standings row if leagueId is available
    StandingRowEntity? standingRow;
    if (effectiveLeagueId != null && effectiveLeagueId.isNotEmpty) {
      try {
        final standings = await _standingsDataSource.getStandings(
          effectiveLeagueId,
          lang: lang,
        );
        effectiveLeagueTitle ??= standings.leagueTitle;

        final queryName = effectiveName.toLowerCase();
        for (final row in standings.rows) {
          final rName = row.teamName.toLowerCase();
          if (rName == queryName ||
              (queryName.length > 3 && rName.contains(queryName)) ||
              (rName.length > 3 && queryName.contains(rName))) {
            standingRow = row;
            effectiveLogo ??= row.teamLogo;
            break;
          }
        }
      } catch (_) {
        // Gracefully ignore standings lookup failure
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
      standingsRow: standingRow,
      form: form.take(5).toList(),
    );
  }
}
