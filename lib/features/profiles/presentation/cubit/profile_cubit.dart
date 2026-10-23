import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profiles_repository.dart';

enum ProfileType { stadium, referee, commentator, player, coach }

enum ProfileStatus { initial, loading, success, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileEntity? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileEntity? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfilesRepository _repository;
  final LocalStorageService _localStorageService;

  ProfileCubit({
    required ProfilesRepository repository,
    required LocalStorageService localStorageService,
  })  : _repository = repository,
        _localStorageService = localStorageService,
        super(const ProfileState());

  Future<void> loadProfile({
    required String id,
    required String slug,
    required ProfileType type,
  }) async {
    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: null));

    try {
      final lang = _localStorageService.getLanguage();
      final result = await switch (type) {
        ProfileType.stadium => _repository.getStadiumProfile(
            id,
            slug,
            lang: lang,
          ),
        ProfileType.referee => _repository.getRefereeProfile(
            id,
            slug,
            lang: lang,
          ),
        ProfileType.commentator => _repository.getCommentatorProfile(
            id,
            slug,
            lang: lang,
          ),
        ProfileType.player => _repository.getPlayerProfile(
            id,
            slug,
            lang: lang,
          ),
        ProfileType.coach => _repository.getCoachProfile(
            id,
            slug,
            lang: lang,
          ),
      };

      if (isClosed) return;

      result.fold(
        onSuccess: (profile) {
          emit(
            state.copyWith(
              status: ProfileStatus.success,
              profile: profile,
              errorMessage: null,
            ),
          );
        },
        onFailure: (failure) {
          emit(
            state.copyWith(
              status: ProfileStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
