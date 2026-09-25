import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';

// ─── Events ────────────────────────────────────────────────────────────────

abstract class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNewsFeedEvent extends NewsEvent {
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadNewsFeedEvent({this.isRefresh = false, this.completer});

  @override
  List<Object?> get props => [isRefresh];
}

class SelectTeamFilterEvent extends NewsEvent {
  final String? teamId;

  const SelectTeamFilterEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class ChangeNewsLanguageEvent extends NewsEvent {
  final String languageCode;
  final Completer<void>? completer;

  const ChangeNewsLanguageEvent(this.languageCode, {this.completer});

  @override
  List<Object?> get props => [languageCode];
}

// ─── State ─────────────────────────────────────────────────────────────────

enum NewsStatus { initial, loading, success, empty, error }

class NewsState extends Equatable {
  final NewsStatus status;
  final NewsFeedEntity? feed;
  final List<NewsArticleEntity> filteredLatest;
  final String? selectedTeamId;
  final String? errorMessage;
  final String lang;

  const NewsState({
    this.status = NewsStatus.initial,
    this.feed,
    this.filteredLatest = const [],
    this.selectedTeamId,
    this.errorMessage,
    this.lang = 'ar',
  });

  NewsState copyWith({
    NewsStatus? status,
    NewsFeedEntity? feed,
    List<NewsArticleEntity>? filteredLatest,
    String? selectedTeamId,
    bool clearTeamId = false,
    String? errorMessage,
    String? lang,
  }) {
    return NewsState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      filteredLatest: filteredLatest ?? this.filteredLatest,
      selectedTeamId: clearTeamId ? null : (selectedTeamId ?? this.selectedTeamId),
      errorMessage: errorMessage ?? this.errorMessage,
      lang: lang ?? this.lang,
    );
  }

  @override
  List<Object?> get props => [
    status,
    feed,
    filteredLatest,
    selectedTeamId,
    errorMessage,
    lang,
  ];
}

// ─── Bloc ──────────────────────────────────────────────────────────────────

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository repository;

  NewsBloc({
    required this.repository,
    required LocalStorageService localStorageService,
  }) : super(NewsState(lang: localStorageService.getLanguage())) {
    on<LoadNewsFeedEvent>(_onLoadFeed);
    on<SelectTeamFilterEvent>(_onSelectTeam);
    on<ChangeNewsLanguageEvent>(_onChangeLanguage);

    add(const LoadNewsFeedEvent());
  }

  Future<void> _onLoadFeed(
    LoadNewsFeedEvent event,
    Emitter<NewsState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: NewsStatus.loading));
    }

    final result = await repository.getNewsFeed(lang: state.lang);

    result.fold(
      onSuccess: (feed) {
        final filtered = _applyTeamFilter(feed.latest, state.selectedTeamId);
        if (feed.latest.isEmpty && feed.main == null) {
          emit(state.copyWith(status: NewsStatus.empty, feed: feed));
        } else {
          emit(
            state.copyWith(
              status: NewsStatus.success,
              feed: feed,
              filteredLatest: filtered,
            ),
          );
        }
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: NewsStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );

    event.completer?.complete();
  }

  Future<void> _onSelectTeam(
    SelectTeamFilterEvent event,
    Emitter<NewsState> emit,
  ) async {
    if (event.teamId == state.selectedTeamId) {
      // Deselect → show all latest
      final latest = state.feed?.latest ?? [];
      emit(
        state.copyWith(
          clearTeamId: true,
          filteredLatest: latest,
        ),
      );
      return;
    }

    final newTeamId = event.teamId;

    if (newTeamId == null) {
      emit(
        state.copyWith(
          clearTeamId: true,
          filteredLatest: state.feed?.latest ?? [],
        ),
      );
      return;
    }

    // Fetch team-filtered news
    emit(state.copyWith(selectedTeamId: newTeamId, status: NewsStatus.loading));

    final result = await repository.getTeamNews(
      teamId: newTeamId,
      lang: state.lang,
    );

    result.fold(
      onSuccess: (articles) {
        emit(
          state.copyWith(
            status: NewsStatus.success,
            filteredLatest: articles,
          ),
        );
      },
      onFailure: (_) {
        // Fall back to existing latest on error
        emit(
          state.copyWith(
            status: NewsStatus.success,
            filteredLatest: state.feed?.latest ?? [],
          ),
        );
      },
    );
  }

  Future<void> _onChangeLanguage(
    ChangeNewsLanguageEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(
      state.copyWith(lang: event.languageCode, status: NewsStatus.loading),
    );

    final result = await repository.getNewsFeed(lang: event.languageCode);

    result.fold(
      onSuccess: (feed) {
        final filtered = _applyTeamFilter(feed.latest, state.selectedTeamId);
        emit(
          state.copyWith(
            status: NewsStatus.success,
            feed: feed,
            filteredLatest: filtered,
          ),
        );
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: NewsStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );

    event.completer?.complete();
  }

  List<NewsArticleEntity> _applyTeamFilter(
    List<NewsArticleEntity> articles,
    String? teamId,
  ) {
    if (teamId == null) return articles;
    return articles;
  }
}
