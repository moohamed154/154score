import 'package:equatable/equatable.dart';

import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';
import '../../domain/entities/top_scorer_entity.dart';

enum LeagueStatus { initial, loading, success, error }

class LeagueState extends Equatable {
  final LeagueStatus status;
  final String leagueId;
  final String? leagueTitle;
  final String? leagueLogo;
  final String? country;
  final String? season;
  final LeagueStandingsEntity? standings;
  final List<TopScorerEntity> topScorers;
  final List<TopScorerEntity> topAssists;
  final List<MatchEntity> matches;
  final int selectedTab;
  final String? errorMessage;

  const LeagueState({
    this.status = LeagueStatus.initial,
    required this.leagueId,
    this.leagueTitle,
    this.leagueLogo,
    this.country,
    this.season,
    this.standings,
    this.topScorers = const [],
    this.topAssists = const [],
    this.matches = const [],
    this.selectedTab = 0,
    this.errorMessage,
  });

  LeagueState copyWith({
    LeagueStatus? status,
    String? leagueId,
    String? leagueTitle,
    String? leagueLogo,
    String? country,
    String? season,
    LeagueStandingsEntity? standings,
    List<TopScorerEntity>? topScorers,
    List<TopScorerEntity>? topAssists,
    List<MatchEntity>? matches,
    int? selectedTab,
    String? errorMessage,
  }) {
    return LeagueState(
      status: status ?? this.status,
      leagueId: leagueId ?? this.leagueId,
      leagueTitle: leagueTitle ?? this.leagueTitle,
      leagueLogo: leagueLogo ?? this.leagueLogo,
      country: country ?? this.country,
      season: season ?? this.season,
      standings: standings ?? this.standings,
      topScorers: topScorers ?? this.topScorers,
      topAssists: topAssists ?? this.topAssists,
      matches: matches ?? this.matches,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    leagueId,
    leagueTitle,
    leagueLogo,
    country,
    season,
    standings,
    topScorers,
    topAssists,
    matches,
    selectedTab,
    errorMessage,
  ];
}
