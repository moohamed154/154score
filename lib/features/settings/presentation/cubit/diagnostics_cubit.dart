import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/diagnostics_repository.dart';

class DiagnosticsState extends Equatable {
  final bool isLoading;
  final String? pingResult;
  final String? healthResult;
  final String? metricsResult;
  final bool isTestingPing;
  final String? pingLatency;
  final bool onboardingCompleted;

  const DiagnosticsState({
    this.isLoading = false,
    this.pingResult,
    this.healthResult,
    this.metricsResult,
    this.isTestingPing = false,
    this.pingLatency,
    this.onboardingCompleted = false,
  });

  DiagnosticsState copyWith({
    bool? isLoading,
    String? pingResult,
    String? healthResult,
    String? metricsResult,
    bool? isTestingPing,
    String? pingLatency,
    bool? onboardingCompleted,
  }) {
    return DiagnosticsState(
      isLoading: isLoading ?? this.isLoading,
      pingResult: pingResult ?? this.pingResult,
      healthResult: healthResult ?? this.healthResult,
      metricsResult: metricsResult ?? this.metricsResult,
      isTestingPing: isTestingPing ?? this.isTestingPing,
      pingLatency: pingLatency ?? this.pingLatency,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        pingResult,
        healthResult,
        metricsResult,
        isTestingPing,
        pingLatency,
        onboardingCompleted,
      ];
}

class DiagnosticsCubit extends Cubit<DiagnosticsState> {
  final DiagnosticsRepository _diagnosticsRepository;
  final OnboardingRepository _onboardingRepository;

  DiagnosticsCubit({
    required DiagnosticsRepository diagnosticsRepository,
    required OnboardingRepository onboardingRepository,
  })  : _diagnosticsRepository = diagnosticsRepository,
        _onboardingRepository = onboardingRepository,
        super(
          DiagnosticsState(
            onboardingCompleted: onboardingRepository.isCompleted(),
          ),
        );

  void refreshOnboardingStatus() {
    emit(
      state.copyWith(
        onboardingCompleted: _onboardingRepository.isCompleted(),
      ),
    );
  }

  Future<void> resetOnboarding() async {
    await _onboardingRepository.resetOnboarding();
    if (isClosed) return;
    emit(
      state.copyWith(
        onboardingCompleted: _onboardingRepository.isCompleted(),
      ),
    );
  }

  Future<void> testPingLatency() async {
    emit(state.copyWith(isTestingPing: true));
    final stopwatch = Stopwatch()..start();
    try {
      await _diagnosticsRepository.ping();
      stopwatch.stop();
      if (isClosed) return;
      emit(
        state.copyWith(
          isTestingPing: false,
          pingLatency: '${stopwatch.elapsedMilliseconds} ms (OK)',
        ),
      );
    } catch (_) {
      stopwatch.stop();
      if (isClosed) return;
      emit(
        state.copyWith(
          isTestingPing: false,
          pingLatency: 'Failed (${stopwatch.elapsedMilliseconds} ms)',
        ),
      );
    }
  }

  Future<void> runDiagnostics() async {
    emit(state.copyWith(isLoading: true));

    String pingRes;
    try {
      pingRes = await _diagnosticsRepository.ping();
    } catch (e) {
      pingRes = 'Error: $e';
    }

    String healthRes;
    try {
      healthRes = await _diagnosticsRepository.checkServerHealth();
    } catch (e) {
      healthRes = 'Error: $e';
    }

    String metricsRes;
    try {
      metricsRes = await _diagnosticsRepository.fetchMetrics();
    } catch (e) {
      metricsRes = 'Error: $e';
    }

    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        pingResult: pingRes,
        healthResult: healthRes,
        metricsResult: metricsRes,
      ),
    );
  }
}
