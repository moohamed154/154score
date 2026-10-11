import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../domain/repositories/live_activity_repository.dart';
import 'live_activity_state.dart';

class LiveActivityCubit extends Cubit<LiveActivityState> {
  final LiveActivityRepository _repository;
  StreamSubscription<String>? _trackingStoppedSubscription;

  LiveActivityCubit({
    required LiveActivityRepository repository,
  })  : _repository = repository,
        super(const LiveActivityState()) {
    _init();
  }

  Future<void> _init() async {
    final supported = await _repository.areActivitiesSupported();
    final activeIds = await _repository.getActiveTrackedMatchIds();
    emit(state.copyWith(
      isSupported: supported,
      trackedMatchIds: activeIds.toSet(),
    ));

    _trackingStoppedSubscription =
        _repository.onTrackingStoppedStream.listen((matchId) {
      final clean = matchId.replaceAll('match:', '').trim();
      final updated = Set<String>.from(state.trackedMatchIds)..remove(clean);
      emit(state.copyWith(trackedMatchIds: updated));
    });
  }

  Future<void> checkSupport() async {
    final supported = await _repository.areActivitiesSupported();
    emit(state.copyWith(isSupported: supported));
  }

  Future<void> loadActiveActivities() async {
    final activeIds = await _repository.getActiveTrackedMatchIds();
    emit(state.copyWith(trackedMatchIds: activeIds.toSet()));
  }

  Future<bool> startTracking({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
  }) async {
    emit(state.copyWith(status: LiveActivityStatus.loading));
    final cleanId = match.id.replaceAll('match:', '').trim();

    final result = await _repository.startTrackingMatch(
      match: match,
      liveScore1: liveScore1,
      liveScore2: liveScore2,
      liveMinute: liveMinute,
      liveStatus: liveStatus,
      liveStatusCode: liveStatusCode,
      livePeriod: livePeriod,
    );

    if (result is ApiSuccess) {
      final updated = Set<String>.from(state.trackedMatchIds)..add(cleanId);
      emit(state.copyWith(
        status: LiveActivityStatus.success,
        trackedMatchIds: updated,
      ));
      return true;
    } else if (result is ApiFailure) {
      emit(state.copyWith(
        status: LiveActivityStatus.failure,
        errorMessage: (result as ApiFailure).failure.message,
      ));
      return false;
    }
    return false;
  }

  Future<void> updateTracking({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
    String? penaltyScore1,
    String? penaltyScore2,
  }) async {
    final cleanId = match.id.replaceAll('match:', '').trim();
    if (!state.trackedMatchIds.contains(cleanId)) return;

    await _repository.updateTrackingMatch(
      match: match,
      liveScore1: liveScore1,
      liveScore2: liveScore2,
      liveMinute: liveMinute,
      liveStatus: liveStatus,
      liveStatusCode: liveStatusCode,
      livePeriod: livePeriod,
      penaltyScore1: penaltyScore1,
      penaltyScore2: penaltyScore2,
    );
  }

  Future<bool> stopTracking(String matchId) async {
    emit(state.copyWith(status: LiveActivityStatus.loading));
    final cleanId = matchId.replaceAll('match:', '').trim();

    final result = await _repository.stopTrackingMatch(cleanId);
    if (result is ApiSuccess) {
      final updated = Set<String>.from(state.trackedMatchIds)..remove(cleanId);
      emit(state.copyWith(
        status: LiveActivityStatus.success,
        trackedMatchIds: updated,
      ));
      return true;
    } else if (result is ApiFailure) {
      emit(state.copyWith(
        status: LiveActivityStatus.failure,
        errorMessage: (result as ApiFailure).failure.message,
      ));
      return false;
    }
    return false;
  }

  Future<bool> toggleTracking({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
  }) async {
    final cleanId = match.id.replaceAll('match:', '').trim();
    if (state.isTracking(cleanId)) {
      return await stopTracking(cleanId);
    } else {
      return await startTracking(
        match: match,
        liveScore1: liveScore1,
        liveScore2: liveScore2,
        liveMinute: liveMinute,
        liveStatus: liveStatus,
        liveStatusCode: liveStatusCode,
        livePeriod: livePeriod,
      );
    }
  }

  @override
  Future<void> close() {
    _trackingStoppedSubscription?.cancel();
    return super.close();
  }
}
