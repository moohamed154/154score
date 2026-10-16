import 'package:equatable/equatable.dart';

enum LiveActivityStatus { initial, loading, success, failure }

class LiveActivityState extends Equatable {
  final LiveActivityStatus status;
  final Set<String> trackedMatchIds;
  final bool isSupported;
  final bool isFeatureEnabled;
  final String? errorMessage;

  const LiveActivityState({
    this.status = LiveActivityStatus.initial,
    this.trackedMatchIds = const {},
    this.isSupported = false,
    this.isFeatureEnabled = false,
    this.errorMessage,
  });

  bool isTracking(String matchId) {
    final clean = matchId.replaceAll('match:', '').trim();
    return trackedMatchIds.contains(clean);
  }

  LiveActivityState copyWith({
    LiveActivityStatus? status,
    Set<String>? trackedMatchIds,
    bool? isSupported,
    bool? isFeatureEnabled,
    String? errorMessage,
  }) {
    return LiveActivityState(
      status: status ?? this.status,
      trackedMatchIds: trackedMatchIds ?? this.trackedMatchIds,
      isSupported: isSupported ?? this.isSupported,
      isFeatureEnabled: isFeatureEnabled ?? this.isFeatureEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        trackedMatchIds,
        isSupported,
        isFeatureEnabled,
        errorMessage,
      ];
}
