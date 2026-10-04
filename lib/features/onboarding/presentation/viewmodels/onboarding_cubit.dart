import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/onboarding_repository.dart';

enum OnboardingStatus { inProgress, completed }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.page = 0,
    this.selectedTeams = const {},
    this.selectedLeagues = const {},
    this.status = OnboardingStatus.inProgress,
  });

  static const int pageCount = 4;

  final int page;

  /// Arabic canonical names of the selected teams.
  final Set<String> selectedTeams;

  /// Arabic canonical names of the selected leagues.
  final Set<String> selectedLeagues;
  final OnboardingStatus status;

  bool get isLastPage => page == pageCount - 1;

  OnboardingState copyWith({
    int? page,
    Set<String>? selectedTeams,
    Set<String>? selectedLeagues,
    OnboardingStatus? status,
  }) {
    return OnboardingState(
      page: page ?? this.page,
      selectedTeams: selectedTeams ?? this.selectedTeams,
      selectedLeagues: selectedLeagues ?? this.selectedLeagues,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [page, selectedTeams, selectedLeagues, status];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository) : super(const OnboardingState());

  final OnboardingRepository _repository;

  void next() {
    if (state.isLastPage) return;
    emit(state.copyWith(page: state.page + 1));
  }

  void back() {
    if (state.page == 0) return;
    emit(state.copyWith(page: state.page - 1));
  }

  void goTo(int page) {
    if (page == state.page || page < 0 || page >= OnboardingState.pageCount) {
      return;
    }
    emit(state.copyWith(page: page));
  }

  void toggleTeam(String arabicName) {
    final updated = Set<String>.from(state.selectedTeams);
    if (!updated.add(arabicName)) updated.remove(arabicName);
    emit(state.copyWith(selectedTeams: updated));
  }

  void toggleLeague(String arabicName) {
    final updated = Set<String>.from(state.selectedLeagues);
    if (!updated.add(arabicName)) updated.remove(arabicName);
    emit(state.copyWith(selectedLeagues: updated));
  }

  /// Persists the completion flag so the flow is shown only once.
  Future<void> complete() async {
    await _repository.markCompleted();
    emit(state.copyWith(status: OnboardingStatus.completed));
  }
}
