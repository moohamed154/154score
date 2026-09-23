import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _repository;
  Timer? _debounce;

  SearchCubit(this._repository) : super(const SearchState());

  /// Called on every keystroke. Debounces 400ms before hitting the API.
  void onQueryChanged(String query, {String lang = 'ar'}) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _debounce?.cancel();
      emit(const SearchState(status: SearchStatus.idle, query: ''));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, query: trimmed));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchResults(trimmed, lang);
    });
  }

  Future<void> _fetchResults(String query, String lang) async {
    final result = await _repository.search(query, lang: lang);

    result.fold(
      onSuccess: (data) {
        if (data.totalResults == 0) {
          emit(state.copyWith(status: SearchStatus.empty, results: data));
        } else {
          emit(state.copyWith(status: SearchStatus.success, results: data));
        }
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: SearchStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  void clear() {
    _debounce?.cancel();
    emit(const SearchState(status: SearchStatus.idle, query: ''));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
