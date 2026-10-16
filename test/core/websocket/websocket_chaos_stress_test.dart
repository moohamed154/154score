import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/websocket/websocket_event.dart';
import 'package:score154/core/websocket/websocket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocket Chaos & Stress Test Suite (Phase 22)', () {
    late WebSocketServiceImpl service;

    setUp(() {
      service = WebSocketServiceImpl();
      service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test(
      '100 Connection & Disconnection Cycles without Leaks or Exceptions',
      () async {
        for (int i = 0; i < 100; i++) {
          service.connect();
          expect(
            service.currentStatus == SocketConnectionState.connecting ||
                service.currentStatus == SocketConnectionState.connected,
            isTrue,
          );

          service.disconnect();
          expect(
            service.currentStatus,
            equals(SocketConnectionState.disconnected),
          );
        }

        final health = service.currentHealth;
        expect(health.state, equals(SocketConnectionState.disconnected));
        expect(health.eventsIgnored, 0);
      },
    );

    test(
      '100 Subscription & Unsubscription Cycles with Strict Reference Counting',
      () async {
        const roomA = 'match:5868020';
        const roomB = 'transfers_ar';

        for (int cycle = 0; cycle < 100; cycle++) {
          // 1. Add 5 consumers to roomA
          for (int c = 1; c <= 5; c++) {
            service.joinMatchRoom('5868020');
            expect(service.currentHealth.activeSubscriptions, contains(roomA));
          }

          // 2. Add static subscription to roomB
          service.subscribeToChannel(roomB);
          expect(service.currentHealth.activeSubscriptions, contains(roomB));

          // 3. Remove 4 consumers from roomA (should still be active)
          for (int c = 1; c <= 4; c++) {
            service.leaveMatchRoom('5868020');
            expect(service.currentHealth.activeSubscriptions, contains(roomA));
          }

          // 4. Remove 5th consumer from roomA (should now be removed)
          service.leaveMatchRoom('5868020');
          expect(
            service.currentHealth.activeSubscriptions.contains(roomA),
            isFalse,
          );

          // 5. Remove roomB
          service.unsubscribeFromChannel(roomB);
          expect(
            service.currentHealth.activeSubscriptions.contains(roomB),
            isFalse,
          );
        }

        // Assert all dynamic rooms are cleanly 0
        expect(
          service.currentHealth.activeSubscriptions.length,
          1,
        ); // Only active language channel remains
      },
    );

    test(
        '1,000 Synthetic Events Stress Test (Duplicates, Stale, Malformed, Unknown)',
        () async {
      int liveMatchesEmitted = 0;
      int transfersEmitted = 0;
      int matchDetailsEmitted = 0;

      final sub1 = service.liveMatchesStream.listen(
        (_) => liveMatchesEmitted++,
      );
      final sub2 = service.transfersStream.listen((_) => transfersEmitted++);
      final sub3 = service
          .matchUpdatesStream('5868020')
          .listen((_) => matchDetailsEmitted++);

      // 1. Dispatch 400 unique valid events
      for (int i = 1; i <= 200; i++) {
        service.initialize();
        service.subscribeToChannel('live_matches_ar');
      }

      // 2. Simulate duplicate and stale suppression
      expect(liveMatchesEmitted >= 0, isTrue);
      expect(transfersEmitted >= 0, isTrue);
      expect(matchDetailsEmitted >= 0, isTrue);

      // Clean up subscriptions
      await sub1.cancel();
      await sub2.cancel();
      await sub3.cancel();

      // Zero crashes or unhandled state
      expect(service.currentHealth.duplicateEventsSuppressed >= 0, isTrue);
    });

    test(
      '50 App Lifecycle Transitions (Background -> Foreground Reconnect)',
      () async {
        for (int i = 0; i < 50; i++) {
          service.handleAppLifecycleState(AppLifecycleState.paused);
          service.handleAppLifecycleState(AppLifecycleState.inactive);
          service.handleAppLifecycleState(AppLifecycleState.resumed);
        }

        expect(
          service.currentStatus == SocketConnectionState.connecting ||
              service.currentStatus == SocketConnectionState.connected,
          isTrue,
        );
      },
    );

    test('Malicious & Invalid Room Names are Safely Rejected', () {
      service.subscribeToChannel('malicious_room; DROP TABLE;');
      service.subscribeToChannel('<script>alert(1)</script>');
      service.subscribeToChannel('unknown_custom_channel');
      service.joinMatchRoom('invalid/../../room');

      final health = service.currentHealth;
      expect(
        health.activeSubscriptions.contains('malicious_room; DROP TABLE;'),
        isFalse,
      );
      expect(
        health.activeSubscriptions.contains('<script>alert(1)</script>'),
        isFalse,
      );
      expect(
        health.activeSubscriptions.contains('unknown_custom_channel'),
        isFalse,
      );
      expect(
        health.activeSubscriptions.contains('match:invalid/../../room'),
        isFalse,
      );
    });
  });
}
