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

  const LoadMatchDetailsEvent(this.matchId, {this.isRefresh = false});

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
