import 'package:equatable/equatable.dart';

class MatchEntity extends Equatable {
  final String id;
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
  final bool isFavorite;

  const MatchEntity({
    required this.id,
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
    this.isFavorite = false,
  });

  bool get hasPenalties =>
      (penaltyScore1 != null && penaltyScore1!.isNotEmpty) ||
      (penaltyScore2 != null && penaltyScore2!.isNotEmpty);

  bool get hasHalfTimeScore =>
      (halfTimeScore1 != null && halfTimeScore1!.isNotEmpty) ||
      (halfTimeScore2 != null && halfTimeScore2!.isNotEmpty);

  bool get hasExtraTimeScore =>
      (extraTimeScore1 != null && extraTimeScore1!.isNotEmpty) ||
      (extraTimeScore2 != null && extraTimeScore2!.isNotEmpty);

  MatchEntity copyWith({
    String? id,
    String? team1,
    String? team2,
    String? team1Logo,
    String? team2Logo,
    String? team1Id,
    String? team2Id,
    String? score1,
    String? score2,
    String? penaltyScore1,
    String? penaltyScore2,
    String? halfTimeScore1,
    String? halfTimeScore2,
    String? extraTimeScore1,
    String? extraTimeScore2,
    String? aggregateScore1,
    String? aggregateScore2,
    String? time,
    String? status,
    String? statusCode,
    String? minute,
    String? period,
    String? extraTime,
    String? leagueTitle,
    String? leagueLogo,
    String? leagueId,
    String? date,
    bool? isFavorite,
  }) {
    return MatchEntity(
      id: id ?? this.id,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      team1Logo: team1Logo ?? this.team1Logo,
      team2Logo: team2Logo ?? this.team2Logo,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      penaltyScore1: penaltyScore1 ?? this.penaltyScore1,
      penaltyScore2: penaltyScore2 ?? this.penaltyScore2,
      halfTimeScore1: halfTimeScore1 ?? this.halfTimeScore1,
      halfTimeScore2: halfTimeScore2 ?? this.halfTimeScore2,
      extraTimeScore1: extraTimeScore1 ?? this.extraTimeScore1,
      extraTimeScore2: extraTimeScore2 ?? this.extraTimeScore2,
      aggregateScore1: aggregateScore1 ?? this.aggregateScore1,
      aggregateScore2: aggregateScore2 ?? this.aggregateScore2,
      time: time ?? this.time,
      status: status ?? this.status,
      statusCode: statusCode ?? this.statusCode,
      minute: minute ?? this.minute,
      period: period ?? this.period,
      extraTime: extraTime ?? this.extraTime,
      leagueTitle: leagueTitle ?? this.leagueTitle,
      leagueLogo: leagueLogo ?? this.leagueLogo,
      leagueId: leagueId ?? this.leagueId,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
    id,
    team1,
    team2,
    team1Logo,
    team2Logo,
    team1Id,
    team2Id,
    score1,
    score2,
    penaltyScore1,
    penaltyScore2,
    halfTimeScore1,
    halfTimeScore2,
    extraTimeScore1,
    extraTimeScore2,
    aggregateScore1,
    aggregateScore2,
    time,
    status,
    statusCode,
    minute,
    period,
    extraTime,
    leagueTitle,
    leagueLogo,
    leagueId,
    date,
    isFavorite,
  ];
}

class LeagueGroupEntity extends Equatable {
  final String leagueTitle;
  final String? leagueLogo;
  final String? leagueId;
  final List<MatchEntity> matches;

  const LeagueGroupEntity({
    required this.leagueTitle,
    this.leagueLogo,
    this.leagueId,
    required this.matches,
  });

  LeagueGroupEntity copyWith({
    String? leagueTitle,
    String? leagueLogo,
    String? leagueId,
    List<MatchEntity>? matches,
  }) {
    return LeagueGroupEntity(
      leagueTitle: leagueTitle ?? this.leagueTitle,
      leagueLogo: leagueLogo ?? this.leagueLogo,
      leagueId: leagueId ?? this.leagueId,
      matches: matches ?? this.matches,
    );
  }

  @override
  List<Object?> get props => [leagueTitle, leagueLogo, leagueId, matches];
}
