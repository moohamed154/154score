import 'package:equatable/equatable.dart';

class TopScorerEntity extends Equatable {
  final int rank;
  final String playerName;
  final String? playerImage;
  final String? teamName;
  final String? teamLogo;
  final String? teamId;
  final int goals;
  final int? assists;
  final String? playerId;
  final int? penaltyGoals;
  final int? penaltiesMissed;
  final int? matchesPlayed;

  const TopScorerEntity({
    required this.rank,
    required this.playerName,
    this.playerImage,
    this.teamName,
    this.teamLogo,
    this.teamId,
    required this.goals,
    this.assists,
    this.playerId,
    this.penaltyGoals,
    this.penaltiesMissed,
    this.matchesPlayed,
  });

  @override
  List<Object?> get props => [
        rank,
        playerName,
        playerImage,
        teamName,
        teamLogo,
        teamId,
        goals,
        assists,
        playerId,
        penaltyGoals,
        penaltiesMissed,
        matchesPlayed,
      ];
}
