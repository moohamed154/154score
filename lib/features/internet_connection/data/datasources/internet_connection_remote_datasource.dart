import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class InternetConnectionRemoteDataSource {
  /// Emits whenever the underlying reachability status changes.
  Stream<bool> get onInternetAccessChanged;

  /// Performs an active verification of actual internet reachability.
  Future<bool> hasInternetAccess();

  /// Releases resources.
  void dispose();
}

class InternetConnectionRemoteDataSourceImpl
    implements InternetConnectionRemoteDataSource {
  final InternetConnection _internetConnection;
  StreamSubscription<InternetStatus>? _subscription;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  InternetConnectionRemoteDataSourceImpl({
    InternetConnection? internetConnection,
  }) : _internetConnection = internetConnection ?? InternetConnection() {
    _initListener();
  }

  void _initListener() {
    try {
      _subscription = _internetConnection.onStatusChange.listen(
        (status) {
          final isConnected = status == InternetStatus.connected;
          if (!_statusController.isClosed) {
            _statusController.add(isConnected);
          }
        },
        onError: (Object error) {
          debugPrint(
              '[InternetConnectionDataSource] onStatusChange error: $error');
          if (!_statusController.isClosed) {
            _statusController.add(false);
          }
        },
      );
    } catch (e) {
      debugPrint('[InternetConnectionDataSource] init error: $e');
    }
  }

  @override
  Stream<bool> get onInternetAccessChanged => _statusController.stream;

  @override
  Future<bool> hasInternetAccess() async {
    try {
      return await _internetConnection.hasInternetAccess;
    } catch (e) {
      debugPrint(
          '[InternetConnectionDataSource] hasInternetAccess check failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    try {
      _subscription?.cancel();
      _statusController.close();
    } catch (e) {
      debugPrint('[InternetConnectionDataSource] dispose error: $e');
    }
  }
}
