import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/top_scorer_entity.dart';

class TopScorerDto {
  final int rank;
  final String playerName;
  final String? playerImage;
  final String? teamName;
  final String? teamLogo;
  final String? teamId;
  final String? playerId;
  final int goals;
  final int? assists;
  final int? penaltyGoals;
  final int? penaltiesMissed;
  final int? matchesPlayed;

  const TopScorerDto({
    required this.rank,
    required this.playerName,
    this.playerImage,
    this.teamName,
    this.teamLogo,
    this.teamId,
    this.playerId,
    required this.goals,
    this.assists,
    this.penaltyGoals,
    this.penaltiesMissed,
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
        json['player_photo']?.toString() ??
        json['player_image']?.toString() ??
        json['photo']?.toString() ??
        json['image']?.toString() ??
        (json['player'] is Map
            ? (json['player']['photo']?.toString() ??
                  json['player']['image']?.toString())
            : null);

    final playerId =
        json['player_id']?.toString() ??
        json['id']?.toString() ??
        (json['player'] is Map ? json['player']['id']?.toString() : null);

    final goals =
        int.tryParse(
          json['goals']?.toString() ??
              json['goals_scored']?.toString() ??
              json['goal']?.toString() ??
              '0',
        ) ??
        0;

    final assists = int.tryParse(
      json['assists']?.toString() ??
          json['assist']?.toString() ??
          json['count']?.toString() ??
          '',
    );
    final penalties = int.tryParse(
      json['penalties_scored']?.toString() ??
          json['penalties']?.toString() ??
          json['penalty_goals']?.toString() ??
          json['penalty']?.toString() ??
          '',
    );
    final penaltiesMissed = int.tryParse(
      json['penalties_missed']?.toString() ??
          json['missed_penalties']?.toString() ??
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
      playerId: playerId,
      goals: goals,
      assists: assists,
      penaltyGoals: penalties,
      penaltiesMissed: penaltiesMissed,
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
      playerId: playerId,
      goals: goals,
      assists: assists,
      penaltyGoals: penaltyGoals,
      penaltiesMissed: penaltiesMissed,
      matchesPlayed: matchesPlayed,
    );
  }
}
