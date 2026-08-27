import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/standings_entity.dart';

class StandingRowDto {
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
  final String? groupName;

  const StandingRowDto({
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
    this.groupName,
  });

  factory StandingRowDto.fromJson(
    int pos,
    Map<String, dynamic> json, {
    String? groupName,
  }) {
    String name = 'Team';
    String? rawLogo;

    if (json['team_name'] is String) {
      name = json['team_name'].toString();
    } else if (json['team_name'] is Map) {
      final tMap = json['team_name'] as Map;
      name =
          tMap['short_title']?.toString() ??
          tMap['title']?.toString() ??
          tMap['full_title']?.toString() ??
          name;
      rawLogo = tMap['image']?.toString() ?? tMap['logo']?.toString();
    } else if (json['name'] != null) {
      name = json['name'].toString();
    }

    rawLogo ??=
        json['team_logo']?.toString() ??
        json['logo']?.toString() ??
        json['image']?.toString();
    final logo = UrlHelper.normalizeImageUrl(rawLogo);

    final position = int.tryParse(json['position']?.toString() ?? '') ?? pos;
    final played =
        int.tryParse(
          json['played']?.toString() ?? json['play']?.toString() ?? '0',
        ) ??
        0;
    final wins = int.tryParse(json['wins']?.toString() ?? '0') ?? 0;
    final draws =
        int.tryParse(
          json['draws']?.toString() ?? json['draw']?.toString() ?? '0',
        ) ??
        0;
    final losses =
        int.tryParse(
          json['losses']?.toString() ?? json['lose']?.toString() ?? '0',
        ) ??
        0;
    final goalsFor =
        int.tryParse(
          json['goals_for']?.toString() ?? json['for']?.toString() ?? '0',
        ) ??
        0;
    final goalsAgainst =
        int.tryParse(
          json['goals_against']?.toString() ??
              json['against']?.toString() ??
              '0',
        ) ??
        0;
    final goalDiff =
        int.tryParse(
          json['goal_difference']?.toString() ??
              json['diff']?.toString() ??
              '0',
        ) ??
        0;
    final points = int.tryParse(json['points']?.toString() ?? '0') ?? 0;
    final group =
        groupName ??
        json['group_name']?.toString() ??
        json['group']?.toString();

    return StandingRowDto(
      position: position,
      teamName: name,
      teamLogo: logo,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDiff: goalDiff,
      points: points,
      rankColor: json['color']?.toString(),
      groupName: group,
    );
  }

  StandingRowEntity toEntity() {
    return StandingRowEntity(
      position: position,
      teamName: teamName,
      teamLogo: teamLogo,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDiff: goalDiff,
      points: points,
      rankColor: rankColor,
      groupName: groupName,
    );
  }
}
