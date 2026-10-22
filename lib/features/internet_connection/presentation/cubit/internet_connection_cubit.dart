import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/internet_connection_status.dart';
import '../../domain/repositories/internet_connection_repository.dart';
import 'internet_connection_state.dart';

class InternetConnectionCubit extends Cubit<InternetConnectionState> {
  final InternetConnectionRepository _repository;
  StreamSubscription<InternetConnectionStatus>? _statusSubscription;
  Timer? _debounceTimer;

  InternetConnectionCubit({
    required InternetConnectionRepository repository,
  })  : _repository = repository,
        super(const InternetConnectionState()) {
    _init();
  }

  void _init() {
    // 1. Initial reachability check on startup
    checkConnection();

    // 2. Subscribe to real-time status transitions with debouncing
    _statusSubscription = _repository.onStatusChanged.listen((newStatus) {
      _handleStatusUpdate(newStatus);
    });
  }

  void _handleStatusUpdate(InternetConnectionStatus newStatus) {
    _debounceTimer?.cancel();

    // If already in this status, do not duplicate emissions
    if (state.status == newStatus && !state.isRetrying) {
      return;
    }

    if (newStatus == InternetConnectionStatus.disconnected) {
      // Debounce short disconnect blips (350ms) to prevent UI flickering on cellular handoff
      _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
        if (isClosed) return;
        // Verify reachability once more before committing to offline blocking state
        final confirmedStatus = await _repository.checkInternetAccess();
        if (isClosed) return;
        emit(state.copyWith(
          status: confirmedStatus,
          isRetrying: false,
          hasRecovered: false,
          lastCheckedAt: DateTime.now(),
        ));
      });
    } else {
      // When recovering or reconnecting, emit immediately to dismiss the dialog fast
      emit(state.copyWith(
        status: InternetConnectionStatus.connected,
        isRetrying: false,
        hasRecovered: state.status == InternetConnectionStatus.disconnected,
        lastCheckedAt: DateTime.now(),
      ));
    }
  }

  /// Actively checks internet access (e.g. startup, resume, or background sync)
  Future<void> checkConnection({bool silent = false}) async {
    if (!silent && !state.isRetrying) {
      // Don't show full checking screen if already connected unless retrying
    }

    try {
      final status = await _repository.checkInternetAccess();
      if (isClosed) return;

      emit(state.copyWith(
        status: status,
        isRetrying: false,
        hasRecovered: state.status == InternetConnectionStatus.disconnected &&
            status == InternetConnectionStatus.connected,
        lastCheckedAt: DateTime.now(),
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: InternetConnectionStatus.disconnected,
        isRetrying: false,
        lastCheckedAt: DateTime.now(),
        errorMessage: e.toString(),
      ));
    }
  }

  /// Manual Retry triggered by user tapping the "Retry" button on the blocking dialog
  Future<bool> retryConnection() async {
    if (state.isRetrying) return false;

    emit(state.copyWith(isRetrying: true));

    try {
      // Allow slight minimum loading feedback (400ms) so the user sees the spinner working
      final results = await Future.wait([
        _repository.checkInternetAccess(),
        Future<void>.delayed(const Duration(milliseconds: 400)),
      ]);

      final status = results.first as InternetConnectionStatus;
      if (isClosed) return false;

      final isSuccess = status == InternetConnectionStatus.connected;
      emit(state.copyWith(
        status: status,
        isRetrying: false,
        hasRecovered: isSuccess,
        lastCheckedAt: DateTime.now(),
      ));
      return isSuccess;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        status: InternetConnectionStatus.disconnected,
        isRetrying: false,
        lastCheckedAt: DateTime.now(),
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Called when the application returns to foreground (AppLifecycleState.resumed)
  void onAppResumed() {
    checkConnection(silent: true);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _statusSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
