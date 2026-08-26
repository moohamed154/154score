class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class WebSocketException implements Exception {
  final String message;

  const WebSocketException(this.message);

  @override
  String toString() => 'WebSocketException: $message';
}

class ParsingException implements Exception {
  final String message;

  const ParsingException(this.message);

  @override
  String toString() => 'ParsingException: $message';
}
