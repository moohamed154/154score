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

class StageTeamEntity extends Equatable {
  final String? id;
  final String name;
  final String? logo;
  final int? score;
  final bool isWinner;
  final int? worldRanking;

  const StageTeamEntity({
    this.id,
    required this.name,
    this.logo,
    this.score,
    this.isWinner = false,
    this.worldRanking,
  });

  @override
  List<Object?> get props => [id, name, logo, score, isWinner, worldRanking];
}

class StageMatchEntity extends Equatable {
  final String? matchId;
  final String? position;
  final String? teamGroup;
  final StageTeamEntity teamA;
  final StageTeamEntity teamB;
  final String? winnerId;
  final String? matchDate;
  final String? matchTime;

  const StageMatchEntity({
    this.matchId,
    this.position,
    this.teamGroup,
    required this.teamA,
    required this.teamB,
    this.winnerId,
    this.matchDate,
    this.matchTime,
  });

  @override
  List<Object?> get props => [
    matchId,
    position,
    teamGroup,
    teamA,
    teamB,
    winnerId,
    matchDate,
    matchTime,
  ];
}

class TournamentStageEntity extends Equatable {
  final String stageName;
  final String? stageId;
  final int? round;
  final int? teamsNumber;
  final List<StageMatchEntity> matches;

  const TournamentStageEntity({
    required this.stageName,
    this.stageId,
    this.round,
    this.teamsNumber,
    required this.matches,
  });

  @override
  List<Object?> get props => [stageName, stageId, round, teamsNumber, matches];
}

class LeagueStandingsEntity extends Equatable {
  final String leagueId;
  final String leagueTitle;
  final List<StandingRowEntity> rows;
  final Map<String, List<StandingRowEntity>>? groups;
  final List<TournamentStageEntity>? stages;
  final List<StandingLegendEntity>? legends;
  final List<String>? rulesList;

  const LeagueStandingsEntity({
    required this.leagueId,
    required this.leagueTitle,
    required this.rows,
    this.groups,
    this.stages,
    this.legends,
    this.rulesList,
  });

  bool get hasMultipleGroups => groups != null && groups!.length > 1;
  bool get hasStages => stages != null && stages!.isNotEmpty;
  bool get isKnockoutOnly =>
      hasStages && rows.isEmpty && (groups == null || groups!.isEmpty);
  bool get hasBothGroupsAndStages =>
      hasStages && (hasMultipleGroups || rows.isNotEmpty);

  @override
  List<Object?> get props => [
    leagueId,
    leagueTitle,
    rows,
    groups,
    stages,
    legends,
    rulesList,
  ];
}
