import 'package:equatable/equatable.dart';

import '../../domain/entities/search_result_entity.dart';

enum SearchStatus { idle, loading, success, empty, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final SearchResultsEntity? results;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results,
    this.errorMessage,
  });

  bool get hasResults =>
      results != null && results!.totalResults > 0;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    SearchResultsEntity? results,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, query, results, errorMessage];
}
