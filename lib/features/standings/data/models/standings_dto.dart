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
  });

  factory StandingRowDto.fromJson(int pos, Map<String, dynamic> json) {
    String name = json['name']?.toString() ?? 'Team';
    String? logo;

    if (json['team_name'] is Map) {
      final tMap = json['team_name'] as Map;
      name = tMap['short_title']?.toString() ??
          tMap['title']?.toString() ??
          tMap['full_title']?.toString() ??
          name;
      logo = tMap['image']?.toString();
    }

    return StandingRowDto(
      position: pos,
      teamName: name,
      teamLogo: logo,
      played: int.tryParse(json['play']?.toString() ?? '0') ?? 0,
      wins: int.tryParse(json['wins']?.toString() ?? '0') ?? 0,
      draws: int.tryParse(json['draw']?.toString() ?? '0') ?? 0,
      losses: int.tryParse(json['lose']?.toString() ?? '0') ?? 0,
      goalsFor: int.tryParse(json['for']?.toString() ?? '0') ?? 0,
      goalsAgainst: int.tryParse(json['against']?.toString() ?? '0') ?? 0,
      goalDiff: int.tryParse(json['diff']?.toString() ?? '0') ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      rankColor: json['color']?.toString(),
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
    );
  }
}
