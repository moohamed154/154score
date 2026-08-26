import 'package:equatable/equatable.dart';

class MatchEntity extends Equatable {
  final String id;
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
  final bool isFavorite;

  const MatchEntity({
    required this.id,
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
    this.isFavorite = false,
  });

  MatchEntity copyWith({
    String? id,
    String? team1,
    String? team2,
    String? team1Logo,
    String? team2Logo,
    String? score1,
    String? score2,
    String? time,
    String? status,
    String? minute,
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
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      time: time ?? this.time,
      status: status ?? this.status,
      minute: minute ?? this.minute,
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
        score1,
        score2,
        time,
        status,
        minute,
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
