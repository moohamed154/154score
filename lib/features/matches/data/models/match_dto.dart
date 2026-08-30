import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/match_entity.dart';

class MatchDto {
  final String? id;
  final String team1;
  final String team2;
  final String? team1Logo;
  final String? team2Logo;
  final String? team1Id;
  final String? team2Id;
  final String? score1;
  final String? score2;
  final String? penaltyScore1;
  final String? penaltyScore2;
  final String? halfTimeScore1;
  final String? halfTimeScore2;
  final String? extraTimeScore1;
  final String? extraTimeScore2;
  final String? aggregateScore1;
  final String? aggregateScore2;
  final String? time;
  final String? status;
  final String? statusCode;
  final String? minute;
  final String? period;
  final String? extraTime;
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
    this.team1Id,
    this.team2Id,
    this.score1,
    this.score2,
    this.penaltyScore1,
    this.penaltyScore2,
    this.halfTimeScore1,
    this.halfTimeScore2,
    this.extraTimeScore1,
    this.extraTimeScore2,
    this.aggregateScore1,
    this.aggregateScore2,
    this.time,
    this.status,
    this.statusCode,
    this.minute,
    this.period,
    this.extraTime,
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
    // 1. Team Names & IDs
    Map? homeTeamMap;
    Map? awayTeamMap;
    if (json['teams'] is Map) {
      if (json['teams']['home'] is Map) {
        homeTeamMap = json['teams']['home'] as Map;
      }
      if (json['teams']['away'] is Map) {
        awayTeamMap = json['teams']['away'] as Map;
      }
    }

    final t1 =
        json['team_1']?.toString() ??
        homeTeamMap?['name']?.toString() ??
        json['home_team']?.toString() ??
        'Team 1';
    final t2 =
        json['team_2']?.toString() ??
        awayTeamMap?['name']?.toString() ??
        json['away_team']?.toString() ??
        'Team 2';

    final t1Id =
        json['team_1_id']?.toString() ??
        homeTeamMap?['id']?.toString() ??
        json['home_team_id']?.toString();
    final t2Id =
        json['team_2_id']?.toString() ??
        awayTeamMap?['id']?.toString() ??
        json['away_team_id']?.toString();

    // 2. Stable Match ID
    final rawId =
        json['match_id']?.toString() ??
        json['id']?.toString() ??
        json['id_match']?.toString();
    final effectiveId = (rawId != null && rawId.isNotEmpty && rawId != 'null')
        ? rawId
        : '${t1}_${t2}_${date ?? ""}';

    // 3. Team Logos (normalized)
    final rawLogo1 =
        json['team_1_logo']?.toString() ??
        homeTeamMap?['logo']?.toString() ??
        homeTeamMap?['image']?.toString() ??
        json['home_logo']?.toString();
    final rawLogo2 =
        json['team_2_logo']?.toString() ??
        awayTeamMap?['logo']?.toString() ??
        awayTeamMap?['image']?.toString() ??
        json['away_logo']?.toString();

    final logo1 = UrlHelper.normalizeImageUrl(rawLogo1);
    final logo2 = UrlHelper.normalizeImageUrl(rawLogo2);

    // 4. Main Match Scores
    String? s1;
    String? s2;

    if (json['score'] is Map) {
      final sMap = json['score'] as Map;
      if (sMap['home'] != null) s1 = sMap['home'].toString();
      if (sMap['away'] != null) s2 = sMap['away'].toString();
    }
    s1 ??= json['score_1']?.toString() ?? json['home_score']?.toString();
    s2 ??= json['score_2']?.toString() ?? json['away_score']?.toString();

    if (s1 == 'null') s1 = null;
    if (s2 == 'null') s2 = null;

    String? rawStatus = json['status']?.toString().trim();
    String? rawTime = json['time']?.toString().trim();

    // Check if rawStatus contains kick-off time (e.g. "10:00م", "02:30م", "10:00", "05:00 م")
    final timePattern = RegExp(r'^(\d{1,2}:\d{2})\s*([صم]|AM|PM|am|pm)?$');
    final timeMatch = rawStatus != null ? timePattern.firstMatch(rawStatus) : null;

    if (timeMatch != null) {
      final digits = timeMatch.group(1)!;
      final period = timeMatch.group(2);
      rawTime = period != null ? '$digits $period' : digits;
      rawStatus = 'لم تبدأ';
      s1 = null;
      s2 = null;
    } else if (rawStatus != null && (s1 == null || s2 == null)) {
      // Only extract scores if status contains explicit finished keywords with hyphen '-'
      final scorePattern = RegExp(r'(\d+)\s*[-–]\s*(\d+)');
      final scoreMatch = scorePattern.firstMatch(rawStatus);
      if (scoreMatch != null &&
          (rawStatus.contains('انتهت') ||
              rawStatus.contains('FT') ||
              rawStatus.contains('مباراة'))) {
        s1 ??= scoreMatch.group(1);
        s2 ??= scoreMatch.group(2);
        rawStatus = 'انتهت';
      }
    }

    // 5. Penalty Shootout Scores
    String? pen1;
    String? pen2;
    if (json['score'] is Map && json['score']['penalties'] is Map) {
      final pMap = json['score']['penalties'] as Map;
      if (pMap['home'] != null) pen1 = pMap['home'].toString();
      if (pMap['away'] != null) pen2 = pMap['away'].toString();
    }
    pen1 ??=
        json['penalty_score_1']?.toString() ??
        json['penalties_1']?.toString() ??
        json['penalties_home']?.toString() ??
        (json['penalties'] is Map
            ? json['penalties']['home']?.toString()
            : null);
    pen2 ??=
        json['penalty_score_2']?.toString() ??
        json['penalties_2']?.toString() ??
        json['penalties_away']?.toString() ??
        (json['penalties'] is Map
            ? json['penalties']['away']?.toString()
            : null);

    if (pen1 == 'null') pen1 = null;
    if (pen2 == 'null') pen2 = null;

    // 6. Half-Time Scores
    String? ht1;
    String? ht2;
    if (json['score'] is Map && json['score']['half_time'] is Map) {
      final htMap = json['score']['half_time'] as Map;
      if (htMap['home'] != null) ht1 = htMap['home'].toString();
      if (htMap['away'] != null) ht2 = htMap['away'].toString();
    }
    ht1 ??=
        json['half_time_score_1']?.toString() ??
        json['ht_score_1']?.toString() ??
        (json['half_time'] is Map
            ? json['half_time']['home']?.toString()
            : null);
    ht2 ??=
        json['half_time_score_2']?.toString() ??
        json['ht_score_2']?.toString() ??
        (json['half_time'] is Map
            ? json['half_time']['away']?.toString()
            : null);

    if (ht1 == 'null') ht1 = null;
    if (ht2 == 'null') ht2 = null;

    // 7. Extra-Time Scores
    String? et1;
    String? et2;
    if (json['score'] is Map && json['score']['extra_time'] is Map) {
      final etMap = json['score']['extra_time'] as Map;
      if (etMap['home'] != null) et1 = etMap['home'].toString();
      if (etMap['away'] != null) et2 = etMap['away'].toString();
    }
    et1 ??=
        json['extra_time_score_1']?.toString() ??
        (json['extra_time'] is Map
            ? json['extra_time']['home']?.toString()
            : null);
    et2 ??=
        json['extra_time_score_2']?.toString() ??
        (json['extra_time'] is Map
            ? json['extra_time']['away']?.toString()
            : null);

    if (et1 == 'null') et1 = null;
    if (et2 == 'null') et2 = null;

    // 8. League info
    Map? leagueMap;
    if (json['league'] is Map) {
      leagueMap = json['league'] as Map;
    }

    final lTitle =
        leagueTitle ??
        json['league_title']?.toString() ??
        leagueMap?['name']?.toString() ??
        json['league_name']?.toString();

    final rawLLogo =
        leagueLogo ??
        json['league_logo']?.toString() ??
        leagueMap?['logo']?.toString();
    final lLogo = UrlHelper.normalizeImageUrl(rawLLogo);

    final lId =
        leagueId ??
        json['league_id']?.toString() ??
        leagueMap?['id']?.toString();

    return MatchDto(
      id: effectiveId,
      team1: t1,
      team2: t2,
      team1Logo: logo1,
      team2Logo: logo2,
      team1Id: t1Id,
      team2Id: t2Id,
      score1: s1,
      score2: s2,
      penaltyScore1: pen1,
      penaltyScore2: pen2,
      halfTimeScore1: ht1,
      halfTimeScore2: ht2,
      extraTimeScore1: et1,
      extraTimeScore2: et2,
      time: (rawTime != null && rawTime.isNotEmpty && rawTime != 'null') ? rawTime : '-',
      status: rawStatus ?? 'Not Started',
      statusCode: json['status_code']?.toString(),
      minute: json['minute']?.toString(),
      period: json['period']?.toString(),
      extraTime: json['extra_time']?.toString(),
      leagueTitle: lTitle,
      leagueLogo: lLogo,
      leagueId: lId,
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
      team1Id: team1Id,
      team2Id: team2Id,
      score1: score1,
      score2: score2,
      penaltyScore1: penaltyScore1,
      penaltyScore2: penaltyScore2,
      halfTimeScore1: halfTimeScore1,
      halfTimeScore2: halfTimeScore2,
      extraTimeScore1: extraTimeScore1,
      extraTimeScore2: extraTimeScore2,
      aggregateScore1: aggregateScore1,
      aggregateScore2: aggregateScore2,
      time: time,
      status: status,
      statusCode: statusCode,
      minute: minute,
      period: period,
      extraTime: extraTime,
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
    final title =
        json['league_title']?.toString() ??
        json['title']?.toString() ??
        json['name']?.toString() ??
        'Competition';
    final rawLogo = json['league_logo']?.toString() ?? json['logo']?.toString();
    final logo = UrlHelper.normalizeImageUrl(rawLogo);
    final id = json['league_id']?.toString() ?? json['id']?.toString();

    final rawMatches = json['matches'] as List? ?? [];
    final matchesList = rawMatches.map((m) {
      if (m is Map<String, dynamic>) {
        return MatchDto.fromJson(
          m,
          leagueTitle: title,
          leagueLogo: logo,
          leagueId: id,
          date: date,
        );
      }
      return MatchDto(
        team1: 'Team 1',
        team2: 'Team 2',
        leagueTitle: title,
        leagueLogo: logo,
        leagueId: id,
        date: date,
      );
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
      matches: matches
          .map((m) => m.toEntity(isFavorite: favoriteMatches.contains(m.id)))
          .toList(),
    );
  }
}
