import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:score154/core/constants/api_endpoints.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';

void main() {
  group('Production 154Score WebSocket Backend Dynamic Verification', () {
    test('Direct Socket.IO connection & handshake to live production endpoint',
        () async {
      final completer = Completer<bool>();
      final errorCompleter = Completer<String>();

      final socket = io.io(
        ApiEndpoints.websocketUrl,
        io.OptionBuilder()
            .setPath('/socket.io/')
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setTimeout(12000)
            .build(),
      );

      socket.onConnect((_) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      socket.onConnectError((err) {
        if (!errorCompleter.isCompleted) {
          errorCompleter.complete(err.toString());
        }
      });

      socket.connect();

      // Wait for connection with a generous timeout for network latency
      final connected = await Future.any([
        completer.future,
        errorCompleter.future.then((e) => false),
        Future.delayed(const Duration(seconds: 15), () => false),
      ]);

      expect(
        connected,
        isTrue,
        reason:
            'Should connect to production WebSocket at ${ApiEndpoints.websocketUrl}',
      );

      // Verify subscription emit to production rooms
      socket.emit('subscribe', 'live_matches_ar');
      socket.emit('subscribe', 'transfers_ar');
      socket.emit('subscribe', 'match:5868020');

      await Future.delayed(const Duration(milliseconds: 500));

      // Verify unsubscribe emit
      socket.emit('unsubscribe', 'match:5868020');

      socket.disconnect();
      socket.dispose();
    }, timeout: const Timeout(Duration(seconds: 25)));

    test(
      'WebSocketServiceImpl manages production connection & subscriptions',
      () async {
        final service = WebSocketServiceImpl();
        service.initialize();

        expect(service.currentStatus, equals(SocketConnectionState.connecting));

        service.subscribeToChannel('live_matches_ar');
        service.subscribeTransfers();
        service.joinMatchRoom('5868020');

        final health = service.currentHealth;
        expect(health.activeSubscriptions, contains('live_matches_ar'));
        expect(health.activeSubscriptions, contains('match:5868020'));
        expect(health.activeSubscriptions, contains('transfers_ar'));

        // Test room reference counting
        service.joinMatchRoom('5868020'); // Ref count = 2
        service.leaveMatchRoom('5868020'); // Ref count = 1 -> still active
        expect(
          service.currentHealth.activeSubscriptions,
          contains('match:5868020'),
        );

        service.leaveMatchRoom('5868020'); // Ref count = 0 -> removed
        expect(
          service.currentHealth.activeSubscriptions.contains('match:5868020'),
          isFalse,
        );

        service.dispose();
      },
    );
  });
}
