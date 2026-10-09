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
  final Set<String> cachedFavCompetitionKeys;
  final Set<String> cachedFavTeamKeys;

  const FavoritesState({
    this.favoriteTeams = const [],
    this.favoriteCompetitions = const [],
    this.favoriteMatches = const [],
    this.competitionTitles = const {},
    this.teamTitles = const {},
    this.cachedFavCompetitionKeys = const {},
    this.cachedFavTeamKeys = const {},
  });

  static Set<String> _buildCompetitionKeys(
    List<String> favCompetitions,
    Map<String, String> titles,
  ) {
    if (favCompetitions.isEmpty) return const {};
    final keys = <String>{};

    for (final fav in favCompetitions) {
      final clean = fav.trim().toLowerCase();
      if (clean.isEmpty) continue;
      keys.add(clean);

      // Fast title mapping
      final mappedTitle = titles[fav] ?? titles[clean];
      if (mappedTitle != null && mappedTitle.trim().isNotEmpty) {
        final cleanMapped = mappedTitle.trim().toLowerCase();
        keys.add(cleanMapped);
        final normMapped = LeagueResolver.normalize(cleanMapped);
        if (normMapped.isNotEmpty) keys.add(normMapped);
        final rMapped = LeagueResolver.resolveId(cleanMapped);
        if (rMapped != null && rMapped.isNotEmpty) keys.add(rMapped);
      }

      final norm = LeagueResolver.normalize(clean);
      if (norm.isNotEmpty) keys.add(norm);
      final rId = LeagueResolver.resolveId(clean);
      if (rId != null && rId.isNotEmpty) keys.add(rId);
    }

    // Fast O(M) single pass over titles instead of O(N * M) nested regex loop
    for (final entry in titles.entries) {
      final idKey = entry.key.trim().toLowerCase();
      final titleVal = entry.value.trim().toLowerCase();
      if (keys.contains(titleVal) || keys.contains(idKey)) {
        keys.add(idKey);
        keys.add(titleVal);
        final rId = LeagueResolver.resolveId(idKey);
        if (rId != null && rId.isNotEmpty) keys.add(rId);
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
      if (clean.isEmpty) continue;
      keys.add(clean);

      // If it's not a numeric ID, allow canonical alias mapping
      if (int.tryParse(clean) == null) {
        final cKey = TeamResolver.getCanonicalKey(clean);
        if (cKey != null && cKey.isNotEmpty) keys.add(cKey.toLowerCase());
      }

      final mappedTitle = titles[team] ?? titles[clean];
      if (mappedTitle != null && mappedTitle.trim().isNotEmpty) {
        final cleanMapped = mappedTitle.trim().toLowerCase();
        keys.add(cleanMapped);
        if (int.tryParse(cleanMapped) == null) {
          final cMapped = TeamResolver.getCanonicalKey(cleanMapped);
          if (cMapped != null && cMapped.isNotEmpty) {
            keys.add(cMapped.toLowerCase());
          }
        }
      }
    }

    // Fast O(M) single pass over titles
    for (final entry in titles.entries) {
      final idKey = entry.key.trim().toLowerCase();
      final titleVal = entry.value.trim().toLowerCase();
      if (keys.contains(titleVal) || keys.contains(idKey)) {
        keys.add(idKey);
        keys.add(titleVal);
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
    final nextTeams = favoriteTeams ?? this.favoriteTeams;
    final nextCompetitions = favoriteCompetitions ?? this.favoriteCompetitions;
    final nextTitles = competitionTitles ?? this.competitionTitles;
    final nextTeamTitles = teamTitles ?? this.teamTitles;

    final shouldRebuildCompKeys =
        favoriteCompetitions != null || competitionTitles != null;
    final shouldRebuildTeamKeys =
        favoriteTeams != null || teamTitles != null;

    return FavoritesState(
      favoriteTeams: nextTeams,
      favoriteCompetitions: nextCompetitions,
      favoriteMatches: favoriteMatches ?? this.favoriteMatches,
      competitionTitles: nextTitles,
      teamTitles: nextTeamTitles,
      cachedFavCompetitionKeys: shouldRebuildCompKeys
          ? _buildCompetitionKeys(nextCompetitions, nextTitles)
          : cachedFavCompetitionKeys,
      cachedFavTeamKeys: shouldRebuildTeamKeys
          ? _buildTeamKeys(nextTeams, nextTeamTitles)
          : cachedFavTeamKeys,
    );
  }

  bool isFavoriteCompetition({String? id, String? name, String? slug}) {
    if (favoriteCompetitions.isEmpty) return false;

    final cleanId = id?.trim().toLowerCase();
    if (cleanId != null && cleanId.isNotEmpty) {
      if (cachedFavCompetitionKeys.contains(cleanId)) return true;
      final rId = LeagueResolver.resolveId(cleanId);
      if (rId != null && cachedFavCompetitionKeys.contains(rId)) return true;
      final titleForId = competitionTitles[cleanId] ?? competitionTitles[id?.trim()];
      if (titleForId != null && isFavoriteCompetition(name: titleForId)) return true;
    }

    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      final lowerName = cleanName.toLowerCase();
      if (cachedFavCompetitionKeys.contains(lowerName)) return true;
      final normName = LeagueResolver.normalize(cleanName);
      if (normName.isNotEmpty && cachedFavCompetitionKeys.contains(normName)) {
        return true;
      }
      final rName = LeagueResolver.resolveId(cleanName);
      if (rName != null && cachedFavCompetitionKeys.contains(rName)) {
        return true;
      }
    }

    final cleanSlug = slug?.trim();
    if (cleanSlug != null && cleanSlug.isNotEmpty) {
      final lowerSlug = cleanSlug.toLowerCase();
      if (cachedFavCompetitionKeys.contains(lowerSlug)) return true;
      final normSlug = LeagueResolver.normalize(cleanSlug);
      if (normSlug.isNotEmpty && cachedFavCompetitionKeys.contains(normSlug)) {
        return true;
      }
      final rSlug = LeagueResolver.resolveId(cleanSlug);
      if (rSlug != null && cachedFavCompetitionKeys.contains(rSlug)) {
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

    // 1. Strict Match by ID (prevents collisions between same-named clubs across leagues)
    if (cleanId != null && cleanId.isNotEmpty) {
      if (favoriteTeams.any((t) => t.trim().toLowerCase() == cleanId)) {
        return true;
      }
      if (cachedFavTeamKeys.contains(cleanId)) return true;
      if (teamTitles.containsKey(cleanId)) {
        final title = teamTitles[cleanId]!.trim().toLowerCase();
        if (favoriteTeams.any((t) => t.trim().toLowerCase() == title)) {
          return true;
        }
      }
      for (final fav in favoriteTeams) {
        final mapped = teamTitles[fav.trim().toLowerCase()];
        if (mapped != null && mapped.trim().toLowerCase() == cleanId) {
          return true;
        }
      }
      // If an ID was provided, NEVER fall back to loose name matching!
      return false;
    }

    // 2. Query only has name (no ID): Check if name corresponds to a known ID
    final knownId =
        LocalStorageServiceImpl.knownTeamNameToId[cleanName?.toLowerCase()] ??
        LocalStorageServiceImpl.knownTeamNameToId[cleanName];
    if (knownId != null) {
      if (favoriteTeams.any((t) => t.trim().toLowerCase() == knownId.toLowerCase())) {
        return true;
      }
    }

    // 3. Fallback name match for custom teams without IDs
    if (cleanName != null && cleanName.isNotEmpty) {
      final lowerName = cleanName.toLowerCase();
      if (cachedFavTeamKeys.contains(lowerName)) return true;
      for (final team in favoriteTeams) {
        final cleanTeam = team.trim();
        if (cleanTeam.toLowerCase() == lowerName) return true;
        if (TeamResolver.areSameTeam(cleanTeam, cleanName)) return true;
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
    final cleanName = teamName.trim();
    final cleanId = (id != null && id.trim().isNotEmpty)
        ? id.trim()
        : (LocalStorageServiceImpl.knownTeamNameToId[cleanName.toLowerCase()] ??
           LocalStorageServiceImpl.knownTeamNameToId[cleanName]);
    final wasFav = isTeamFavorite(id: cleanId, name: cleanName);
    final key = (cleanId != null && cleanId.isNotEmpty) ? cleanId : cleanName;

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteTeams);
    final updatedTitles = Map<String, String>.from(state.teamTitles);

    if (wasFav) {
      updatedList.removeWhere((item) {
        final cleanItem = item.trim();
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            cleanItem.toLowerCase() == cleanId.toLowerCase()) {
          return true;
        }
        if (cleanName.isNotEmpty &&
            cleanItem.toLowerCase() == cleanName.toLowerCase()) {
          return true;
        }
        if (cleanName.isNotEmpty &&
            TeamResolver.areSameTeam(cleanItem, cleanName)) {
          return true;
        }
        return false;
      });
    } else {
      if (cleanId != null && cleanId.isNotEmpty) {
        if (!updatedList.contains(cleanId)) updatedList.add(cleanId);
        if (cleanName.isNotEmpty) updatedTitles[cleanId] = cleanName;
      } else if (cleanName.isNotEmpty && !updatedList.contains(cleanName)) {
        updatedList.add(cleanName);
      }
    }
    emit(state.copyWith(favoriteTeams: updatedList, teamTitles: updatedTitles));

    await _storage.toggleFavoriteTeam(teamName, id: cleanId);
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
    final cleanId = id?.trim();
    final lookupTitle = (cleanId != null && cleanId.isNotEmpty)
        ? (state.competitionTitles[cleanId] ?? _storage.resolveCompetitionTitle(cleanId))
        : null;
    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : ((compName != null && compName.trim().isNotEmpty)
            ? compName.trim()
            : ((slug != null && slug.trim().isNotEmpty)
                ? slug.trim()
                : (lookupTitle ?? '')));

    final wasFav = isCompetitionFavorite(
      id: cleanId,
      name: effectiveName,
      slug: slug,
    );

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteCompetitions);
    final updatedTitles = Map<String, String>.from(state.competitionTitles);

    final canonicalName = effectiveName.isNotEmpty
        ? effectiveName
        : (cleanId ?? '');

    if (wasFav) {
      final originalLen = updatedList.length;
      // 1. Fast direct removal
      updatedList.removeWhere((item) {
        final itemTrim = item.trim();
        final itemLower = itemTrim.toLowerCase();
        if (cleanId != null && cleanId.isNotEmpty && itemLower == cleanId.toLowerCase()) {
          return true;
        }
        if (effectiveName.isNotEmpty && itemLower == effectiveName.toLowerCase()) {
          return true;
        }
        if (cleanId != null && state.competitionTitles[cleanId]?.toLowerCase() == itemLower) {
          return true;
        }
        if (state.competitionTitles[itemTrim]?.toLowerCase() == cleanId?.toLowerCase()) {
          return true;
        }
        if (lookupTitle != null && lookupTitle.toLowerCase() == itemLower) {
          return true;
        }
        return false;
      });

      // 2. Fallback only if direct comparison didn't match
      if (updatedList.length == originalLen) {
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
      }
    } else {
      if (canonicalName.isNotEmpty && !updatedList.contains(canonicalName)) {
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

    await _storage.setFavoriteCompetitions(updatedList);
    if (cleanId != null && cleanId.isNotEmpty && canonicalName.isNotEmpty) {
      unawaited(_storage.registerCompetitionTitles({cleanId: canonicalName}));
    }
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

