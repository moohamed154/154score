import '../entities/internet_connection_status.dart';

abstract class InternetConnectionRepository {
  /// Stream emitting real-time internet accessibility changes.
  Stream<InternetConnectionStatus> get onStatusChanged;

  /// Performs an active external reachability check and returns current status.
  Future<InternetConnectionStatus> checkInternetAccess();

  /// Convenient boolean accessor for immediate reachability check.
  Future<bool> get isConnected;

  /// Releases stream subscriptions and background timers.
  void dispose();
}
