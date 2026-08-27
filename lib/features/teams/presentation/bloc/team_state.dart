import 'package:equatable/equatable.dart';

import '../../domain/entities/team_entity.dart';

enum TeamStatus { initial, loading, success, error }

class TeamState extends Equatable {
  final TeamStatus status;
  final String teamId;
  final String? teamName;
  final String? teamLogo;
  final TeamProfileEntity? profile;
  final int selectedTab;
  final String? errorMessage;

  const TeamState({
    this.status = TeamStatus.initial,
    required this.teamId,
    this.teamName,
    this.teamLogo,
    this.profile,
    this.selectedTab = 0,
    this.errorMessage,
  });

  TeamState copyWith({
    TeamStatus? status,
    String? teamId,
    String? teamName,
    String? teamLogo,
    TeamProfileEntity? profile,
    int? selectedTab,
    String? errorMessage,
  }) {
    return TeamState(
      status: status ?? this.status,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamLogo: teamLogo ?? this.teamLogo,
      profile: profile ?? this.profile,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    teamId,
    teamName,
    teamLogo,
    profile,
    selectedTab,
    errorMessage,
  ];
}
