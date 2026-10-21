import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/league_resolver.dart';
import '../../../../core/utils/team_resolver.dart';
import '../../../../core/utils/url_helper.dart';

class FavoritesState extends Equatable {
  final List<String> favoriteTeams;
  final List<String> favoriteCompetitions;
  final List<String> favoriteMatches;
  final Map<String, String> competitionTitles;
  final Map<String, String> teamTitles;
  final Map<String, String> teamLogos;
  final Map<String, String> competitionLogos;
  final Set<String> cachedFavCompetitionKeys;
  final Set<String> cachedFavTeamKeys;

  const FavoritesState({
    this.favoriteTeams = const [],
    this.favoriteCompetitions = const [],
    this.favoriteMatches = const [],
    this.competitionTitles = const {},
    this.teamTitles = const {},
    this.teamLogos = const {},
    this.competitionLogos = const {},
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

      // Add bidirectional titles (AR and EN) from LeagueResolver
      final arTitle = LeagueResolver.resolveTitle(clean, isArabic: true);
      if (arTitle.isNotEmpty && arTitle.toLowerCase() != clean) {
        final cleanAr = arTitle.trim().toLowerCase();
        keys.add(cleanAr);
        final normAr = LeagueResolver.normalize(cleanAr);
        if (normAr.isNotEmpty) keys.add(normAr);
        final rIdAr = LeagueResolver.resolveId(cleanAr);
        if (rIdAr != null && rIdAr.isNotEmpty) keys.add(rIdAr);
      }
      final enTitle = LeagueResolver.resolveTitle(clean, isArabic: false);
      if (enTitle.isNotEmpty && enTitle.toLowerCase() != clean) {
        final cleanEn = enTitle.trim().toLowerCase();
        keys.add(cleanEn);
        final normEn = LeagueResolver.normalize(cleanEn);
        if (normEn.isNotEmpty) keys.add(normEn);
        final rIdEn = LeagueResolver.resolveId(cleanEn);
        if (rIdEn != null && rIdEn.isNotEmpty) keys.add(rIdEn);
      }
    }

    // Only expand title from confirmed ID keys, never add unknown IDs from generic titles
    for (final entry in titles.entries) {
      final idKey = entry.key.trim().toLowerCase();
      final titleVal = entry.value.trim().toLowerCase();
      if (keys.contains(idKey)) {
        keys.add(titleVal);
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
    Map<String, String>? teamLogos,
    Map<String, String>? competitionLogos,
  }) {
    final nextTeams = favoriteTeams ?? this.favoriteTeams;
    final nextCompetitions = favoriteCompetitions ?? this.favoriteCompetitions;
    final nextTitles = competitionTitles ?? this.competitionTitles;
    final nextTeamTitles = teamTitles ?? this.teamTitles;
    final nextTeamLogos = teamLogos ?? this.teamLogos;
    final nextCompetitionLogos = competitionLogos ?? this.competitionLogos;

    final shouldRebuildCompKeys =
        favoriteCompetitions != null || competitionTitles != null;
    final shouldRebuildTeamKeys = favoriteTeams != null || teamTitles != null;

    return FavoritesState(
      favoriteTeams: nextTeams,
      favoriteCompetitions: nextCompetitions,
      favoriteMatches: favoriteMatches ?? this.favoriteMatches,
      competitionTitles: nextTitles,
      teamTitles: nextTeamTitles,
      teamLogos: nextTeamLogos,
      competitionLogos: nextCompetitionLogos,
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
    final cleanName = name?.trim();

    // 1. Strict Match by ID (prevents collisions between same-named leagues e.g. Austrian vs German Bundesliga)
    if (cleanId != null && cleanId.isNotEmpty) {
      if (favoriteCompetitions
          .any((fav) => fav.trim().toLowerCase() == cleanId)) {
        return true;
      }
      // Check ID aliases via LeagueResolver (e.g. 1933 and 938652 for LaLiga)
      for (final fav in favoriteCompetitions) {
        final favTrim = fav.trim();
        if (LeagueResolver.areSameCompetition(
          cleanId,
          favTrim,
          idA: cleanId,
          idB: int.tryParse(favTrim) != null ? favTrim : null,
        )) {
          return true;
        }
      }

      // Check name-based favorites only if they belong to this exact tournament and stage
      for (final fav in favoriteCompetitions) {
        final favTrim = fav.trim();
        if (int.tryParse(favTrim) != null) continue;
        if (cleanName != null && cleanName.contains('|') != favTrim.contains('|')) {
          continue;
        }

        final favId = competitionTitles[favTrim] ??
            competitionTitles[favTrim.toLowerCase()] ??
            LeagueResolver.resolveId(favTrim) ??
            LocalStorageServiceImpl.defaultNameToId[favTrim] ??
            LocalStorageServiceImpl.defaultNameToId[favTrim.toLowerCase()];

        if (favId != null && favId.isNotEmpty) {
          if (LeagueResolver.areSameCompetition(
            favId,
            cleanId,
            idA: favId,
            idB: cleanId,
          )) {
            return true;
          }
        } else if (cleanName != null && cleanName.isNotEmpty) {
          if (LeagueResolver.areSameCompetition(
            favTrim,
            cleanName,
            idA: favId,
            idB: cleanId,
          )) {
            return true;
          }
        }
      }

      return false;
    }

    // 2. Query only has name (no ID provided):
    if (cleanName != null && cleanName.isNotEmpty) {
      final lowerName = cleanName.toLowerCase();
      if (cachedFavCompetitionKeys.contains(lowerName)) return true;
      final normName = LeagueResolver.normalize(cleanName);
      if (normName.isNotEmpty && cachedFavCompetitionKeys.contains(normName)) {
        return true;
      }
      final rName = LeagueResolver.resolveId(cleanName);
      if (rName != null &&
          cachedFavCompetitionKeys.contains(rName.toLowerCase())) {
        return true;
      }

      final cleanSlug = slug?.trim();
      if (cleanSlug != null && cleanSlug.isNotEmpty) {
        final lowerSlug = cleanSlug.toLowerCase();
        if (cachedFavCompetitionKeys.contains(lowerSlug)) return true;
        final normSlug = LeagueResolver.normalize(cleanSlug);
        if (normSlug.isNotEmpty && cachedFavCompetitionKeys.contains(normSlug)) {
          return true;
        }
      }

      for (final fav in favoriteCompetitions) {
        final favTrim = fav.trim();
        final mappedId = competitionTitles[favTrim];
        if (LeagueResolver.areSameCompetition(
          favTrim,
          cleanName,
          idA: mappedId,
          idB: null,
        )) {
          return true;
        }
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
      // Check legacy non-numeric items in favoriteTeams
      if (cleanName != null && cleanName.isNotEmpty) {
        for (final fav in favoriteTeams) {
          if (int.tryParse(fav.trim()) == null &&
              (fav.trim().toLowerCase() == cleanName.toLowerCase() ||
                  TeamResolver.areSameTeam(fav, cleanName))) {
            return true;
          }
        }
      }
      return false;
    }

    // 2. Query only has name (no ID): Check if name or translated name maps to a stored ID
    if (cleanName != null && cleanName.isNotEmpty) {
      final lowerName = cleanName.toLowerCase();
      final arLoc = TeamResolver.getLocalizedName(cleanName, isArabic: true)
          ?.toLowerCase();
      final enLoc = TeamResolver.getLocalizedName(cleanName, isArabic: false)
          ?.toLowerCase();

      for (final candidate in [
        lowerName,
        if (arLoc != null) arLoc,
        if (enLoc != null) enLoc
      ]) {
        final knownId = LocalStorageServiceImpl.knownTeamNameToId[candidate];
        if (knownId != null &&
            favoriteTeams
                .any((t) => t.trim().toLowerCase() == knownId.toLowerCase())) {
          return true;
        }
        final mappedId = teamTitles[candidate]?.toLowerCase();
        if (mappedId != null &&
            favoriteTeams.any((t) => t.trim().toLowerCase() == mappedId)) {
          return true;
        }
      }

      // 3. Fallback name match for custom teams without IDs
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
        teamLogos,
        competitionLogos,
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
        teamLogos: _storage.getFavoriteTeamLogos(),
        competitionLogos: _storage.getFavoriteCompetitionLogos(),
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

  Future<void> toggleTeam(String teamName, {String? id, String? logo}) async {
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
    final updatedLogos = Map<String, String>.from(state.teamLogos);

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

      final resolvedLogo = (logo != null && logo.trim().isNotEmpty)
          ? logo.trim()
          : UrlHelper.resolveTeamLogo(cleanId, teamName: cleanName);
      if (resolvedLogo != null && resolvedLogo.isNotEmpty) {
        if (cleanId != null && cleanId.isNotEmpty) {
          updatedLogos[cleanId] = resolvedLogo;
        }
        if (cleanName.isNotEmpty) {
          updatedLogos[cleanName] = resolvedLogo;
        }
        unawaited(_storage.registerTeamLogos({
          if (cleanId != null && cleanId.isNotEmpty) cleanId: resolvedLogo,
          if (cleanName.isNotEmpty) cleanName: resolvedLogo,
        }));
      }
    }
    emit(state.copyWith(
      favoriteTeams: updatedList,
      teamTitles: updatedTitles,
      teamLogos: updatedLogos,
    ));

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
    String? logo,
    bool? forceFavorite,
  }) async {
    final cleanId = id?.trim();
    final lookupTitle = (cleanId != null && cleanId.isNotEmpty)
        ? (state.competitionTitles[cleanId] ??
            _storage.resolveCompetitionTitle(cleanId))
        : null;
    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : ((compName != null && compName.trim().isNotEmpty)
            ? compName.trim()
            : ((slug != null && slug.trim().isNotEmpty)
                ? slug.trim()
                : (lookupTitle ?? '')));

    final wasFav = forceFavorite != null
        ? !forceFavorite
        : isCompetitionFavorite(
            id: cleanId,
            name: effectiveName,
            slug: slug,
          );

    // Optimistic UI update: 0ms lag
    final updatedList = List<String>.from(state.favoriteCompetitions);
    final updatedTitles = Map<String, String>.from(state.competitionTitles);
    final updatedLogos = Map<String, String>.from(state.competitionLogos);

    final canonicalKey =
        (cleanId != null && cleanId.isNotEmpty) ? cleanId : effectiveName;
    final canonicalName =
        effectiveName.isNotEmpty ? effectiveName : (cleanId ?? '');

    if (wasFav) {
      if (cleanId != null && cleanId.isNotEmpty) {
        updatedTitles.remove(cleanId);
        updatedLogos.remove(cleanId);
        final rClean = LeagueResolver.resolveId(cleanId);
        if (rClean != null) {
          updatedTitles.remove(rClean);
          updatedLogos.remove(rClean);
        }
      }
      if (effectiveName.isNotEmpty) {
        updatedTitles.remove(effectiveName);
        updatedTitles.remove(effectiveName.toLowerCase());
        updatedLogos.remove(effectiveName);
      }
      final baseEffectiveName = effectiveName.contains('|')
          ? effectiveName.split('|').first.trim()
          : effectiveName;

      updatedList.removeWhere((item) {
        final itemTrim = item.trim();
        final itemLower = itemTrim.toLowerCase();
        final itemAsId = int.tryParse(itemTrim) != null ? itemTrim : null;

        // 1. Direct match by ID string or name string
        if (cleanId != null &&
            cleanId.isNotEmpty &&
            itemLower == cleanId.toLowerCase()) {
          return true;
        }
        if (effectiveName.isNotEmpty &&
            itemLower == effectiveName.toLowerCase()) {
          return true;
        }

        // Sub-stage mismatch protection:
        // E.g. 'CAF Champions League | Qualification' vs 'CAF Champions League'
        final itemHasStage = itemTrim.contains('|');
        final targetHasStage = effectiveName.contains('|');
        if (effectiveName.isNotEmpty && itemHasStage != targetHasStage) {
          if (cleanId == null || itemAsId == null) {
            return false;
          }
        }

        // 2. Both are numeric IDs: check if they are aliases for the same competition
        if (cleanId != null && cleanId.isNotEmpty && itemAsId != null) {
          return LeagueResolver.areSameCompetition(
            cleanId,
            itemTrim,
            idA: cleanId,
            idB: itemAsId,
          );
        }

        // 3. One is ID and one is Name, or both are Names:
        final favId = state.competitionTitles[itemTrim] ??
            state.competitionTitles[itemLower] ??
            LeagueResolver.resolveId(itemTrim) ??
            LocalStorageServiceImpl.defaultNameToId[itemLower];

        if (cleanId != null && cleanId.isNotEmpty) {
          if (LeagueResolver.areSameCompetition(
            itemTrim,
            effectiveName.isNotEmpty ? effectiveName : cleanId,
            idA: favId,
            idB: cleanId,
          )) {
            return true;
          }
          if (favId != null &&
              LeagueResolver.areSameCompetition(
                favId,
                cleanId,
                idA: favId,
                idB: cleanId,
              )) {
            return true;
          }
        }

        if (effectiveName.isNotEmpty) {
          if (LeagueResolver.areSameCompetition(
            itemTrim,
            effectiveName,
            idA: favId,
            idB: cleanId,
          )) {
            return true;
          }
        }

        if (baseEffectiveName.isNotEmpty &&
            (!itemHasStage && !targetHasStage)) {
          final itemBase = itemTrim.contains('|')
              ? itemTrim.split('|').first.trim()
              : itemTrim;
          if (itemBase.toLowerCase() == baseEffectiveName.toLowerCase()) {
            return true;
          }
        }

        return false;
      });
    } else {
      if (canonicalKey.isNotEmpty && !updatedList.contains(canonicalKey)) {
        updatedList.add(canonicalKey);
      }
      if (cleanId != null && cleanId.isNotEmpty && canonicalName.isNotEmpty) {
        updatedTitles[cleanId] = canonicalName;
        updatedTitles[canonicalName.toLowerCase()] = cleanId;
      }

      final resolvedLogo = (logo != null && logo.trim().isNotEmpty)
          ? logo.trim()
          : (UrlHelper.resolveChampionshipLogo(cleanId ?? canonicalName) ??
              UrlHelper.resolveChampionshipLogo(canonicalName));
      if (resolvedLogo != null && resolvedLogo.isNotEmpty) {
        final logoMap = <String, String>{};
        if (cleanId != null && cleanId.isNotEmpty) {
          logoMap[cleanId] = resolvedLogo;
          updatedLogos[cleanId] = resolvedLogo;
        }
        if (canonicalName.isNotEmpty) {
          logoMap[canonicalName] = resolvedLogo;
          updatedLogos[canonicalName] = resolvedLogo;
        }
        if (effectiveName.isNotEmpty) {
          logoMap[effectiveName] = resolvedLogo;
          updatedLogos[effectiveName] = resolvedLogo;
        }
        unawaited(_storage.registerCompetitionLogos(logoMap));
      }
    }

    emit(state.copyWith(
      favoriteCompetitions: updatedList,
      competitionTitles: updatedTitles,
      competitionLogos: updatedLogos,
    ));

    await _storage.setFavoriteCompetitions(updatedList);
    if (!wasFav && canonicalName.isNotEmpty && cleanId != null && cleanId.isNotEmpty) {
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
