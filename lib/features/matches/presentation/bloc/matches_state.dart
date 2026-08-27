import 'package:equatable/equatable.dart';

import '../../domain/entities/match_entity.dart';
import 'matches_event.dart';

enum MatchesStatus { initial, loading, success, empty, error }

class MatchesState extends Equatable {
  final MatchesStatus status;
  final List<LeagueGroupEntity> allLeagues;
  final List<LeagueGroupEntity> filteredLeagues;
  final DateTime selectedDate;
  final MatchFilterType activeFilter;
  final String searchQuery;
  final String? errorMessage;
  final int liveMatchesCount;

  const MatchesState({
    this.status = MatchesStatus.initial,
    this.allLeagues = const [],
    this.filteredLeagues = const [],
    required this.selectedDate,
    this.activeFilter = MatchFilterType.all,
    this.searchQuery = '',
    this.errorMessage,
    this.liveMatchesCount = 0,
  });

  MatchesState copyWith({
    MatchesStatus? status,
    List<LeagueGroupEntity>? allLeagues,
    List<LeagueGroupEntity>? filteredLeagues,
    DateTime? selectedDate,
    MatchFilterType? activeFilter,
    String? searchQuery,
    String? errorMessage,
    int? liveMatchesCount,
  }) {
    return MatchesState(
      status: status ?? this.status,
      allLeagues: allLeagues ?? this.allLeagues,
      filteredLeagues: filteredLeagues ?? this.filteredLeagues,
      selectedDate: selectedDate ?? this.selectedDate,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      liveMatchesCount: liveMatchesCount ?? this.liveMatchesCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allLeagues,
    filteredLeagues,
    selectedDate,
    activeFilter,
    searchQuery,
    errorMessage,
    liveMatchesCount,
  ];
}
