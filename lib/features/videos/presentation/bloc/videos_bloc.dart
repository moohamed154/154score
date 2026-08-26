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

  const LoadVideosEvent({this.champId = 'all', this.isRefresh = false});

  @override
  List<Object?> get props => [champId, isRefresh];
}

class SelectVideoCategoryEvent extends VideosEvent {
  final String categoryId;

  const SelectVideoCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
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
  List<Object?> get props => [status, selectedCategory, categories, videos, errorMessage];
}

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideosRepository _repository;
  final LocalStorageService _localStorageService;

  VideosBloc({
    required VideosRepository repository,
    required LocalStorageService localStorageService,
  })  : _repository = repository,
        _localStorageService = localStorageService,
        super(const VideosState()) {
    on<LoadVideosEvent>(_onLoadVideos);
    on<SelectVideoCategoryEvent>(_onSelectCategory);
  }

  Future<void> _onLoadVideos(
    LoadVideosEvent event,
    Emitter<VideosState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: VideosStatus.loading, selectedCategory: event.champId));
    }

    final lang = _localStorageService.getLanguage();

    try {
      final results = await Future.wait([
        _repository.getVideos(champId: event.champId, lang: lang),
        _repository.getCategories(lang: lang),
      ]);

      final videosRes = results[0].dataOrNull as List<VideoItemEntity>? ?? [];
      final categoriesRes = results[1].dataOrNull as List<VideoCategoryEntity>? ?? [];

      emit(state.copyWith(
        status: videosRes.isEmpty ? VideosStatus.empty : VideosStatus.success,
        videos: videosRes,
        categories: categoriesRes.isNotEmpty ? categoriesRes : state.categories,
        selectedCategory: event.champId,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VideosStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSelectCategory(
    SelectVideoCategoryEvent event,
    Emitter<VideosState> emit,
  ) {
    add(LoadVideosEvent(champId: event.categoryId));
  }
}
