import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/internet_connection/domain/repositories/internet_connection_repository.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final InternetConnectionRepository? _internetConnectionRepository;

  NetworkInfoImpl(
    this._connectivity, {
    InternetConnectionRepository? internetConnectionRepository,
  }) : _internetConnectionRepository = internetConnectionRepository;

  @override
  Future<bool> get isConnected async {
    if (_internetConnectionRepository != null) {
      return await _internetConnectionRepository.isConnected;
    }
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    if (_internetConnectionRepository != null) {
      return _internetConnectionRepository.onStatusChanged
          .map((status) => status.isConnected);
    }
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
