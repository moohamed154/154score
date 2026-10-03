import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/team_resolver.dart';

class FavoritesState extends Equatable {
  final List<String> favoriteTeams;
  final List<String> favoriteCompetitions;
  final List<String> favoriteMatches;
  final Map<String, String> competitionTitles;
  final Map<String, String> teamTitles;

  const FavoritesState({
    this.favoriteTeams = const [],
    this.favoriteCompetitions = const [],
    this.favoriteMatches = const [],
    this.competitionTitles = const {},
    this.teamTitles = const {},
  });

  FavoritesState copyWith({
    List<String>? favoriteTeams,
    List<String>? favoriteCompetitions,
    List<String>? favoriteMatches,
    Map<String, String>? competitionTitles,
    Map<String, String>? teamTitles,
  }) {
    return FavoritesState(
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      favoriteCompetitions: favoriteCompetitions ?? this.favoriteCompetitions,
      favoriteMatches: favoriteMatches ?? this.favoriteMatches,
      competitionTitles: competitionTitles ?? this.competitionTitles,
      teamTitles: teamTitles ?? this.teamTitles,
    );
  }

  bool isFavoriteCompetition({String? id, String? name, String? slug}) {
    if (favoriteCompetitions.isEmpty) return false;

    final targets = <String>{};
    void addTarget(String? s) {
      if (s != null && s.trim().isNotEmpty) {
        targets.add(s.trim().toLowerCase());
      }
    }

    addTarget(id);
    addTarget(name);
    addTarget(slug);

    if (id != null && competitionTitles.containsKey(id.trim())) {
      addTarget(competitionTitles[id.trim()]);
    }
    if (name != null && competitionTitles.containsKey(name.trim())) {
      addTarget(competitionTitles[name.trim()]);
    }

    for (final candidate in [id, name, slug]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        final clean = candidate.trim().toLowerCase();
        final resolvedId =
            LocalStorageServiceImpl.defaultNameToId[clean] ??
            competitionTitles[clean];
        if (resolvedId != null) addTarget(resolvedId);
      }
    }

    for (final fav in favoriteCompetitions) {
      final cleanFav = fav.trim().toLowerCase();
      if (targets.contains(cleanFav)) return true;
      if (competitionTitles.containsKey(fav.trim())) {
        final mapped = competitionTitles[fav.trim()]!.trim().toLowerCase();
        if (targets.contains(mapped)) return true;
      }
      if (competitionTitles.containsKey(cleanFav)) {
        final mapped = competitionTitles[cleanFav]!.trim().toLowerCase();
        if (targets.contains(mapped)) return true;
      }
      final resolvedId = LocalStorageServiceImpl.defaultNameToId[cleanFav];
      if (resolvedId != null && targets.contains(resolvedId.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool isFavoriteTeam({String? id, String? name}) {
    if (favoriteTeams.isEmpty) return false;
    final cleanId = id?.trim();
    final cleanName = name?.trim();

    final targets = <String>{};
    if (cleanId != null && cleanId.isNotEmpty) {
      targets.add(cleanId.toLowerCase());
      if (teamTitles.containsKey(cleanId)) {
        targets.add(teamTitles[cleanId]!.trim().toLowerCase());
      }
    }
    if (cleanName != null && cleanName.isNotEmpty) {
      targets.add(cleanName.toLowerCase());
      if (teamTitles.containsKey(cleanName.toLowerCase())) {
        targets.add(teamTitles[cleanName.toLowerCase()]!.trim().toLowerCase());
      }
    }

    final nameKey = cleanName != null && cleanName.isNotEmpty
        ? TeamResolver.getCanonicalKey(cleanName)
        : null;
    final idKey = cleanId != null && cleanId.isNotEmpty
        ? TeamResolver.getCanonicalKey(cleanId)
        : null;

    for (final team in favoriteTeams) {
      final cleanTeam = team.trim();
      final lowerTeam = cleanTeam.toLowerCase();

      // 1. Direct target match
      if (targets.contains(lowerTeam)) return true;

      // 2. Mapped titles match
      if (teamTitles.containsKey(cleanTeam) &&
          targets.contains(teamTitles[cleanTeam]!.trim().toLowerCase())) {
        return true;
      }
      if (teamTitles.containsKey(lowerTeam) &&
          targets.contains(teamTitles[lowerTeam]!.trim().toLowerCase())) {
        return true;
      }

      // 3. TeamResolver cross-lingual matching (e.g. 'مصر' == 'Egypt')
      if (cleanName != null && cleanName.isNotEmpty &&
          TeamResolver.areSameTeam(cleanTeam, cleanName)) {
        return true;
      }
      if (cleanId != null && cleanId.isNotEmpty &&
          TeamResolver.areSameTeam(cleanTeam, cleanId)) {
        return true;
      }

      // 4. Canonical key matching
      final teamKey = TeamResolver.getCanonicalKey(cleanTeam);
      if (teamKey != null) {
        if (nameKey != null && teamKey == nameKey) return true;
        if (idKey != null && teamKey == idKey) return true;
      }
    }
    return false;
  }

  bool isFavoriteMatch(String matchId) {
    if (favoriteMatches.isEmpty) return false;
    final clean = matchId.trim().toLowerCase();
    return favoriteMatches.any((m) => m.trim().toLowerCase() == clean);
  }

  @override
  List<Object?> get props => [
    favoriteTeams,
    favoriteCompetitions,
    favoriteMatches,
    competitionTitles,
    teamTitles,
  ];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final LocalStorageService _storage;

  FavoritesCubit(this._storage) : super(const FavoritesState()) {
    loadFavorites();
  }

  void loadFavorites() {
    emit(
      state.copyWith(
        favoriteTeams: _storage.getFavoriteTeams(),
        favoriteCompetitions: _storage.getFavoriteCompetitions(),
        favoriteMatches: _storage.getFavoriteMatches(),
        competitionTitles: _storage.getFavoriteCompetitionTitles(),
        teamTitles: _storage.getFavoriteTeamTitles(),
      ),
    );
  }

  bool isCompetitionFavorite({String? id, String? name, String? slug}) {
    return state.isFavoriteCompetition(id: id, name: name, slug: slug);
  }

  bool isTeamFavorite({String? id, String? name}) {
    return state.isFavoriteTeam(id: id, name: name);
  }

  bool isMatchFavorite(String matchId) {
    return state.isFavoriteMatch(matchId);
  }

  Future<void> toggleTeam(String teamName, {String? id}) async {
    final wasFav = isTeamFavorite(id: id, name: teamName);
    final key = (id != null && id.trim().isNotEmpty) ? id.trim() : teamName.trim();

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteTeams);
    if (wasFav) {
      updatedList.removeWhere((item) =>
          item.toLowerCase() == key.toLowerCase() ||
          item.toLowerCase() == teamName.trim().toLowerCase() ||
          (id != null && item.toLowerCase() == id.trim().toLowerCase()));
    } else {
      if (!updatedList.any((item) => item.toLowerCase() == key.toLowerCase())) {
        updatedList.add(key);
      }
    }
    emit(state.copyWith(favoriteTeams: updatedList));

    await _storage.toggleFavoriteTeam(teamName, id: id);
    loadFavorites();
    final isFavNow = isTeamFavorite(id: id, name: teamName);
    if (!wasFav && isFavNow) {
      await _storage.setTeamNotificationMuted(key, false);
      if (!_storage.isTeamNotificationEnabled(key)) {
        await _storage.toggleTeamNotification(key);
      }
      unawaited(NotificationService.instance.requestPermissions());
    }
  }

  Future<void> registerTeamTitles(Map<String, String> titles) async {
    await _storage.registerTeamTitles(titles);
    loadFavorites();
  }

  Future<void> toggleCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) async {
    final effectiveName = name ?? compName;
    final wasFav = isCompetitionFavorite(id: id, name: effectiveName, slug: slug);
    final target = id ?? effectiveName ?? slug ?? '';

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteCompetitions);
    if (wasFav) {
      updatedList.removeWhere((c) =>
          c.toLowerCase() == target.toLowerCase() ||
          (effectiveName != null && c.toLowerCase() == effectiveName.toLowerCase()) ||
          (id != null && c.toLowerCase() == id.toLowerCase()));
    } else {
      if (target.isNotEmpty &&
          !updatedList.any((c) => c.toLowerCase() == target.toLowerCase())) {
        updatedList.add(target);
      }
    }
    emit(state.copyWith(favoriteCompetitions: updatedList));

    await _storage.toggleFavoriteCompetition(
      compName: effectiveName,
      id: id,
      name: effectiveName,
      slug: slug,
    );
    loadFavorites();
  }

  Future<void> registerCompetitionTitles(Map<String, String> titles) async {
    await _storage.registerCompetitionTitles(titles);
    loadFavorites();
  }

  Future<void> setFavoriteCompetitions(List<String> list) async {
    await _storage.setFavoriteCompetitions(list);
    emit(state.copyWith(favoriteCompetitions: list));
  }

  Future<void> reorderFavoriteCompetitions(int oldIndex, int newIndex) async {
    final list = List<String>.from(state.favoriteCompetitions);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await _storage.setFavoriteCompetitions(list);
    emit(state.copyWith(favoriteCompetitions: list));
  }

  Future<void> toggleMatch(String matchId) async {
    final wasFav = isMatchFavorite(matchId);

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteMatches);
    if (wasFav) {
      updatedList.remove(matchId);
    } else {
      if (!updatedList.contains(matchId)) updatedList.add(matchId);
    }
    emit(state.copyWith(favoriteMatches: updatedList));

    await _storage.toggleFavoriteMatch(matchId);
    loadFavorites();
  }
}

