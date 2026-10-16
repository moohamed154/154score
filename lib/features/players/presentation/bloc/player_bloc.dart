import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/repositories/player_repository.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final PlayerRepository repository;
  final LocalStorageService localStorageService;

  String? _currentSlug;

  PlayerBloc({
    required this.repository,
    required this.localStorageService,
    String? initialId,
    String? initialName,
    String? initialPhoto,
    String? initialSlug,
  })  : _currentSlug = initialSlug,
        super(
          PlayerState(
            playerId: initialId ?? '',
            playerName: initialName,
            playerPhoto: initialPhoto,
          ),
        ) {
    on<LoadPlayerProfileEvent>(_onLoadPlayerProfile);
    on<ChangePlayerTabEvent>(_onChangePlayerTab);
    on<RefreshPlayerProfileEvent>(_onRefreshPlayerProfile);

    if (initialId != null && initialId.isNotEmpty) {
      add(
        LoadPlayerProfileEvent(
          initialId,
          slug: initialSlug,
          fallbackName: initialName,
          fallbackPhoto: initialPhoto,
        ),
      );
    }
  }

  Future<void> _onLoadPlayerProfile(
    LoadPlayerProfileEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _currentSlug = event.slug ?? _currentSlug;
    emit(
      state.copyWith(
        status: PlayerStatus.loading,
        playerId: event.id,
        playerName: event.fallbackName ?? state.playerName,
        playerPhoto: event.fallbackPhoto ?? state.playerPhoto,
        errorMessage: null,
      ),
    );

    final lang = localStorageService.getLanguage();
    final result = await repository.getPlayerProfile(
      event.id,
      slug: event.slug,
      lang: lang,
    );

    result.fold(
      onSuccess: (profile) {
        emit(
          state.copyWith(
            status: PlayerStatus.success,
            profile: profile,
            playerId: profile.id.isNotEmpty ? profile.id : state.playerId,
            playerName:
                profile.name.isNotEmpty ? profile.name : state.playerName,
            playerPhoto: profile.photo ?? state.playerPhoto,
          ),
        );
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: PlayerStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  void _onChangePlayerTab(
    ChangePlayerTabEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  Future<void> _onRefreshPlayerProfile(
    RefreshPlayerProfileEvent event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.playerId.isEmpty) return;

    final lang = localStorageService.getLanguage();
    final result = await repository.getPlayerProfile(
      state.playerId,
      slug: _currentSlug,
      lang: lang,
    );

    result.fold(
      onSuccess: (profile) {
        emit(
          state.copyWith(
            status: PlayerStatus.success,
            profile: profile,
            playerId: profile.id.isNotEmpty ? profile.id : state.playerId,
            playerName:
                profile.name.isNotEmpty ? profile.name : state.playerName,
            playerPhoto: profile.photo ?? state.playerPhoto,
          ),
        );
      },
      onFailure: (_) {
        // Retain current view on background pull-to-refresh failure
      },
    );
  }
}
