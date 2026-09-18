import 'package:equatable/equatable.dart';

class StandingLegendEntity extends Equatable {
  final String colorHex;
  final String description;

  const StandingLegendEntity({
    required this.colorHex,
    required this.description,
  });

  @override
  List<Object?> get props => [colorHex, description];
}

class StandingRowEntity extends Equatable {
  final int position;
  final String teamName;
  final String? teamId;
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
  final String? groupName;

  const StandingRowEntity({
    required this.position,
    required this.teamName,
    this.teamId,
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
    this.groupName,
  });

  @override
  List<Object?> get props => [
    position,
    teamName,
    teamId,
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
    groupName,
  ];
}

class LeagueStandingsEntity extends Equatable {
  final String leagueId;
  final String leagueTitle;
  final List<StandingRowEntity> rows;
  final Map<String, List<StandingRowEntity>>? groups;
  final List<StandingLegendEntity>? legends;

  const LeagueStandingsEntity({
    required this.leagueId,
    required this.leagueTitle,
    required this.rows,
    this.groups,
    this.legends,
  });

  bool get hasMultipleGroups => groups != null && groups!.length > 1;

  @override
  List<Object?> get props => [leagueId, leagueTitle, rows, groups, legends];
}
