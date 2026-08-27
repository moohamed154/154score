import '../errors/failures.dart';

sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(data: final d) => d,
    _ => null,
  };

  Failure? get failureOrNull => switch (this) {
    ApiFailure<T>(failure: final f) => f,
    _ => null,
  };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      ApiSuccess<T>(data: final d) => onSuccess(d),
      ApiFailure<T>(failure: final f) => onFailure(f),
    };
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);

  @override
  String toString() => 'ApiSuccess($data)';
}

class ApiFailure<T> extends ApiResult<T> {
  final Failure failure;
  const ApiFailure(this.failure);

  @override
  String toString() => 'ApiFailure($failure)';
}
