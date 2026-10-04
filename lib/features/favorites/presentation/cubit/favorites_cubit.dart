import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/team_resolver.dart';

class FavoritesState extends Equatable {
  final List<String> favoriteTeams;
  final List<String> favoriteCompetitions;
  final List<String> favoriteMatches;
  final Map<String, String> competitionTitles;
  final Map<String, String> teamTitles;
  final Set<String> _cachedFavCompetitionKeys;
  final Set<String> _cachedFavTeamKeys;

  FavoritesState({
    this.favoriteTeams = const [],
    this.favoriteCompetitions = const [],
    this.favoriteMatches = const [],
    this.competitionTitles = const {},
    this.teamTitles = const {},
    Set<String>? cachedFavCompetitionKeys,
    Set<String>? cachedFavTeamKeys,
  })  : _cachedFavCompetitionKeys = cachedFavCompetitionKeys ??
            _buildCompetitionKeys(favoriteCompetitions, competitionTitles),
        _cachedFavTeamKeys = cachedFavTeamKeys ??
            _buildTeamKeys(favoriteTeams, teamTitles);

  static Set<String> _buildCompetitionKeys(
    List<String> favCompetitions,
    Map<String, String> titles,
  ) {
    if (favCompetitions.isEmpty) return const {};
    final keys = <String>{};
    for (final fav in favCompetitions) {
      final clean = fav.trim().toLowerCase();
      if (clean.isNotEmpty) {
        keys.add(clean);
        final norm = LeagueResolver.normalize(clean);
        if (norm.isNotEmpty) keys.add(norm);
        final rId = LeagueResolver.resolveId(clean);
        if (rId != null && rId.isNotEmpty) keys.add(rId);
      }
      final mappedTitle = titles[fav] ?? titles[clean];
      if (mappedTitle != null && mappedTitle.trim().isNotEmpty) {
        final cleanMapped = mappedTitle.trim().toLowerCase();
        keys.add(cleanMapped);
        final normMapped = LeagueResolver.normalize(cleanMapped);
        if (normMapped.isNotEmpty) keys.add(normMapped);
        final rMapped = LeagueResolver.resolveId(cleanMapped);
        if (rMapped != null && rMapped.isNotEmpty) keys.add(rMapped);
      }
    }
    return keys;
  }

  static Set<String> _buildTeamKeys(
    List<String> favTeams,
    Map<String, String> titles,
  ) {
    if (favTeams.isEmpty) return const {};
    final keys = <String>{};
    for (final team in favTeams) {
      final clean = team.trim().toLowerCase();
      if (clean.isNotEmpty) {
        keys.add(clean);
        final cKey = TeamResolver.getCanonicalKey(clean);
        if (cKey != null && cKey.isNotEmpty) keys.add(cKey.toLowerCase());
      }
      final mappedTitle = titles[team] ?? titles[clean];
      if (mappedTitle != null && mappedTitle.trim().isNotEmpty) {
        final cleanMapped = mappedTitle.trim().toLowerCase();
        keys.add(cleanMapped);
        final cMapped = TeamResolver.getCanonicalKey(cleanMapped);
        if (cMapped != null && cMapped.isNotEmpty) {
          keys.add(cMapped.toLowerCase());
        }
      }
    }
    return keys;
  }

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

    final cleanId = id?.trim().toLowerCase();
    if (cleanId != null && cleanId.isNotEmpty) {
      if (_cachedFavCompetitionKeys.contains(cleanId)) return true;
      final rId = LeagueResolver.resolveId(cleanId);
      if (rId != null && _cachedFavCompetitionKeys.contains(rId)) return true;
    }

    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      final lowerName = cleanName.toLowerCase();
      if (_cachedFavCompetitionKeys.contains(lowerName)) return true;
      final normName = LeagueResolver.normalize(cleanName);
      if (normName.isNotEmpty && _cachedFavCompetitionKeys.contains(normName)) {
        return true;
      }
      final rName = LeagueResolver.resolveId(cleanName);
      if (rName != null && _cachedFavCompetitionKeys.contains(rName)) {
        return true;
      }
    }

    final cleanSlug = slug?.trim();
    if (cleanSlug != null && cleanSlug.isNotEmpty) {
      final lowerSlug = cleanSlug.toLowerCase();
      if (_cachedFavCompetitionKeys.contains(lowerSlug)) return true;
      final normSlug = LeagueResolver.normalize(cleanSlug);
      if (normSlug.isNotEmpty && _cachedFavCompetitionKeys.contains(normSlug)) {
        return true;
      }
      final rSlug = LeagueResolver.resolveId(cleanSlug);
      if (rSlug != null && _cachedFavCompetitionKeys.contains(rSlug)) {
        return true;
      }
    }

    // Safety fallback for any complex dynamic variation
    final origCleanName = name?.trim();
    final origCleanId = id?.trim();
    for (final fav in favoriteCompetitions) {
      final favTrim = fav.trim();
      final mappedId = competitionTitles[favTrim];
      if (LeagueResolver.areSameCompetition(
        favTrim,
        origCleanName,
        idA: mappedId,
        idB: origCleanId,
      )) {
        return true;
      }
    }
    return false;
  }

  bool isFavoriteTeam({String? id, String? name}) {
    if (favoriteTeams.isEmpty) return false;
    final cleanId = id?.trim().toLowerCase();
    final cleanName = name?.trim();

    if (cleanId != null && cleanId.isNotEmpty) {
      if (_cachedFavTeamKeys.contains(cleanId)) return true;
      final cId = TeamResolver.getCanonicalKey(cleanId);
      if (cId != null && _cachedFavTeamKeys.contains(cId.toLowerCase())) {
        return true;
      }
    }

    if (cleanName != null && cleanName.isNotEmpty) {
      final lowerName = cleanName.toLowerCase();
      if (_cachedFavTeamKeys.contains(lowerName)) return true;
      final cName = TeamResolver.getCanonicalKey(cleanName);
      if (cName != null && _cachedFavTeamKeys.contains(cName.toLowerCase())) {
        return true;
      }
    }

    final targets = <String>{};
    if (cleanId != null && cleanId.isNotEmpty) {
      targets.add(cleanId);
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
    final cleanName = teamName.trim();
    final cleanId = id?.trim();
    final key = (cleanId != null && cleanId.isNotEmpty) ? cleanId : cleanName;

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteTeams);
    final updatedTitles = Map<String, String>.from(state.teamTitles);

    if (wasFav) {
      updatedList.removeWhere((item) {
        final cleanItem = item.trim();
        if (cleanName.isNotEmpty &&
            cleanItem.toLowerCase() == cleanName.toLowerCase()) {
          return true;
        }
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            cleanItem.toLowerCase() == cleanId.toLowerCase()) {
          return true;
        }
        if (cleanName.isNotEmpty &&
            TeamResolver.areSameTeam(cleanItem, cleanName)) {
          return true;
        }
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            TeamResolver.areSameTeam(cleanItem, cleanId)) {
          return true;
        }
        return false;
      });
    } else {
      if (cleanName.isNotEmpty && !updatedList.contains(cleanName)) {
        updatedList.add(cleanName);
      } else if (cleanId != null && cleanId.isNotEmpty && !updatedList.contains(cleanId)) {
        updatedList.add(cleanId);
      }
      if (cleanId != null && cleanId.isNotEmpty && cleanName.isNotEmpty) {
        updatedTitles[cleanId] = cleanName;
      }
    }
    emit(state.copyWith(favoriteTeams: updatedList, teamTitles: updatedTitles));

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
    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : ((compName != null && compName.trim().isNotEmpty)
            ? compName.trim()
            : (slug?.trim() ?? ''));
    final cleanId = id?.trim();

    final wasFav = isCompetitionFavorite(
      id: cleanId,
      name: effectiveName,
      slug: slug,
    );

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteCompetitions);
    final updatedTitles = Map<String, String>.from(state.competitionTitles);

    if (wasFav) {
      updatedList.removeWhere((item) {
        final itemTrim = item.trim();
        final mappedId = state.competitionTitles[itemTrim];
        return LeagueResolver.areSameCompetition(
          itemTrim,
          effectiveName,
          idA: mappedId,
          idB: cleanId,
        );
      });
    } else {
      final canonicalName = effectiveName.isNotEmpty
          ? effectiveName
          : (cleanId ?? '');

      if (canonicalName.isNotEmpty &&
          !updatedList.any((item) {
            final itemTrim = item.trim();
            final mappedId = state.competitionTitles[itemTrim];
            return LeagueResolver.areSameCompetition(
              itemTrim,
              canonicalName,
              idA: mappedId,
              idB: cleanId,
            );
          })) {
        updatedList.add(canonicalName);
      }
      if (cleanId != null && cleanId.isNotEmpty && canonicalName.isNotEmpty) {
        updatedTitles[cleanId] = canonicalName;
      }
    }

    emit(state.copyWith(
      favoriteCompetitions: updatedList,
      competitionTitles: updatedTitles,
    ));

    await _storage.toggleFavoriteCompetition(
      compName: effectiveName,
      id: cleanId,
      name: effectiveName,
      slug: slug,
    );
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

