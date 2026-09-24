import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/videos_repository.dart';

abstract class VideosEvent extends Equatable {
  const VideosEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideosEvent extends VideosEvent {
  final String champId;
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadVideosEvent({
    this.champId = 'all',
    this.isRefresh = false,
    this.completer,
  });

  @override
  List<Object?> get props => [champId, isRefresh];
}

class SelectVideoCategoryEvent extends VideosEvent {
  final String categoryId;

  const SelectVideoCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class ChangeVideosLanguageEvent extends VideosEvent {
  final String languageCode;
  final Completer<void>? completer;

  const ChangeVideosLanguageEvent(this.languageCode, {this.completer});

  @override
  List<Object?> get props => [languageCode];
}

enum VideosStatus { initial, loading, success, empty, error }

class VideosState extends Equatable {
  final VideosStatus status;
  final String selectedCategory;
  final List<VideoCategoryEntity> categories;
  final List<VideoItemEntity> videos;
  final String? errorMessage;

  const VideosState({
    this.status = VideosStatus.initial,
    this.selectedCategory = 'all',
    this.categories = const [],
    this.videos = const [],
    this.errorMessage,
  });

  VideosState copyWith({
    VideosStatus? status,
    String? selectedCategory,
    List<VideoCategoryEntity>? categories,
    List<VideoItemEntity>? videos,
    String? errorMessage,
  }) {
    return VideosState(
      status: status ?? this.status,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categories: categories ?? this.categories,
      videos: videos ?? this.videos,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedCategory,
    categories,
    videos,
    errorMessage,
  ];
}

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideosRepository repository;
  final LocalStorageService localStorageService;

  VideosBloc({required this.repository, required this.localStorageService})
    : super(const VideosState()) {
    on<LoadVideosEvent>(_onLoadVideos);
    on<SelectVideoCategoryEvent>(_onSelectCategory);
    on<ChangeVideosLanguageEvent>(_onChangeVideosLanguage);
  }

  Future<void> _onLoadVideos(
    LoadVideosEvent event,
    Emitter<VideosState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(
        state.copyWith(
          status: VideosStatus.loading,
          selectedCategory: event.champId,
        ),
      );
    }

    final lang = localStorageService.getLanguage();

    try {
      final videosFuture = repository.getVideos(
        champId: event.champId,
        lang: lang,
      );
      final categoriesFuture = repository.getCategories(lang: lang);

      final videosRes = (await videosFuture).dataOrNull ?? [];
      final categoriesRes = (await categoriesFuture).dataOrNull ?? [];

      emit(
        state.copyWith(
          status: videosRes.isEmpty ? VideosStatus.empty : VideosStatus.success,
          videos: videosRes,
          categories: categoriesRes.isNotEmpty
              ? categoriesRes
              : state.categories,
          selectedCategory: event.champId,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: VideosStatus.error, errorMessage: e.toString()),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onChangeVideosLanguage(
    ChangeVideosLanguageEvent event,
    Emitter<VideosState> emit,
  ) async {
    final targetLang = event.languageCode;
    try {
      final videosFuture = repository.getVideos(
        champId: state.selectedCategory,
        lang: targetLang,
      );
      final categoriesFuture = repository.getCategories(lang: targetLang);

      final videosRes = (await videosFuture).dataOrNull ?? [];
      final categoriesRes = (await categoriesFuture).dataOrNull ?? [];

      // Race condition check: make sure current language is still targetLang
      final currentLang = localStorageService.getLanguage();
      if (currentLang != targetLang) return;

      emit(
        state.copyWith(
          status: videosRes.isEmpty ? VideosStatus.empty : VideosStatus.success,
          videos: videosRes,
          categories: categoriesRes.isNotEmpty
              ? categoriesRes
              : state.categories,
          errorMessage: null,
        ),
      );
    } catch (_) {
      // Keep existing videos visible
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  void _onSelectCategory(
    SelectVideoCategoryEvent event,
    Emitter<VideosState> emit,
  ) {
    add(LoadVideosEvent(champId: event.categoryId));
  }
}
