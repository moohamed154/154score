import 'package:equatable/equatable.dart';

import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';

class TeamProfileEntity extends Equatable {
  final String teamId;
  final String teamName;
  final String? teamLogo;
  final String? leagueId;
  final String? leagueName;
  final String? country;
  final List<MatchEntity> upcomingMatches;
  final List<MatchEntity> recentMatches;
  final StandingRowEntity? standingsRow;
  final List<String> form;

  const TeamProfileEntity({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.leagueId,
    this.leagueName,
    this.country,
    this.upcomingMatches = const [],
    this.recentMatches = const [],
    this.standingsRow,
    this.form = const [],
  });

  @override
  List<Object?> get props => [
    teamId,
    teamName,
    teamLogo,
    leagueId,
    leagueName,
    country,
    upcomingMatches,
    recentMatches,
    standingsRow,
    form,
  ];
}
