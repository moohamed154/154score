import 'package:equatable/equatable.dart';
import '../../domain/entities/internet_connection_status.dart';

class InternetConnectionState extends Equatable {
  final InternetConnectionStatus status;
  final bool isRetrying;
  final bool hasRecovered;
  final DateTime? lastCheckedAt;
  final String? errorMessage;

  const InternetConnectionState({
    this.status = InternetConnectionStatus.checking,
    this.isRetrying = false,
    this.hasRecovered = false,
    this.lastCheckedAt,
    this.errorMessage,
  });

  bool get isConnected => status == InternetConnectionStatus.connected;
  bool get isDisconnected => status == InternetConnectionStatus.disconnected;
  bool get isChecking => status == InternetConnectionStatus.checking;

  InternetConnectionState copyWith({
    InternetConnectionStatus? status,
    bool? isRetrying,
    bool? hasRecovered,
    DateTime? lastCheckedAt,
    String? errorMessage,
  }) {
    return InternetConnectionState(
      status: status ?? this.status,
      isRetrying: isRetrying ?? this.isRetrying,
      hasRecovered: hasRecovered ?? this.hasRecovered,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isRetrying,
        hasRecovered,
        lastCheckedAt,
        errorMessage,
      ];
}
