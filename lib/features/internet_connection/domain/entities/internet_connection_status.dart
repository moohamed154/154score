enum InternetConnectionStatus {
  connected,
  disconnected,
  checking;

  bool get isConnected => this == InternetConnectionStatus.connected;
  bool get isDisconnected => this == InternetConnectionStatus.disconnected;
  bool get isChecking => this == InternetConnectionStatus.checking;
}
