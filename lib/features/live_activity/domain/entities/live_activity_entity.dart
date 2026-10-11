import 'package:equatable/equatable.dart';

class LiveActivityEntity extends Equatable {
  final String activityId;
  final String matchId;
  final String? pushToken;
  final bool isTracking;

  const LiveActivityEntity({
    required this.activityId,
    required this.matchId,
    this.pushToken,
    this.isTracking = true,
  });

  LiveActivityEntity copyWith({
    String? activityId,
    String? matchId,
    String? pushToken,
    bool? isTracking,
  }) {
    return LiveActivityEntity(
      activityId: activityId ?? this.activityId,
      matchId: matchId ?? this.matchId,
      pushToken: pushToken ?? this.pushToken,
      isTracking: isTracking ?? this.isTracking,
    );
  }

  @override
  List<Object?> get props => [activityId, matchId, pushToken, isTracking];
}
