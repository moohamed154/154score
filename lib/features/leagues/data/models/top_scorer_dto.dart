import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/top_scorer_entity.dart';

class TopScorerDto {
  final int rank;
  final String playerName;
  final String? playerImage;
  final String? teamName;
  final String? teamLogo;
  final String? teamId;
  final int goals;
  final int? assists;
  final int? penaltyGoals;
  final int? matchesPlayed;

  const TopScorerDto({
    required this.rank,
    required this.playerName,
    this.playerImage,
    this.teamName,
    this.teamLogo,
    this.teamId,
    required this.goals,
    this.assists,
    this.penaltyGoals,
    this.matchesPlayed,
  });

  factory TopScorerDto.fromJson(int fallbackRank, Map<String, dynamic> json) {
    final rank =
        int.tryParse(
          json['rank']?.toString() ??
              json['position']?.toString() ??
              json['pos']?.toString() ??
              '',
        ) ??
        fallbackRank;

    String name = 'Player';
    if (json['player_name'] is String) {
      name = json['player_name'].toString();
    } else if (json['name'] != null) {
      name = json['name'].toString();
    } else if (json['player'] is Map) {
      name =
          json['player']['title']?.toString() ??
          json['player']['name']?.toString() ??
          name;
    }

    String? tName;
    String? rawTeamLogo;
    String? tId;

    if (json['team_name'] is String) {
      tName = json['team_name'].toString();
    } else if (json['team'] is Map) {
      tName =
          json['team']['title']?.toString() ?? json['team']['name']?.toString();
      rawTeamLogo =
          json['team']['image']?.toString() ?? json['team']['logo']?.toString();
      tId = json['team']['id']?.toString();
    } else if (json['team'] is String) {
      tName = json['team'].toString();
    }

    rawTeamLogo ??=
        json['team_logo']?.toString() ??
        json['team_image']?.toString() ??
        json['logo']?.toString();
    tId ??= json['team_id']?.toString();

    final rawPlayerImg =
        json['player_image']?.toString() ?? json['image']?.toString();

    final goals =
        int.tryParse(
          json['goals']?.toString() ??
              json['goals_scored']?.toString() ??
              json['goal']?.toString() ??
              '0',
        ) ??
        0;

    final assists = int.tryParse(
      json['assists']?.toString() ?? json['assist']?.toString() ?? '',
    );
    final penalties = int.tryParse(
      json['penalties']?.toString() ??
          json['penalty_goals']?.toString() ??
          json['penalty']?.toString() ??
          '',
    );
    final played = int.tryParse(
      json['matches']?.toString() ??
          json['played']?.toString() ??
          json['matches_played']?.toString() ??
          '',
    );

    return TopScorerDto(
      rank: rank,
      playerName: name,
      playerImage: UrlHelper.normalizeImageUrl(rawPlayerImg),
      teamName: tName,
      teamLogo: UrlHelper.normalizeImageUrl(rawTeamLogo),
      teamId: tId,
      goals: goals,
      assists: assists,
      penaltyGoals: penalties,
      matchesPlayed: played,
    );
  }

  TopScorerEntity toEntity() {
    return TopScorerEntity(
      rank: rank,
      playerName: playerName,
      playerImage: playerImage,
      teamName: teamName,
      teamLogo: teamLogo,
      teamId: teamId,
      goals: goals,
      assists: assists,
      penaltyGoals: penaltyGoals,
      matchesPlayed: matchesPlayed,
    );
  }
}
