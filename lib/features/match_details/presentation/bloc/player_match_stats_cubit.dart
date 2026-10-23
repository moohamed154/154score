import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/player_match_rating_entity.dart';
import '../../domain/repositories/match_details_repository.dart';

class PlayerMatchStatsState extends Equatable {
  final bool isLoading;
  final PlayerMatchRatingEntity? ratingData;
  final String? errorMessage;

  const PlayerMatchStatsState({
    this.isLoading = true,
    this.ratingData,
    this.errorMessage,
  });

  PlayerMatchStatsState copyWith({
    bool? isLoading,
    PlayerMatchRatingEntity? ratingData,
    String? errorMessage,
  }) {
    return PlayerMatchStatsState(
      isLoading: isLoading ?? this.isLoading,
      ratingData: ratingData ?? this.ratingData,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, ratingData, errorMessage];
}

class PlayerMatchStatsCubit extends Cubit<PlayerMatchStatsState> {
  final MatchDetailsRepository _repository;

  PlayerMatchStatsCubit({
    required MatchDetailsRepository repository,
  })  : _repository = repository,
        super(const PlayerMatchStatsState());

  Future<void> loadPlayerRating({
    required String matchId,
    required String? playerId,
    required bool isArabic,
  }) async {
    final trimmedId = playerId?.trim();
    if (trimmedId == null || trimmedId.isEmpty || trimmedId == '0') {
      emit(const PlayerMatchStatsState(isLoading: false));
      return;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final res = await _repository.getPlayerMatchRating(
        matchId,
        trimmedId,
        lang: isArabic ? 'ar' : 'en',
      );
      if (isClosed) return;
      emit(
        PlayerMatchStatsState(
          isLoading: false,
          ratingData: res.dataOrNull,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        PlayerMatchStatsState(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
