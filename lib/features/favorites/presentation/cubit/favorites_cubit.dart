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

    final cleanId = id?.trim();
    final cleanName = name?.trim();
    final cleanSlug = slug?.trim();

    for (final fav in favoriteCompetitions) {
      final favTrim = fav.trim();
      final mappedId = competitionTitles[favTrim];
      if (LeagueResolver.areSameCompetition(
        favTrim,
        cleanName,
        idA: mappedId,
        idB: cleanId,
      )) {
        return true;
      }
      if (cleanSlug != null && cleanSlug.isNotEmpty) {
        if (LeagueResolver.areSameCompetition(
          favTrim,
          cleanSlug,
          idA: mappedId,
          idB: cleanId,
        )) {
          return true;
        }
      }
      if (cleanId != null && cleanId.isNotEmpty) {
        if (LeagueResolver.areSameCompetition(
          favTrim,
          null,
          idA: mappedId,
          idB: cleanId,
        )) {
          return true;
        }
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

