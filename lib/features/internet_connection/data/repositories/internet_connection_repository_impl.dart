import 'dart:async';
import '../../domain/entities/internet_connection_status.dart';
import '../../domain/repositories/internet_connection_repository.dart';
import '../datasources/internet_connection_remote_datasource.dart';

class InternetConnectionRepositoryImpl implements InternetConnectionRepository {
  final InternetConnectionRemoteDataSource _remoteDataSource;
  final StreamController<InternetConnectionStatus> _statusController =
      StreamController<InternetConnectionStatus>.broadcast();
  StreamSubscription<bool>? _dataSourceSubscription;
  InternetConnectionStatus _lastStatus = InternetConnectionStatus.checking;

  InternetConnectionRepositoryImpl({
    required InternetConnectionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource {
    _init();
  }

  void _init() {
    _dataSourceSubscription =
        _remoteDataSource.onInternetAccessChanged.listen((hasAccess) {
      final newStatus = hasAccess
          ? InternetConnectionStatus.connected
          : InternetConnectionStatus.disconnected;
      _lastStatus = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    });
  }

  @override
  Stream<InternetConnectionStatus> get onStatusChanged =>
      _statusController.stream;

  @override
  Future<InternetConnectionStatus> checkInternetAccess() async {
    final hasAccess = await _remoteDataSource.hasInternetAccess();
    final status = hasAccess
        ? InternetConnectionStatus.connected
        : InternetConnectionStatus.disconnected;
    _lastStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    return status;
  }

  @override
  Future<bool> get isConnected async {
    if (_lastStatus == InternetConnectionStatus.connected) {
      return true;
    }
    final status = await checkInternetAccess();
    return status.isConnected;
  }

  @override
  void dispose() {
    _dataSourceSubscription?.cancel();
    _statusController.close();
    _remoteDataSource.dispose();
  }
}
