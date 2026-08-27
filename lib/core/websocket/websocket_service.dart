import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_endpoints.dart';
import 'websocket_event.dart';

abstract class WebSocketService {
  void initialize();
  void connect({String? initialChannel});
  void disconnect();
  void subscribeToChannel(String channel);
  void unsubscribeFromChannel(String channel);
  void joinMatchRoom(String matchId);
  void leaveMatchRoom(String matchId);
  void subscribeTransfers();
  void unsubscribeTransfers();
  void switchLanguageChannel(String langCode);
  Stream<SocketConnectionStatus> get statusStream;
  Stream<LiveMatchUpdate> get updatesStream;
  SocketConnectionStatus get currentStatus;
  String get activeChannel;
  void dispose();
}

class WebSocketServiceImpl implements WebSocketService {
  io.Socket? _socket;
  String _activeChannel = ApiEndpoints.wsChannelMatchesAr;
  final Set<String> _activeRooms = <String>{};
  SocketConnectionStatus _currentStatus = SocketConnectionStatus.initial;

  final StreamController<SocketConnectionStatus> _statusController =
      StreamController<SocketConnectionStatus>.broadcast();
  final StreamController<LiveMatchUpdate> _updatesController =
      StreamController<LiveMatchUpdate>.broadcast();

  @override
  SocketConnectionStatus get currentStatus => _currentStatus;

  @override
  String get activeChannel => _activeChannel;

  @override
  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<LiveMatchUpdate> get updatesStream => _updatesController.stream;

  @override
  void initialize() {
    if (_socket != null) return;

    try {
      _updateStatus(SocketConnectionStatus.connecting);

      _socket = io.io(
        ApiEndpoints.websocketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(20)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .setTimeout(15000)
            .build(),
      );

      _setupSocketListeners();
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket initialization error: $e');
      }
      _updateStatus(SocketConnectionStatus.error);
    }
  }

  void _setupSocketListeners() {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      _updateStatus(SocketConnectionStatus.connected);
      _resubscribeAll();
    });

    socket.onConnectError((data) {
      _updateStatus(SocketConnectionStatus.error);
    });

    socket.onConnectTimeout((_) {
      _updateStatus(SocketConnectionStatus.disconnected);
    });

    socket.onDisconnect((_) {
      _updateStatus(SocketConnectionStatus.disconnected);
    });

    socket.on('reconnect_attempt', (_) {
      _updateStatus(SocketConnectionStatus.reconnecting);
    });

    socket.on('reconnect', (_) {
      _updateStatus(SocketConnectionStatus.connected);
      _resubscribeAll();
    });

    // Listen to generic events and dynamic event names
    socket.onAny((event, data) {
      _handleIncomingEvent(event, data);
    });
  }

  void _handleIncomingEvent(String event, dynamic data) {
    if (data == null) return;

    try {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final update = LiveMatchUpdate.fromJson(map);
        _updatesController.add(update);
      } else if (data is List) {
        for (final item in data) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final update = LiveMatchUpdate.fromJson(map);
            _updatesController.add(update);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message ($event): $e');
      }
    }
  }

  void _resubscribeAll() {
    if (_socket?.connected == true) {
      _socket?.emit('subscribe', _activeChannel);
      _socket?.emit('join', _activeChannel);

      for (final room in _activeRooms) {
        _socket?.emit('subscribe', room);
        _socket?.emit('join', room);
      }
    }
  }

  @override
  void connect({String? initialChannel}) {
    if (initialChannel != null && initialChannel.isNotEmpty) {
      _activeChannel = initialChannel;
    }

    if (_socket == null) {
      initialize();
    }

    if (_socket?.connected != true) {
      _updateStatus(SocketConnectionStatus.connecting);
      _socket?.connect();
    }
  }

  @override
  void disconnect() {
    _socket?.disconnect();
    _updateStatus(SocketConnectionStatus.disconnected);
  }

  @override
  void subscribeToChannel(String channel) {
    _activeRooms.add(channel);
    if (_socket?.connected == true) {
      _socket?.emit('subscribe', channel);
      _socket?.emit('join', channel);
    }
  }

  @override
  void unsubscribeFromChannel(String channel) {
    _activeRooms.remove(channel);
    if (_socket?.connected == true) {
      _socket?.emit('unsubscribe', channel);
      _socket?.emit('leave', channel);
    }
  }

  @override
  void joinMatchRoom(String matchId) {
    final room = ApiEndpoints.wsMatchRoom(matchId);
    subscribeToChannel(room);
  }

  @override
  void leaveMatchRoom(String matchId) {
    final room = ApiEndpoints.wsMatchRoom(matchId);
    unsubscribeFromChannel(room);
  }

  @override
  void subscribeTransfers() {
    subscribeToChannel(ApiEndpoints.wsChannelTransfersAr);
  }

  @override
  void unsubscribeTransfers() {
    unsubscribeFromChannel(ApiEndpoints.wsChannelTransfersAr);
  }

  @override
  void switchLanguageChannel(String langCode) {
    final oldChannel = _activeChannel;
    final newChannel = langCode == 'ar'
        ? ApiEndpoints.wsChannelAr
        : ApiEndpoints.wsChannelEn;

    if (oldChannel != newChannel) {
      unsubscribeFromChannel(oldChannel);
      _activeChannel = newChannel;
      subscribeToChannel(newChannel);
    }
  }

  void _updateStatus(SocketConnectionStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _statusController.close();
    _updatesController.close();
  }
}
