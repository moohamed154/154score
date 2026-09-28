class ConfigurationException implements Exception {
  final String message;

  const ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  const ServerException(this.message, {this.statusCode, this.requestId});

  @override
  String toString() =>
      'ServerException: $message (status: $statusCode, requestId: $requestId)';
}

class ApiAuthenticationException extends ServerException {
  final String? _code;

  ApiAuthenticationException(
    super.message, {
    String? code,
    super.requestId,
    super.statusCode,
  }) : _code = code ?? _inferCodeFromMessage(message);

  String? get code => _code;

  static String? _inferCodeFromMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('INVALID_API_KEY')) return 'INVALID_API_KEY';
    if (trimmed.contains('API_KEY_REVOKED')) return 'API_KEY_REVOKED';
    if (trimmed.contains('API_KEY_EXPIRED')) return 'API_KEY_EXPIRED';
    if (trimmed.contains('ADMIN_AUTH_REQUIRED')) return 'ADMIN_AUTH_REQUIRED';
    if (trimmed.contains('AUTH_REQUIRED')) return 'AUTH_REQUIRED';
    return trimmed;
  }

  @override
  String toString() =>
      'ApiAuthenticationException: $message (code: $code, status: $statusCode, requestId: $requestId)';
}

class ForbiddenException extends ServerException {
  const ForbiddenException(
    super.message, {
    super.requestId,
    super.statusCode = 403,
  });
}

class RateLimitException extends ServerException {
  final Duration? retryAfter;

  const RateLimitException(
    super.message, {
    super.requestId,
    super.statusCode = 429,
    this.retryAfter,
  });
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  final String? requestId;

  const NetworkException(this.message, {this.requestId});

  @override
  String toString() => 'NetworkException: $message (requestId: $requestId)';
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
