# 154Score - WebSocket & Real-Time Documentation

## WebSocket URL
```text
https://moohamed154-154score-api.hf.space
```
- Protocol: **Socket.IO (Engine.IO v4)** with WebSocket and HTTP polling fallback.

---

## Channels & Room Subscription

| Channel | Description |
| :--- | :--- |
| `live_matches_ar` | Arabic live matches stream (scores, minutes, goals, cards) |
| `live_matches_en` | English live matches stream |

When the user switches application language, `WebSocketService` dynamically unsubscribes from the previous channel and subscribes to the new one:

```dart
_webSocketService.switchLanguageChannel(langCode);
```

---

## Connection Lifecycle & Reconnection
- **Auto Reconnect**: Configured with 20 reconnection attempts with exponential backoff (2s to 10s).
- **Status Stream**: Exposes `Stream<SocketConnectionStatus>` (`initial`, `connecting`, `connected`, `disconnected`, `reconnecting`, `error`).
- **Reactive UI updates**: Match cards update without full page reloads. Score changes trigger `AnimatedScoreText` animations.
