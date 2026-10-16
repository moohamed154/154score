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
  final MatchVideosEntity videos;
  final MatchLineupEntity? lineup;
  final MatchOverviewDataEntity? overview;
  final String? liveScore1;
  final String? liveScore2;
  final String? livePenaltyScore1;
  final String? livePenaltyScore2;
  final String? liveStatus;
  final String? liveStatusCode;
  final String? liveMinute;
  final String? liveExtraTime;
  final String? livePeriod;
  final String? championshipId;
  final Map<String, dynamic>? halfScores;
  final PenaltyShootoutDetailEntity? penaltiesDetail;
  final String? alert;
  final String? errorMessage;

  const MatchDetailsState({
    this.status = MatchDetailsStatus.initial,
    required this.matchId,
    this.selectedTab = 0,
    this.events = const [],
    this.stats = const [],
    this.details = const [],
    this.news = const [],
    this.videos = const MatchVideosEntity(),
    this.lineup,
    this.overview,
    this.championshipId,
    this.halfScores,
    this.penaltiesDetail,
    this.alert,
    this.liveScore1,
    this.liveScore2,
    this.livePenaltyScore1,
    this.livePenaltyScore2,
    this.liveStatus,
    this.liveStatusCode,
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
    MatchVideosEntity? videos,
    MatchLineupEntity? lineup,
    MatchOverviewDataEntity? overview,
    String? championshipId,
    Map<String, dynamic>? halfScores,
    PenaltyShootoutDetailEntity? penaltiesDetail,
    String? alert,
    String? liveScore1,
    String? liveScore2,
    String? livePenaltyScore1,
    String? livePenaltyScore2,
    String? liveStatus,
    String? liveStatusCode,
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
      videos: videos ?? this.videos,
      lineup: lineup ?? this.lineup,
      overview: overview ?? this.overview,
      championshipId: championshipId ?? this.championshipId,
      halfScores: halfScores ?? this.halfScores,
      penaltiesDetail: penaltiesDetail ?? this.penaltiesDetail,
      alert: alert ?? this.alert,
      liveScore1: liveScore1 ?? this.liveScore1,
      liveScore2: liveScore2 ?? this.liveScore2,
      livePenaltyScore1: livePenaltyScore1 ?? this.livePenaltyScore1,
      livePenaltyScore2: livePenaltyScore2 ?? this.livePenaltyScore2,
      liveStatus: liveStatus ?? this.liveStatus,
      liveStatusCode: liveStatusCode ?? this.liveStatusCode,
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
        videos,
        lineup,
        overview,
        championshipId,
        halfScores,
        penaltiesDetail,
        alert,
        liveScore1,
        liveScore2,
        livePenaltyScore1,
        livePenaltyScore2,
        liveStatus,
        liveStatusCode,
        liveMinute,
        liveExtraTime,
        livePeriod,
        errorMessage,
      ];
}
