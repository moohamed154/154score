import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';

class FavoritesState extends Equatable {
  final List<String> favoriteTeams;
  final List<String> favoriteCompetitions;
  final List<String> favoriteMatches;

  const FavoritesState({
    this.favoriteTeams = const [],
    this.favoriteCompetitions = const [],
    this.favoriteMatches = const [],
  });

  FavoritesState copyWith({
    List<String>? favoriteTeams,
    List<String>? favoriteCompetitions,
    List<String>? favoriteMatches,
  }) {
    return FavoritesState(
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      favoriteCompetitions: favoriteCompetitions ?? this.favoriteCompetitions,
      favoriteMatches: favoriteMatches ?? this.favoriteMatches,
    );
  }

  @override
  List<Object?> get props => [
    favoriteTeams,
    favoriteCompetitions,
    favoriteMatches,
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
      ),
    );
  }

  Future<void> toggleTeam(String teamName) async {
    await _storage.toggleFavoriteTeam(teamName);
    loadFavorites();
  }

  Future<void> toggleCompetition(String compName) async {
    await _storage.toggleFavoriteCompetition(compName);
    loadFavorites();
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
