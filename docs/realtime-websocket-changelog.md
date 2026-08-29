# 154Score Real-Time WebSocket Integration & Hardening Changelog

### lib/core/websocket/websocket_event.dart
- **OLD**: Simple `LiveMatchUpdate` model and basic `SocketConnectionState` enum.
- **NEW**: Hardened `LiveMatchUpdate`, `TransferUpdate`, `MatchDetailRealtimeUpdate`, and `WebSocketConnectionHealth` models with deterministic composite fingerprinting, timestamp/sequence version fields, transport identifier, latency tracking, and REST fallback telemetry.
- **REASON**: Comprehensive event typing, out-of-order rejection, duplicate suppression, and rich observability.
- **TEST**: `test/core/websocket/websocket_unit_tests.dart` PASS.

---

### lib/core/websocket/websocket_service.dart
- **OLD**: Basic Socket.IO service.
- **NEW**: Hardened `WebSocketServiceImpl` with:
  - Network connectivity integration (`NetworkInfo`)
  - Exponential backoff (1s-30s)
  - Reference-counted room registry with malicious string validation
  - LRU deduplication cache (size 250)
  - Sequence and timestamp ordering checks
  - Active transport & latency telemetry
  - App lifecycle awareness
- **REASON**: High-reliability single-socket real-time core with zero leaks.
- **TEST**: `test/core/websocket/production_websocket_test.dart` & `test/core/websocket/websocket_chaos_stress_test.dart` PASS.

---

### lib/core/utils/realtime_merge_engine.dart
- **OLD**: Ad-hoc match updates.
- **NEW**: Pure-function merge engine for matches, match events, and transfers.
- **REASON**: Preserves all untouched REST snapshot fields, re-sorts matches safely, and prevents NaN or null string coercion.
- **TEST**: `test/core/websocket/websocket_unit_tests.dart` PASS.

---

### lib/features/matches/presentation/bloc/matches_bloc.dart & matches_event.dart
- **OLD**: Uncontrolled polling and simple socket listening.
- **NEW**: Integrated with `RealtimeMergeEngine`, listens to `statusStream` to start fallback polling on disconnect, stops polling on reconnect, and triggers a healing REST refresh upon reconnecting.
- **REASON**: Guarantees fresh match state without redundant REST calls when WebSocket is healthy.
- **TEST**: `test/features/matches/matches_bloc_test.dart` PASS.

---

### lib/features/match_details/presentation/bloc/match_details_bloc.dart & match_details_event.dart
- **OLD**: Listened to generic stream without room lifecycle safety.
- **NEW**: Manages room `match:{matchId}` with reference counting, listens to `matchUpdatesStream(matchId)`, merges events via `RealtimeMergeEngine`, and cleans up on close.
- **REASON**: Real-time match-specific goals, cards, and status delivered with zero room leaks.
- **TEST**: `test/features/match_details/match_events_real_api_test.dart` PASS.

---

### lib/features/transfers/presentation/bloc/transfers_bloc.dart
- **OLD**: REST only.
- **NEW**: Subscribes to `transfers_ar`/`transfers_en`, receives `TransferSocketUpdateEvent`, and merges with deduplication.
- **REASON**: Real-time transfer updates on the Transfers screen.
- **TEST**: `test/core/websocket/websocket_unit_tests.dart` PASS.

---

### lib/core/di/injection_container.dart
- **OLD**: `WebSocketService` initialized without `NetworkInfo`, and `TransfersBloc` initialized without `WebSocketService`.
- **NEW**: `NetworkInfo` passed to `WebSocketService` singleton; `WebSocketService` injected into `TransfersBloc`.
- **REASON**: Seamless dependency injection across network and feature layers.
- **TEST**: Full app compilation and test pass.

---

### lib/features/settings/presentation/widgets/diagnostics_sheet.dart
- **OLD**: Static connection text.
- **NEW**: Live `StreamBuilder` rendering transport (`websocket`/`polling`), latency, active rooms, total events, duplicates suppressed, stale events ignored, and REST fallback status.
- **REASON**: Real-time observability and diagnostic visibility.
- **TEST**: `flutter analyze` PASS.

---

### lib/app/app.dart
- **OLD**: `StatelessWidget` without lifecycle observer.
- **NEW**: `StatefulWidget` with `WidgetsBindingObserver` routing lifecycle changes to `WebSocketService`.
- **REASON**: Automatic reconnection upon app resume.
- **TEST**: `test/core/websocket/websocket_chaos_stress_test.dart` PASS.
