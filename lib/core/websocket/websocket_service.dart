import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_endpoints.dart';
import '../network/network_info.dart';
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

  Stream<SocketConnectionState> get statusStream;
  Stream<WebSocketConnectionHealth> get healthStream;
  Stream<LiveMatchUpdate> get liveMatchesStream;
  Stream<TransferUpdate> get transfersStream;
  Stream<MatchDetailRealtimeUpdate> matchUpdatesStream(String matchId);

  // Backward compatibility stream
  Stream<LiveMatchUpdate> get updatesStream;

  SocketConnectionState get currentStatus;
  WebSocketConnectionHealth get currentHealth;
  String get activeChannel;

  void handleAppLifecycleState(AppLifecycleState state);
  void recordRestFallback({required bool isActive, DateTime? refreshedAt});
  void dispose();
}

class WebSocketServiceImpl implements WebSocketService {
  final NetworkInfo? _networkInfo;

  io.Socket? _socket;
  String _activeChannel = ApiEndpoints.wsChannelMatchesAr;
  String _activeTransfersChannel = ApiEndpoints.wsChannelTransfersAr;

  // Subscription Registry with reference counting for match rooms
  final Map<String, int> _roomReferenceCounts = <String, int>{};
  final Set<String> _staticSubscriptions = <String>{};

  SocketConnectionState _currentStatus = SocketConnectionState.disconnected;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  DateTime? _lastConnectedAt;
  DateTime? _lastDisconnectedAt;
  String? _lastError;
  int _totalEventsReceived = 0;
  int _duplicateEventsSuppressed = 0;
  int _staleEventsSuppressed = 0;
  int _eventsIgnored = 0;
  String? _lastEventName;
  DateTime? _lastEventTimestamp;
  int? _latencyMs;
  bool _restFallbackActive = false;
  DateTime? _lastRestRefreshAt;

  StreamSubscription? _connectivitySubscription;

  // Deduplication & Ordering Cache (Bounded size 250)
  final Queue<String> _recentFingerprints = Queue<String>();
  final Set<String> _fingerprintSet = <String>{};
  final Map<String, int> _matchSequenceVersions = <String, int>{};
  static const int _maxCacheSize = 250;

  final StreamController<SocketConnectionState> _statusController =
      StreamController<SocketConnectionState>.broadcast();
  final StreamController<WebSocketConnectionHealth> _healthController =
      StreamController<WebSocketConnectionHealth>.broadcast();
  final StreamController<LiveMatchUpdate> _liveMatchesController =
      StreamController<LiveMatchUpdate>.broadcast();
  final StreamController<TransferUpdate> _transfersController =
      StreamController<TransferUpdate>.broadcast();
  final StreamController<MatchDetailRealtimeUpdate> _matchDetailsController =
      StreamController<MatchDetailRealtimeUpdate>.broadcast();

  WebSocketServiceImpl({NetworkInfo? networkInfo})
    // ignore: prefer_initializing_formals
    : _networkInfo = networkInfo {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    if (_networkInfo != null) {
      _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((
        hasConnection,
      ) {
        if (hasConnection) {
          if (_currentStatus != SocketConnectionState.connected &&
              !_isConnecting) {
            if (kDebugMode) {
              debugPrint(
                '[WS] Network connectivity restored. Checking socket connection...',
              );
            }
            connect();
          }
        } else {
          if (kDebugMode) {
            debugPrint('[WS] Network connection lost.');
          }
          _updateStatus(SocketConnectionState.disconnected);
        }
      });
    }
  }

  @override
  SocketConnectionState get currentStatus => _currentStatus;

  String get _currentTransport {
    if (_socket?.connected != true &&
        _currentStatus != SocketConnectionState.connected) {
      return 'none';
    }
    try {
      final engine = _socket?.io.engine;
      final transportName = engine?.transport?.name;
      if (transportName != null && transportName.isNotEmpty) {
        return transportName;
      }
    } catch (_) {}
    return 'websocket';
  }

  @override
  WebSocketConnectionHealth get currentHealth => WebSocketConnectionHealth(
    state: _currentStatus,
    currentTransport: _currentTransport,
    socketId: _socket?.id,
    latencyMs: _latencyMs,
    lastConnectedAt: _lastConnectedAt,
    lastDisconnectedAt: _lastDisconnectedAt,
    reconnectAttempts: _reconnectAttempts,
    lastError: _lastError,
    activeSubscriptions: Set.unmodifiable(_getAllActiveRooms()),
    totalEventsReceived: _totalEventsReceived,
    duplicateEventsSuppressed: _duplicateEventsSuppressed,
    staleEventsSuppressed: _staleEventsSuppressed,
    eventsIgnored: _eventsIgnored,
    lastEventName: _lastEventName,
    lastEventTimestamp: _lastEventTimestamp,
    restFallbackActive: _restFallbackActive,
    lastRestRefreshAt: _lastRestRefreshAt,
  );

  @override
  String get activeChannel => _activeChannel;

  @override
  Stream<SocketConnectionState> get statusStream => _statusController.stream;

  @override
  Stream<WebSocketConnectionHealth> get healthStream =>
      _healthController.stream;

  @override
  Stream<LiveMatchUpdate> get liveMatchesStream =>
      _liveMatchesController.stream;

  @override
  Stream<TransferUpdate> get transfersStream => _transfersController.stream;

  @override
  Stream<LiveMatchUpdate> get updatesStream => _liveMatchesController.stream;

  @override
  Stream<MatchDetailRealtimeUpdate> matchUpdatesStream(String matchId) {
    return _matchDetailsController.stream.where(
      (update) => update.matchId == matchId,
    );
  }

  @override
  void recordRestFallback({required bool isActive, DateTime? refreshedAt}) {
    _restFallbackActive = isActive;
    if (refreshedAt != null) {
      _lastRestRefreshAt = refreshedAt;
    }
    _emitHealth();
  }

  Set<String> _getAllActiveRooms() {
    final allRooms = <String>{_activeChannel};
    allRooms.addAll(_staticSubscriptions);
    for (final entry in _roomReferenceCounts.entries) {
      if (entry.value > 0) {
        allRooms.add(entry.key);
      }
    }
    return allRooms;
  }

  bool _isValidRoom(String room) {
    if (room.isEmpty) return false;
    if (room == ApiEndpoints.wsChannelMatchesAr ||
        room == ApiEndpoints.wsChannelEn ||
        room == ApiEndpoints.wsChannelTransfersAr ||
        room == 'transfers_en') {
      return true;
    }
    if (room.startsWith('match:')) {
      final idPart = room.substring('match:'.length);
      return idPart.isNotEmpty && RegExp(r'^[0-9a-zA-Z_-]+$').hasMatch(idPart);
    }
    return false;
  }

  @override
  void initialize() {
    if (_socket != null) return;

    try {
      _updateStatus(SocketConnectionState.connecting);

      if (kDebugMode) {
        debugPrint(
          '[WS] Initializing Socket.IO connection to ${ApiEndpoints.websocketUrl} path: /socket.io/',
        );
      }

      final startTime = DateTime.now();

      _socket = io.io(
        ApiEndpoints.websocketUrl,
        io.OptionBuilder()
            .setPath('/socket.io/')
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(15)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(30000)
            .setTimeout(15000)
            .build(),
      );

      _setupSocketListeners(startTime);
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        debugPrint('[WS] Initialization error: $e');
      }
      _updateStatus(SocketConnectionState.error);
    }
  }

  void _setupSocketListeners([DateTime? connectStartTime]) {
    final socket = _socket;
    if (socket == null) return;

    socket.clearListeners();

    socket.onConnect((_) {
      _isConnecting = false;
      _reconnectAttempts = 0;
      _lastConnectedAt = DateTime.now();
      _lastError = null;
      _updateStatus(SocketConnectionState.connected);

      if (connectStartTime != null) {
        _latencyMs = DateTime.now().difference(connectStartTime).inMilliseconds;
      }

      if (kDebugMode) {
        debugPrint(
          '[WS] Connected successfully to Socket.IO backend (transport: $_currentTransport, latency: ${_latencyMs}ms)',
        );
      }

      _resubscribeAll();
    });

    socket.onConnectError((data) {
      _isConnecting = false;
      _lastError = data?.toString() ?? 'Connection error';
      if (kDebugMode) {
        debugPrint('[WS] Connect error: $_lastError');
      }
      _updateStatus(SocketConnectionState.error);
    });

    socket.onConnectTimeout((_) {
      _isConnecting = false;
      _lastError = 'Connection timed out';
      if (kDebugMode) {
        debugPrint('[WS] Connect timeout');
      }
      _updateStatus(SocketConnectionState.disconnected);
    });

    socket.onDisconnect((_) {
      _isConnecting = false;
      _lastDisconnectedAt = DateTime.now();
      if (kDebugMode) {
        debugPrint('[WS] Disconnected');
      }
      _updateStatus(SocketConnectionState.disconnected);
    });

    socket.on('reconnect_attempt', (attempt) {
      _reconnectAttempts++;
      if (kDebugMode) {
        debugPrint('[WS] Reconnect attempt #$_reconnectAttempts');
      }
      _updateStatus(SocketConnectionState.reconnecting);
    });

    socket.on('reconnect', (_) {
      _isConnecting = false;
      _reconnectAttempts = 0;
      _lastConnectedAt = DateTime.now();
      _lastError = null;
      if (kDebugMode) {
        debugPrint(
          '[WS] Reconnected successfully. Restoring active subscriptions...',
        );
      }
      _updateStatus(SocketConnectionState.connected);
      _resubscribeAll();
    });

    socket.on('reconnect_error', (error) {
      _lastError = error?.toString();
      if (kDebugMode) {
        debugPrint('[WS] Reconnect error: $_lastError');
      }
      _updateStatus(SocketConnectionState.reconnecting);
    });

    socket.on('reconnect_failed', (_) {
      _lastError = 'Reconnect failed after maximum attempts';
      if (kDebugMode) {
        debugPrint('[WS] Reconnect failed completely');
      }
      _updateStatus(SocketConnectionState.error);
    });

    // 1. Live Matches Update Event
    socket.on('live_matches_update', (data) {
      _lastEventName = 'live_matches_update';
      _lastEventTimestamp = DateTime.now();
      _processLiveMatchesUpdate(data);
    });

    // 2. Transfers Update Event
    socket.on('transfers_update', (data) {
      _lastEventName = 'transfers_update';
      _lastEventTimestamp = DateTime.now();
      _processTransfersUpdate(data);
    });

    // 3. Match Detail Update Event
    socket.on('match_update', (data) {
      _lastEventName = 'match_update';
      _lastEventTimestamp = DateTime.now();
      _processMatchUpdate(data);
    });

    // Generic fallback handler for dynamic event formats
    socket.onAny((event, data) {
      if (event == 'live_matches_update' ||
          event == 'transfers_update' ||
          event == 'match_update') {
        return;
      }
      _handleGenericIncomingEvent(event, data);
    });
  }

  void _processLiveMatchesUpdate(dynamic data) {
    if (data == null) {
      _eventsIgnored++;
      _emitHealth();
      return;
    }
    _totalEventsReceived++;

    try {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        // Case 1: Standard API Envelope {"success": true, "data": [...]}
        if (map['data'] is List) {
          _processLiveMatchesList(map['data'] as List);
        } else if (map['matches'] is List) {
          // Case 2: Single League Group {"league_title": "...", "matches": [...]}
          final lTitle = map['league_title']?.toString() ?? map['title']?.toString();
          final lId = map['league_id']?.toString() ?? map['id']?.toString();
          for (final m in map['matches']) {
            if (m is Map) {
              _dispatchLiveMatch(
                Map<String, dynamic>.from(m),
                defaultLeagueTitle: lTitle,
                defaultLeagueId: lId,
              );
            }
          }
        } else {
          // Case 3: Direct single Match map
          _dispatchLiveMatch(map);
        }
      } else if (data is List) {
        _processLiveMatchesList(data);
      } else {
        _eventsIgnored++;
      }
    } catch (e) {
      _eventsIgnored++;
      if (kDebugMode) {
        debugPrint('[WS] Error processing live_matches_update: $e');
      }
    }
    _emitHealth();
  }

  void _processLiveMatchesList(List list) {
    for (final item in list) {
      if (item is Map) {
        final itemMap = Map<String, dynamic>.from(item);
        if (itemMap['matches'] is List) {
          // League Group item
          final lTitle = itemMap['league_title']?.toString() ?? itemMap['title']?.toString();
          final lId = itemMap['league_id']?.toString() ?? itemMap['id']?.toString();
          for (final m in itemMap['matches']) {
            if (m is Map) {
              _dispatchLiveMatch(
                Map<String, dynamic>.from(m),
                defaultLeagueTitle: lTitle,
                defaultLeagueId: lId,
              );
            }
          }
        } else {
          // Direct Match item
          _dispatchLiveMatch(itemMap);
        }
      } else {
        _eventsIgnored++;
      }
    }
  }

  void _dispatchLiveMatch(
    Map<String, dynamic> map, {
    String? defaultLeagueTitle,
    String? defaultLeagueId,
  }) {
    final update = LiveMatchUpdate.fromJson(
      map,
      defaultLeagueTitle: defaultLeagueTitle,
      defaultLeagueId: defaultLeagueId,
    );

    // Duplicate event protection
    final fp = update.fingerprint;
    if (_isDuplicateEvent(fp)) {
      _duplicateEventsSuppressed++;
      return;
    }

    // Out-of-order sequence/timestamp check
    if (update.matchId != null && update.timestamp != null) {
      final lastTime = _matchSequenceVersions[update.matchId!];
      if (lastTime != null && update.timestamp! < lastTime) {
        _staleEventsSuppressed++;
        if (kDebugMode) {
          debugPrint(
            '[WS] Out-of-order update ignored for match ${update.matchId}',
          );
        }
        return;
      }
      _matchSequenceVersions[update.matchId!] = update.timestamp!;
    }

    if (!_liveMatchesController.isClosed) {
      _liveMatchesController.add(update);
    }
  }

  void _processTransfersUpdate(dynamic data) {
    if (data == null) {
      _eventsIgnored++;
      _emitHealth();
      return;
    }
    _totalEventsReceived++;

    try {
      if (data is Map) {
        _dispatchTransfer(Map<String, dynamic>.from(data));
      } else if (data is List) {
        for (final item in data) {
          if (item is Map) {
            _dispatchTransfer(Map<String, dynamic>.from(item));
          } else {
            _eventsIgnored++;
          }
        }
      } else {
        _eventsIgnored++;
      }
    } catch (e) {
      _eventsIgnored++;
      if (kDebugMode) {
        debugPrint('[WS] Error processing transfers_update: $e');
      }
    }
    _emitHealth();
  }

  void _dispatchTransfer(Map<String, dynamic> map) {
    final update = TransferUpdate.fromJson(map);

    final fp = update.fingerprint;
    if (_isDuplicateEvent(fp)) {
      _duplicateEventsSuppressed++;
      return;
    }

    if (!_transfersController.isClosed) {
      _transfersController.add(update);
    }
  }

  void _processMatchUpdate(dynamic data) {
    if (data == null) {
      _eventsIgnored++;
      _emitHealth();
      return;
    }
    _totalEventsReceived++;

    try {
      if (data is Map) {
        final update = MatchDetailRealtimeUpdate.fromJson(
          Map<String, dynamic>.from(data),
        );
        if (update.matchId.isEmpty) {
          _eventsIgnored++;
          return;
        }

        final fp = update.eventFingerprint;
        if (_isDuplicateEvent(fp)) {
          _duplicateEventsSuppressed++;
          return;
        }

        if (!_matchDetailsController.isClosed) {
          _matchDetailsController.add(update);
        }
      } else {
        _eventsIgnored++;
      }
    } catch (e) {
      _eventsIgnored++;
      if (kDebugMode) {
        debugPrint('[WS] Error processing match_update: $e');
      }
    }
    _emitHealth();
  }

  void _handleGenericIncomingEvent(String event, dynamic data) {
    if (data == null) return;

    try {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map.containsKey('score_1') ||
            map.containsKey('home_score') ||
            map.containsKey('team_1')) {
          _totalEventsReceived++;
          _dispatchLiveMatch(map);
        } else if (map.containsKey('player_name') &&
            (map.containsKey('to_team_name') || map.containsKey('fee'))) {
          _totalEventsReceived++;
          _dispatchTransfer(map);
        }
      }
    } catch (_) {}
    _emitHealth();
  }

  bool _isDuplicateEvent(String fingerprint) {
    if (fingerprint.isEmpty) return false;
    if (_fingerprintSet.contains(fingerprint)) {
      return true;
    }

    _fingerprintSet.add(fingerprint);
    _recentFingerprints.addLast(fingerprint);

    if (_recentFingerprints.length > _maxCacheSize) {
      final oldest = _recentFingerprints.removeFirst();
      _fingerprintSet.remove(oldest);
    }
    return false;
  }

  void _resubscribeAll() {
    final socket = _socket;
    if (socket == null || socket.connected != true) return;

    final allRooms = _getAllActiveRooms();
    for (final room in allRooms) {
      if (_isValidRoom(room)) {
        if (kDebugMode) {
          debugPrint('[WS] Emitting subscribe for room: $room');
        }
        socket.emit('subscribe', room);
      }
    }
  }

  @override
  void connect({String? initialChannel}) {
    if (initialChannel != null && initialChannel.isNotEmpty) {
      if (_isValidRoom(initialChannel)) {
        _activeChannel = initialChannel;
      }
    }

    if (_socket == null) {
      initialize();
    }

    if (_socket?.connected != true && !_isConnecting) {
      _isConnecting = true;
      _updateStatus(SocketConnectionState.connecting);
      try {
        _socket?.connect();
      } catch (e) {
        _isConnecting = false;
        _lastError = e.toString();
        _updateStatus(SocketConnectionState.error);
      }
    }
  }

  @override
  void disconnect() {
    _isConnecting = false;
    try {
      _socket?.disconnect();
    } catch (_) {}
    _updateStatus(SocketConnectionState.disconnected);
  }

  @override
  void subscribeToChannel(String channel) {
    if (!_isValidRoom(channel)) {
      if (kDebugMode) {
        debugPrint('[WS] Rejected invalid room name: $channel');
      }
      return;
    }

    _staticSubscriptions.add(channel);
    if (_socket?.connected == true) {
      if (kDebugMode) {
        debugPrint('[WS] Subscribing to channel: $channel');
      }
      _socket?.emit('subscribe', channel);
    }
    _emitHealth();
  }

  @override
  void unsubscribeFromChannel(String channel) {
    _staticSubscriptions.remove(channel);
    if (_socket?.connected == true) {
      if (kDebugMode) {
        debugPrint('[WS] Unsubscribing from channel: $channel');
      }
      _socket?.emit('unsubscribe', channel);
    }
    _emitHealth();
  }

  @override
  void joinMatchRoom(String matchId) {
    final room = ApiEndpoints.wsMatchRoom(matchId);
    if (!_isValidRoom(room)) {
      if (kDebugMode) {
        debugPrint('[WS] Rejected invalid match room: $room');
      }
      return;
    }

    final count = _roomReferenceCounts[room] ?? 0;
    _roomReferenceCounts[room] = count + 1;

    // Only emit subscription on the first reference
    if (count == 0 && _socket?.connected == true) {
      if (kDebugMode) {
        debugPrint('[WS] Joining room: $room (ref count: 1)');
      }
      _socket?.emit('subscribe', room);
    }
    _emitHealth();
  }

  @override
  void leaveMatchRoom(String matchId) {
    final room = ApiEndpoints.wsMatchRoom(matchId);
    final count = _roomReferenceCounts[room] ?? 0;

    if (count <= 1) {
      _roomReferenceCounts.remove(room);
      if (_socket?.connected == true) {
        if (kDebugMode) {
          debugPrint('[WS] Leaving room: $room (ref count: 0)');
        }
        _socket?.emit('unsubscribe', room);
      }
    } else {
      _roomReferenceCounts[room] = count - 1;
      if (kDebugMode) {
        debugPrint('[WS] Decremented room $room ref count to ${count - 1}');
      }
    }
    _emitHealth();
  }

  @override
  void subscribeTransfers() {
    subscribeToChannel(_activeTransfersChannel);
  }

  @override
  void unsubscribeTransfers() {
    unsubscribeFromChannel(_activeTransfersChannel);
  }

  @override
  void switchLanguageChannel(String langCode) {
    final oldMatchChannel = _activeChannel;
    final newMatchChannel = langCode == 'ar'
        ? ApiEndpoints.wsChannelMatchesAr
        : ApiEndpoints.wsChannelEn;

    final oldTransfersChannel = _activeTransfersChannel;
    final newTransfersChannel = langCode == 'ar'
        ? ApiEndpoints.wsChannelTransfersAr
        : 'transfers_en';

    if (oldMatchChannel != newMatchChannel) {
      unsubscribeFromChannel(oldMatchChannel);
      _activeChannel = newMatchChannel;
      subscribeToChannel(newMatchChannel);
    }

    if (oldTransfersChannel != newTransfersChannel) {
      if (_staticSubscriptions.contains(oldTransfersChannel)) {
        unsubscribeFromChannel(oldTransfersChannel);
        _activeTransfersChannel = newTransfersChannel;
        subscribeToChannel(newTransfersChannel);
      } else {
        _activeTransfersChannel = newTransfersChannel;
      }
    }
  }

  @override
  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_socket?.connected != true) {
          if (kDebugMode) {
            debugPrint(
              '[WS] App resumed: verifying connection and reconnecting...',
            );
          }
          connect();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Do not destroy the socket instance to prevent reconnect thrashing
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _updateStatus(SocketConnectionState status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    _emitHealth();
  }

  void _emitHealth() {
    if (!_healthController.isClosed) {
      _healthController.add(currentHealth);
    }
  }

  @override
  void dispose() {
    _isConnecting = false;
    _connectivitySubscription?.cancel();
    try {
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _statusController.close();
    _healthController.close();
    _liveMatchesController.close();
    _transfersController.close();
    _matchDetailsController.close();
  }
}
