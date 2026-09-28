import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/config/app_config.dart';
import 'package:score154/core/errors/exceptions.dart';
import 'package:score154/core/errors/failures.dart';
import 'package:score154/core/network/api_client.dart';
import 'package:score154/core/network/api_result.dart';

void main() {
  group('ApiResult Tests', () {
    test('ApiSuccess holds data correctly and isSuccess is true', () {
      const result = ApiSuccess<String>('hello');
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 'hello');
      expect(result.failureOrNull, isNull);

      final folded = result.fold(
        onSuccess: (data) => 'success: $data',
        onFailure: (fail) => 'fail: ${fail.message}',
      );
      expect(folded, 'success: hello');
    });

    test('ApiFailure holds failure correctly and isFailure is true', () {
      const failure = ServerFailure('Server not reachable', statusCode: 500);
      const result = ApiFailure<String>(failure);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, failure);

      final folded = result.fold(
        onSuccess: (data) => 'success: $data',
        onFailure: (fail) => 'fail: ${fail.message}',
      );
      expect(folded, 'fail: Server not reachable');
    });
  });

  group('ApiClient auth config', () {
    test('missing API key throws a clear configuration error', () {
      expect(
        () => AppConfig.validateApiKey(''),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('request id stays attached to a mapped authentication error', () {
      final exception = ApiAuthenticationException(
        'INVALID_API_KEY',
        statusCode: 401,
        requestId: 'req_123',
      );

      expect(exception.code, 'INVALID_API_KEY');
      expect(exception.requestId, 'req_123');
      expect(exception.statusCode, 401);
    });
  });
}
