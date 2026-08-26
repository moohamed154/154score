import '../../domain/entities/match_entity.dart';

class MatchDto {
  final String? id;
  final String team1;
  final String team2;
  final String? team1Logo;
  final String? team2Logo;
  final String? score1;
  final String? score2;
  final String? time;
  final String? status;
  final String? minute;
  final String? leagueTitle;
  final String? leagueLogo;
  final String? leagueId;
  final String? date;

  const MatchDto({
    this.id,
    required this.team1,
    required this.team2,
    this.team1Logo,
    this.team2Logo,
    this.score1,
    this.score2,
    this.time,
    this.status,
    this.minute,
    this.leagueTitle,
    this.leagueLogo,
    this.leagueId,
    this.date,
  });

  factory MatchDto.fromJson(
    Map<String, dynamic> json, {
    String? leagueTitle,
    String? leagueLogo,
    String? leagueId,
    String? date,
  }) {
    final t1 = json['team_1']?.toString() ?? json['home_team']?.toString() ?? 'Team 1';
    final t2 = json['team_2']?.toString() ?? json['away_team']?.toString() ?? 'Team 2';
    
    // Create a stable synthetic ID if not present in the payload
    final rawId = json['id']?.toString() ?? json['match_id']?.toString();
    final effectiveId = rawId ?? '${t1}_${t2}_${date ?? ""}';

    return MatchDto(
      id: effectiveId,
      team1: t1,
      team2: t2,
      team1Logo: json['team_1_logo']?.toString() ?? json['home_logo']?.toString(),
      team2Logo: json['team_2_logo']?.toString() ?? json['away_logo']?.toString(),
      score1: json['score_1']?.toString() ?? json['home_score']?.toString(),
      score2: json['score_2']?.toString() ?? json['away_score']?.toString(),
      time: json['time']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Not Started',
      minute: json['minute']?.toString(),
      leagueTitle: leagueTitle ?? json['league_title']?.toString(),
      leagueLogo: leagueLogo ?? json['league_logo']?.toString(),
      leagueId: leagueId ?? json['league_id']?.toString(),
      date: date ?? json['date']?.toString(),
    );
  }

  MatchEntity toEntity({bool isFavorite = false}) {
    return MatchEntity(
      id: id ?? '${team1}_$team2',
      team1: team1,
      team2: team2,
      team1Logo: team1Logo,
      team2Logo: team2Logo,
      score1: score1,
      score2: score2,
      time: time,
      status: status,
      minute: minute,
      leagueTitle: leagueTitle,
      leagueLogo: leagueLogo,
      leagueId: leagueId,
      date: date,
      isFavorite: isFavorite,
    );
  }
}

class LeagueGroupDto {
  final String leagueTitle;
  final String? leagueLogo;
  final String? leagueId;
  final List<MatchDto> matches;

  const LeagueGroupDto({
    required this.leagueTitle,
    this.leagueLogo,
    this.leagueId,
    required this.matches,
  });

  factory LeagueGroupDto.fromJson(Map<String, dynamic> json, {String? date}) {
    final title = json['league_title']?.toString() ?? json['title']?.toString() ?? 'Competition';
    final logo = json['league_logo']?.toString() ?? json['logo']?.toString();
    final id = json['league_id']?.toString() ?? json['id']?.toString();

    final rawMatches = json['matches'] as List? ?? [];
    final matchesList = rawMatches.map((m) {
      if (m is Map<String, dynamic>) {
        return MatchDto.fromJson(m, leagueTitle: title, leagueLogo: logo, leagueId: id, date: date);
      }
      return MatchDto(team1: 'Team 1', team2: 'Team 2', leagueTitle: title, date: date);
    }).toList();

    return LeagueGroupDto(
      leagueTitle: title,
      leagueLogo: logo,
      leagueId: id,
      matches: matchesList,
    );
  }

  LeagueGroupEntity toEntity({List<String> favoriteMatches = const []}) {
    return LeagueGroupEntity(
      leagueTitle: leagueTitle,
      leagueLogo: leagueLogo,
      leagueId: leagueId,
      matches: matches.map((m) => m.toEntity(isFavorite: favoriteMatches.contains(m.id))).toList(),
    );
  }
}
