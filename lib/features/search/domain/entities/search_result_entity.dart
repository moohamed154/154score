import 'package:equatable/equatable.dart';

/// Represents a single search result item from the API.
/// [type] is one of: 'championship', 'team', 'player'
class SearchResultEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String? fullTitle;
  final String? logo;
  final String? position; // for players
  final String? country; // for teams
  final String? countryCode;

  const SearchResultEntity({
    required this.id,
    required this.type,
    required this.title,
    this.fullTitle,
    this.logo,
    this.position,
    this.country,
    this.countryCode,
  });

  @override
  List<Object?> get props => [id, type, title];
}

class SearchResultsEntity extends Equatable {
  final String query;
  final List<SearchResultEntity> championships;
  final List<SearchResultEntity> teams;
  final List<SearchResultEntity> players;

  const SearchResultsEntity({
    required this.query,
    required this.championships,
    required this.teams,
    required this.players,
  });

  int get totalResults => championships.length + teams.length + players.length;

  @override
  List<Object?> get props => [query, championships, teams, players];
}
