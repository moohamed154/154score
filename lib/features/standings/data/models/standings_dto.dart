import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/standings_entity.dart';

class StandingRowDto {
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

  const StandingRowDto({
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

  factory StandingRowDto.fromJson(
    int pos,
    Map<String, dynamic> json, {
    String? groupName,
  }) {
    String name = '';
    String? rawLogo;
    String? teamId;

    if (json['team_name'] is String &&
        json['team_name'].toString().trim().isNotEmpty) {
      name = json['team_name'].toString().trim();
    } else if (json['team_name'] is Map) {
      final tMap = json['team_name'] as Map;
      name =
          tMap['short_title']?.toString() ??
          tMap['title']?.toString() ??
          tMap['full_title']?.toString() ??
          '';
      rawLogo = tMap['image']?.toString() ?? tMap['logo']?.toString();
      teamId = tMap['row_id']?.toString() ?? tMap['id']?.toString();
    }

    if (name.isEmpty && json['team'] is Map) {
      final tMap = json['team'] as Map;
      name =
          tMap['name']?.toString() ??
          tMap['title']?.toString() ??
          tMap['short_name']?.toString() ??
          tMap['full_title']?.toString() ??
          '';
      rawLogo ??= tMap['logo']?.toString() ?? tMap['image']?.toString();
      teamId ??= tMap['id']?.toString() ?? tMap['row_id']?.toString();
    }

    if (name.isEmpty &&
        json['team'] is String &&
        json['team'].toString().trim().isNotEmpty) {
      name = json['team'].toString().trim();
    }

    if (name.isEmpty &&
        json['name'] != null &&
        json['name'].toString().trim().isNotEmpty) {
      name = json['name'].toString().trim();
    }

    if (name.isEmpty &&
        json['title'] != null &&
        json['title'].toString().trim().isNotEmpty) {
      name = json['title'].toString().trim();
    }

    if (name.isEmpty) {
      name = 'Team $pos';
    }

    teamId ??= json['team_id']?.toString() ?? json['id']?.toString();

    rawLogo ??=
        json['team_logo']?.toString() ??
        json['logo']?.toString() ??
        json['image']?.toString() ??
        json['team_image']?.toString();

    var logo = UrlHelper.normalizeImageUrl(rawLogo);
    if ((logo == null || logo.isEmpty) && teamId != null && teamId.isNotEmpty) {
      logo = UrlHelper.resolveTeamLogo(teamId);
    }

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
      teamId: teamId,
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
      teamId: teamId,
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
