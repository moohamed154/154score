import 'package:equatable/equatable.dart';

import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import 'top_scorer_entity.dart';

class LeagueDetailsEntity extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String? country;
  final String? season;
  final LeagueStandingsEntity? standings;
  final List<TopScorerEntity> topScorers;
  final List<TopScorerEntity> topAssists;
  final List<MatchEntity> matches;

  const LeagueDetailsEntity({
    required this.id,
    required this.name,
    this.logo,
    this.country,
    this.season,
    this.standings,
    this.topScorers = const [],
    this.topAssists = const [],
    this.matches = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        logo,
        country,
        season,
        standings,
        topScorers,
        topAssists,
        matches,
      ];
}
