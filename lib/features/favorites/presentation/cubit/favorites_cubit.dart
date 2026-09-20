import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';

class FavoritesState extends Equatable {
  final List<String> favoriteTeams;
  final List<String> favoriteCompetitions;
  final List<String> favoriteMatches;
  final Map<String, String> competitionTitles;

  const FavoritesState({
    this.favoriteTeams = const [],
    this.favoriteCompetitions = const [],
    this.favoriteMatches = const [],
    this.competitionTitles = const {},
  });

  FavoritesState copyWith({
    List<String>? favoriteTeams,
    List<String>? favoriteCompetitions,
    List<String>? favoriteMatches,
    Map<String, String>? competitionTitles,
  }) {
    return FavoritesState(
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      favoriteCompetitions: favoriteCompetitions ?? this.favoriteCompetitions,
      favoriteMatches: favoriteMatches ?? this.favoriteMatches,
      competitionTitles: competitionTitles ?? this.competitionTitles,
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

    for (final fav in favoriteCompetitions) {
      final cleanFav = fav.trim().toLowerCase();
      if (targets.contains(cleanFav)) return true;
      if (competitionTitles.containsKey(fav.trim())) {
        final mapped = competitionTitles[fav.trim()]!.trim().toLowerCase();
        if (targets.contains(mapped)) return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [
    favoriteTeams,
    favoriteCompetitions,
    favoriteMatches,
    competitionTitles,
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
      ),
    );
  }

  bool isCompetitionFavorite({String? id, String? name, String? slug}) {
    return state.isFavoriteCompetition(id: id, name: name, slug: slug);
  }

  Future<void> toggleTeam(String teamName) async {
    await _storage.toggleFavoriteTeam(teamName);
    loadFavorites();
  }

  Future<void> toggleCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) async {
    final effectiveName = name ?? compName;
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
    await _storage.toggleFavoriteMatch(matchId);
    loadFavorites();
  }
}
