import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../../core/websocket/websocket_event.dart';

enum MatchFilterType { all, live, upcoming, finished, favorites }

enum MatchesSortOrder { importance, time, league }

extension MatchFilterTypeX on MatchFilterType {
  String? toApiString() {
    return switch (this) {
      MatchFilterType.all => 'all',
      MatchFilterType.live => 'live',
      MatchFilterType.upcoming => 'upcoming',
      MatchFilterType.finished => 'finished',
      MatchFilterType.favorites => null,
    };
  }
}

extension MatchesSortOrderX on MatchesSortOrder {
  String toApiString() {
    return switch (this) {
      MatchesSortOrder.importance => 'importance',
      MatchesSortOrder.time => 'time',
      MatchesSortOrder.league => 'league',
    };
  }
}

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatchesEvent extends MatchesEvent {
  final DateTime date;
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadMatchesEvent({
    required this.date,
    this.isRefresh = false,
    this.completer,
  });

  @override
  List<Object?> get props => [date, isRefresh];
}

class ChangeFilterEvent extends MatchesEvent {
  final MatchFilterType filter;

  const ChangeFilterEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ApplyMatchesFilterEvent extends MatchesEvent {
  final MatchFilterType? filter;
  final String? leagueId;
  final String? leagueTitle;
  final MatchesSortOrder? sortOrder;

  const ApplyMatchesFilterEvent({
    this.filter,
    this.leagueId,
    this.leagueTitle,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [filter, leagueId, leagueTitle, sortOrder];
}

class ResetMatchesFilterEvent extends MatchesEvent {
  const ResetMatchesFilterEvent();
}

class SearchMatchesEvent extends MatchesEvent {
  final String query;

  const SearchMatchesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LiveMatchReceivedEvent extends MatchesEvent {
  final LiveMatchUpdate update;

  const LiveMatchReceivedEvent(this.update);

  @override
  List<Object?> get props => [update];
}

class SocketStatusChangedEvent extends MatchesEvent {
  final SocketConnectionState status;

  const SocketStatusChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class ToggleMatchFavoriteEvent extends MatchesEvent {
  final String matchId;

  const ToggleMatchFavoriteEvent(this.matchId);

  @override
  List<Object?> get props => [matchId];
}
