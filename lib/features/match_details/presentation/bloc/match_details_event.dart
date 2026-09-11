import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../../core/websocket/websocket_event.dart';

abstract class MatchDetailsEvent extends Equatable {
  const MatchDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatchDetailsEvent extends MatchDetailsEvent {
  final String matchId;
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadMatchDetailsEvent(
    this.matchId, {
    this.isRefresh = false,
    this.completer,
  });

  @override
  List<Object?> get props => [matchId, isRefresh];
}

class ChangeTabEvent extends MatchDetailsEvent {
  final int tabIndex;

  const ChangeTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class LiveMatchDetailUpdateEvent extends MatchDetailsEvent {
  final LiveMatchUpdate update;

  const LiveMatchDetailUpdateEvent(this.update);

  @override
  List<Object?> get props => [update];
}

class MatchDetailSocketUpdateEvent extends MatchDetailsEvent {
  final MatchDetailRealtimeUpdate update;

  const MatchDetailSocketUpdateEvent(this.update);

  @override
  List<Object?> get props => [update];
}
