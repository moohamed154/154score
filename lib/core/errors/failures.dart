import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class WebSocketFailure extends Failure {
  const WebSocketFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message, {super.statusCode = 429});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class UpstreamUnavailableFailure extends Failure {
  const UpstreamUnavailableFailure(super.message, {super.statusCode = 503});
}
