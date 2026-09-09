import 'package:equatable/equatable.dart';

import '../../domain/entities/match_details_entity.dart';

enum MatchDetailsStatus { initial, loading, success, error }

class MatchDetailsState extends Equatable {
  final MatchDetailsStatus status;
  final String matchId;
  final int selectedTab;
  final List<MatchEventEntity> events;
  final List<MatchStatItemEntity> stats;
  final List<MatchInfoSectionEntity> details;
  final List<MatchNewsItemEntity> news;
  final MatchLineupEntity? lineup;
  final String? liveScore1;
  final String? liveScore2;
  final String? liveStatus;
  final String? liveMinute;
  final String? liveExtraTime;
  final String? livePeriod;
  final String? errorMessage;

  const MatchDetailsState({
    this.status = MatchDetailsStatus.initial,
    required this.matchId,
    this.selectedTab = 0,
    this.events = const [],
    this.stats = const [],
    this.details = const [],
    this.news = const [],
    this.lineup,
    this.liveScore1,
    this.liveScore2,
    this.liveStatus,
    this.liveMinute,
    this.liveExtraTime,
    this.livePeriod,
    this.errorMessage,
  });

  MatchDetailsState copyWith({
    MatchDetailsStatus? status,
    String? matchId,
    int? selectedTab,
    List<MatchEventEntity>? events,
    List<MatchStatItemEntity>? stats,
    List<MatchInfoSectionEntity>? details,
    List<MatchNewsItemEntity>? news,
    MatchLineupEntity? lineup,
    String? liveScore1,
    String? liveScore2,
    String? liveStatus,
    String? liveMinute,
    String? liveExtraTime,
    String? livePeriod,
    String? errorMessage,
  }) {
    return MatchDetailsState(
      status: status ?? this.status,
      matchId: matchId ?? this.matchId,
      selectedTab: selectedTab ?? this.selectedTab,
      events: events ?? this.events,
      stats: stats ?? this.stats,
      details: details ?? this.details,
      news: news ?? this.news,
      lineup: lineup ?? this.lineup,
      liveScore1: liveScore1 ?? this.liveScore1,
      liveScore2: liveScore2 ?? this.liveScore2,
      liveStatus: liveStatus ?? this.liveStatus,
      liveMinute: liveMinute ?? this.liveMinute,
      liveExtraTime: liveExtraTime ?? this.liveExtraTime,
      livePeriod: livePeriod ?? this.livePeriod,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    matchId,
    selectedTab,
    events,
    stats,
    details,
    news,
    lineup,
    liveScore1,
    liveScore2,
    liveStatus,
    liveMinute,
    liveExtraTime,
    livePeriod,
    errorMessage,
  ];
}
