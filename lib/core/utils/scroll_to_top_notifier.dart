import 'package:flutter/foundation.dart';

/// Centralized notifier to request the active tab or screen to scroll back to the top.
/// Tapping the currently selected bottom navigation bar item triggers this notification.
class AppScrollToTopNotifier {
  AppScrollToTopNotifier._();

  static final Map<int, List<VoidCallback>> _listeners = {};

  /// Register a callback to be notified when a tab index requests scrolling to top.
  static void addListener(int tabIndex, VoidCallback callback) {
    _listeners.putIfAbsent(tabIndex, () => []).add(callback);
  }

  /// Unregister a previously registered callback.
  static void removeListener(int tabIndex, VoidCallback callback) {
    _listeners[tabIndex]?.remove(callback);
    if (_listeners[tabIndex]?.isEmpty ?? false) {
      _listeners.remove(tabIndex);
    }
  }

  /// Broadcast a scroll-to-top request for the specified tab index.
  static void scrollToTop(int tabIndex) {
    final callbacks = _listeners[tabIndex];
    if (callbacks != null && callbacks.isNotEmpty) {
      for (final cb in List<VoidCallback>.of(callbacks)) {
        try {
          cb();
        } catch (_) {}
      }
    }
  }
}
