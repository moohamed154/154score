import 'package:equatable/equatable.dart';

import '../../domain/entities/player_profile_entity.dart';

enum PlayerStatus { initial, loading, success, error }

class PlayerState extends Equatable {
  final PlayerStatus status;
  final String playerId;
  final String? playerName;
  final String? playerPhoto;
  final PlayerProfileEntity? profile;
  final int selectedTab;
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerStatus.initial,
    required this.playerId,
    this.playerName,
    this.playerPhoto,
    this.profile,
    this.selectedTab = 0,
    this.errorMessage,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    String? playerId,
    String? playerName,
    String? playerPhoto,
    PlayerProfileEntity? profile,
    int? selectedTab,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerPhoto: playerPhoto ?? this.playerPhoto,
      profile: profile ?? this.profile,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playerId,
        playerName,
        playerPhoto,
        profile,
        selectedTab,
        errorMessage,
      ];
}
