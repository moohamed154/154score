import 'package:equatable/equatable.dart';

abstract class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamProfileEvent extends TeamEvent {
  final String teamId;
  final String? teamName;
  final String? leagueId;
  final bool isRefresh;

  const LoadTeamProfileEvent(
    this.teamId, {
    this.teamName,
    this.leagueId,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [teamId, teamName, leagueId, isRefresh];
}

class ChangeTeamTabEvent extends TeamEvent {
  final int tabIndex;

  const ChangeTeamTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}
