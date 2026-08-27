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
  final LeagueStandingsEntity? standings;
  final List<TopScorerEntity> topScorers;
  final List<MatchEntity> matches;
  final int selectedTab;
  final String? errorMessage;

  const LeagueState({
    this.status = LeagueStatus.initial,
    required this.leagueId,
    this.leagueTitle,
    this.leagueLogo,
    this.standings,
    this.topScorers = const [],
    this.matches = const [],
    this.selectedTab = 0,
    this.errorMessage,
  });

  LeagueState copyWith({
    LeagueStatus? status,
    String? leagueId,
    String? leagueTitle,
    String? leagueLogo,
    LeagueStandingsEntity? standings,
    List<TopScorerEntity>? topScorers,
    List<MatchEntity>? matches,
    int? selectedTab,
    String? errorMessage,
  }) {
    return LeagueState(
      status: status ?? this.status,
      leagueId: leagueId ?? this.leagueId,
      leagueTitle: leagueTitle ?? this.leagueTitle,
      leagueLogo: leagueLogo ?? this.leagueLogo,
      standings: standings ?? this.standings,
      topScorers: topScorers ?? this.topScorers,
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
    standings,
    topScorers,
    matches,
    selectedTab,
    errorMessage,
  ];
}
