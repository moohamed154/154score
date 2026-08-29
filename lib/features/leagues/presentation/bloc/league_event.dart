import 'package:equatable/equatable.dart';

abstract class LeagueEvent extends Equatable {
  const LeagueEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeagueDetailsEvent extends LeagueEvent {
  final String leagueId;
  final bool isRefresh;

  const LoadLeagueDetailsEvent(this.leagueId, {this.isRefresh = false});

  @override
  List<Object?> get props => [leagueId, isRefresh];
}

class ChangeLeagueTabEvent extends LeagueEvent {
  final int tabIndex;

  const ChangeLeagueTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class LeagueLiveMatchReceivedEvent extends LeagueEvent {
  final dynamic update;

  const LeagueLiveMatchReceivedEvent(this.update);

  @override
  List<Object?> get props => [update];
}
