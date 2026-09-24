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
  final String? selectedLeagueId;
  final String? selectedLeagueTitle;
  final MatchesSortOrder sortOrder;
  final String searchQuery;
  final String? errorMessage;
  final int liveMatchesCount;
  final String timeFormat;
  final bool isLanguageRefreshing;

  const MatchesState({
    this.status = MatchesStatus.initial,
    this.allLeagues = const [],
    this.filteredLeagues = const [],
    required this.selectedDate,
    this.activeFilter = MatchFilterType.all,
    this.selectedLeagueId,
    this.selectedLeagueTitle,
    this.sortOrder = MatchesSortOrder.importance,
    this.searchQuery = '',
    this.errorMessage,
    this.liveMatchesCount = 0,
    this.timeFormat = '24h',
    this.isLanguageRefreshing = false,
  });

  bool get hasActiveFilter =>
      activeFilter != MatchFilterType.all ||
      selectedLeagueId != null ||
      sortOrder != MatchesSortOrder.importance;

  int get filteredMatchesCount =>
      filteredLeagues.fold<int>(0, (sum, l) => sum + l.matches.length);

  List<({String? id, String title, String? logo, int matchCount})>
  get availableLeagues {
    final map =
        <String, ({String? id, String title, String? logo, int matchCount})>{};
    for (final l in allLeagues) {
      final key = (l.leagueId != null && l.leagueId!.isNotEmpty)
          ? l.leagueId!
          : l.leagueTitle.trim();
      if (!map.containsKey(key)) {
        map[key] = (
          id: l.leagueId,
          title: l.leagueTitle,
          logo: l.leagueLogo,
          matchCount: l.matches.length,
        );
      } else {
        final existing = map[key]!;
        map[key] = (
          id: existing.id ?? l.leagueId,
          title: existing.title,
          logo: existing.logo ?? l.leagueLogo,
          matchCount: existing.matchCount + l.matches.length,
        );
      }
    }
    return map.values.toList();
  }

  MatchesState copyWith({
    MatchesStatus? status,
    List<LeagueGroupEntity>? allLeagues,
    List<LeagueGroupEntity>? filteredLeagues,
    DateTime? selectedDate,
    MatchFilterType? activeFilter,
    String? selectedLeagueId,
    bool clearSelectedLeague = false,
    String? selectedLeagueTitle,
    MatchesSortOrder? sortOrder,
    String? searchQuery,
    String? errorMessage,
    int? liveMatchesCount,
    String? timeFormat,
    bool? isLanguageRefreshing,
  }) {
    return MatchesState(
      status: status ?? this.status,
      allLeagues: allLeagues ?? this.allLeagues,
      filteredLeagues: filteredLeagues ?? this.filteredLeagues,
      selectedDate: selectedDate ?? this.selectedDate,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedLeagueId: clearSelectedLeague
          ? null
          : (selectedLeagueId ?? this.selectedLeagueId),
      selectedLeagueTitle: clearSelectedLeague
          ? null
          : (selectedLeagueTitle ?? this.selectedLeagueTitle),
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      liveMatchesCount: liveMatchesCount ?? this.liveMatchesCount,
      timeFormat: timeFormat ?? this.timeFormat,
      isLanguageRefreshing: isLanguageRefreshing ?? this.isLanguageRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allLeagues,
    filteredLeagues,
    selectedDate,
    activeFilter,
    selectedLeagueId,
    selectedLeagueTitle,
    sortOrder,
    searchQuery,
    errorMessage,
    liveMatchesCount,
    timeFormat,
    isLanguageRefreshing,
  ];
}
