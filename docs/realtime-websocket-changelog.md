# 154Score Real-Time WebSocket Integration Changelog

### lib/core/websocket/websocket_event.dart
- **OLD**: Simple `LiveMatchUpdate` model and basic `SocketConnectionState` enum.
- **NEW**: Strongly typed `LiveMatchUpdate`, `TransferUpdate`, `MatchDetailRealtimeUpdate`, and `WebSocketConnectionHealth` models with deterministic fingerprinting and timestamp/version fields.
- **REASON**: Support multi-room domain event parsing, duplicate protection, and connection observability.
- **TEST**: `test/core/websocket/websocket_unit_tests.dart` PASS.

---

### lib/core/websocket/websocket_service.dart
- **OLD**: Minimal Socket.IO service without reference counted rooms or health tracking.
- **NEW**: Centralized production-grade Socket.IO service with exponential backoff (1s-30s), subscription registry with room reference counting, deduplication caching (size 250), out-of-order sequence protection, event routers, and app lifecycle handlers.
- **REASON**: Ensure robust real-time communication without memory leaks, duplicate connections, or dropped subscriptions on reconnect.
- **TEST**: `test/core/websocket/production_websocket_test.dart` PASS.

---

### lib/core/utils/realtime_merge_engine.dart
- **OLD**: Ad-hoc match list copying and manual mapping in BLoC.
- **NEW**: Dedicated `RealtimeMergeEngine` with `mergeMatchesWithRealtime`, `mergeMatchDetailsEvents`, and `mergeTransfersWithRealtime`.
- **REASON**: Reusable, pure-function data merging preserving unchanged fields, preventing null coercion/NaN, and re-sorting live matches cleanly.
- **TEST**: `test/core/websocket/websocket_unit_tests.dart` PASS.

---

### lib/features/matches/presentation/bloc/matches_bloc.dart & matches_event.dart
- **OLD**: Basic event listening without connection-state awareness or fallback polling.
- **NEW**: Integrated with `RealtimeMergeEngine`, listens to `statusStream` to start fallback polling on disconnect, and cancels polling on reconnect.
- **REASON**: Maintain fresh match data regardless of WebSocket health without hammering server when WebSocket is active.
- **TEST**: `test/features/matches/matches_bloc_test.dart` PASS.

---

### lib/features/match_details/presentation/bloc/match_details_bloc.dart & match_details_event.dart
- **OLD**: Listened only to generic `updatesStream`.
- **NEW**: Listens to dedicated `matchUpdatesStream(matchId)`, handles `MatchDetailSocketUpdateEvent`, and leaves `match:{id}` room cleanly on `close()`.
- **REASON**: Low-latency match events, cards, and goals delivered only to active viewers.
- **TEST**: `test/features/match_details/match_events_real_api_test.dart` PASS.

---

### lib/features/transfers/presentation/bloc/transfers_bloc.dart
- **OLD**: REST only.
- **NEW**: Subscribes to `transfers_ar`/`transfers_en`, receives `TransferSocketUpdateEvent`, and merges with deduplication.
- **REASON**: Real-time transfer updates on the Transfers screen.
- **TEST**: `test/core/websocket/websocket_unit_tests.dart` PASS.

---

### lib/core/di/injection_container.dart
- **OLD**: `TransfersBloc` initialized without `WebSocketService`.
- **NEW**: `WebSocketService` injected into `TransfersBloc`.
- **REASON**: Connect Transfers feature to real-time events.
- **TEST**: Verified via app compilation and DI tests.

---

### lib/features/settings/presentation/widgets/diagnostics_sheet.dart
- **OLD**: Rendered static connection string.
- **NEW**: Live `StreamBuilder` rendering active rooms, real-time connection status, and event counters.
- **REASON**: Observability and diagnostic visibility.
- **TEST**: `flutter analyze` PASS.

---

### lib/app/app.dart
- **OLD**: `StatelessWidget` without lifecycle observer.
- **NEW**: `StatefulWidget` with `WidgetsBindingObserver` routing lifecycle changes to `WebSocketService`.
- **REASON**: Automatic reconnection upon app resume.
- **TEST**: Full test suite PASS.
