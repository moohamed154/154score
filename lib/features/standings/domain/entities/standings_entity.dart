import 'package:equatable/equatable.dart';

class StandingRowEntity extends Equatable {
  final int position;
  final String teamName;
  final String? teamLogo;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;
  final String? rankColor;

  const StandingRowEntity({
    required this.position,
    required this.teamName,
    this.teamLogo,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
    this.rankColor,
  });

  @override
  List<Object?> get props => [
    position,
    teamName,
    teamLogo,
    played,
    wins,
    draws,
    losses,
    goalsFor,
    goalsAgainst,
    goalDiff,
    points,
    rankColor,
  ];
}

class LeagueStandingsEntity extends Equatable {
  final String leagueId;
  final String leagueTitle;
  final List<StandingRowEntity> rows;

  const LeagueStandingsEntity({
    required this.leagueId,
    required this.leagueTitle,
    required this.rows,
  });

  @override
  List<Object?> get props => [leagueId, leagueTitle, rows];
}
