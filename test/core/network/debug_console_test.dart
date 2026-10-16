import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/network/debug_console.dart';

void main() {
  setUp(() {
    DebugConsole.clear();
    DebugConsole.enabled = true;
    DebugConsole.autoPrintResponses = false;
    DebugConsole.autoPrintRequests = false;
    DebugConsole.autoPrintErrors = false;
  });

  group('DebugNetworkRecord Tests', () {
    test('formats JSON Map body with pretty indentation', () {
      final record = DebugNetworkRecord(
        id: '1',
        method: 'GET',
        url: 'https://api.example.com/matches',
        statusCode: 200,
        responseData: {'status': 'ok', 'count': 5},
        requestedAt: DateTime(2026, 9, 9, 21, 0, 0),
        duration: const Duration(milliseconds: 150),
      );

      expect(record.formattedResponseString, contains('"status": "ok"'));
      expect(record.formattedResponseString, contains('"count": 5'));
      expect(record.summaryLine, contains('[GET] [200] (150ms)'));
    });

    test('formats String JSON body properly', () {
      final record = DebugNetworkRecord(
        id: '2',
        method: 'POST',
        url: 'https://api.example.com/submit',
        statusCode: 201,
        responseData: '{"success": true}',
        requestedAt: DateTime(2026, 9, 9, 21, 0, 0),
      );

      expect(record.formattedResponseString, contains('"success": true'));
    });

    test('formats null body gracefully', () {
      final record = DebugNetworkRecord(
        id: '3',
        method: 'GET',
        url: 'https://api.example.com/empty',
        requestedAt: DateTime(2026, 1, 1),
      );

      expect(record.formattedResponseString, '(empty response)');
    });
  });

  group('DebugConsole Tests', () {
    test('logResponse stores record in history and updates changeNotifier', () {
      int notified = 0;
      DebugConsole.changeNotifier.addListener(() => notified++);

      final reqOptions = RequestOptions(
        path: '/matches',
        baseUrl: 'https://api.example.com',
        method: 'GET',
        queryParameters: {'date': '2026-09-09'},
        headers: {'Accept': 'application/json'},
      );

      final response = Response(
        requestOptions: reqOptions,
        statusCode: 200,
        statusMessage: 'OK',
        data: {'data': []},
      );

      final record = DebugConsole.logResponse(
        response,
        duration: const Duration(milliseconds: 200),
      );

      expect(DebugConsole.history.length, 1);
      expect(
        DebugConsole.history.first.url,
        'https://api.example.com/matches?date=2026-09-09',
      );
      expect(DebugConsole.history.first.statusCode, 200);
      expect(DebugConsole.history.first.duration?.inMilliseconds, 200);
      expect(notified, 1);
      expect(record?.method, 'GET');
    });

    test('logError stores error in history', () {
      final reqOptions = RequestOptions(
        path: '/missing',
        baseUrl: 'https://api.example.com',
        method: 'GET',
      );

      final dioError = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.badResponse,
        message: 'Resource not found',
        response: Response(
          requestOptions: reqOptions,
          statusCode: 404,
          data: {'error': 'not found'},
        ),
      );

      final record = DebugConsole.logError(
        dioError,
        duration: const Duration(milliseconds: 120),
      );

      expect(DebugConsole.history.length, 1);
      expect(record?.isError, isTrue);
      expect(record?.statusCode, 404);
      expect(record?.errorMessage, 'Resource not found');
    });

    test('maxHistorySize trims oldest records', () {
      final oldSize = DebugConsole.maxHistorySize;
      DebugConsole.maxHistorySize = 3;

      for (int i = 1; i <= 5; i++) {
        final reqOptions = RequestOptions(
          path: '/item/$i',
          baseUrl: 'https://api.example.com',
        );
        DebugConsole.logResponse(
          Response(requestOptions: reqOptions, statusCode: 200, data: i),
        );
      }

      expect(DebugConsole.history.length, 3);
      // Newest first: 5, 4, 3
      expect(DebugConsole.history[0].url, contains('/item/5'));
      expect(DebugConsole.history[1].url, contains('/item/4'));
      expect(DebugConsole.history[2].url, contains('/item/3'));

      DebugConsole.maxHistorySize = oldSize;
    });

    test(
        'printLatestResponse, printAllResponses, and printRecord run without throwing',
        () {
      // Empty calls
      expect(() => DebugConsole.printLatestResponse(), returnsNormally);
      expect(() => DebugConsole.printAllResponses(), returnsNormally);

      // Add records
      final reqOptions = RequestOptions(
        path: '/matches',
        baseUrl: 'https://api.example.com',
      );
      DebugConsole.logResponse(
        Response(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {
            'teams': ['A', 'B'],
          },
        ),
      );

      expect(() => DebugConsole.printLatestResponse(), returnsNormally);
      expect(() => DebugConsole.printAllResponses(), returnsNormally);
      expect(
        () => DebugConsole.printRecord(DebugConsole.history.first),
        returnsNormally,
      );
    });

    test('clear empties history and triggers listener', () {
      int notified = 0;
      DebugConsole.changeNotifier.addListener(() => notified++);

      final reqOptions = RequestOptions(path: '/test');
      DebugConsole.logResponse(Response(requestOptions: reqOptions));
      expect(DebugConsole.history.length, 1);

      DebugConsole.clear();
      expect(DebugConsole.history.isEmpty, isTrue);
      expect(notified, 2); // 1 for logResponse, 1 for clear
    });
  });

  group('DebugConsoleInterceptor Tests', () {
    test(
      'interceptor captures requests and logs responses to DebugConsole',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter((options) async {
          return ResponseBody.fromString(
            '{"success": true, "message": "mocked"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
        dio.interceptors.add(DebugConsoleInterceptor());

        final response = await dio.get('https://fake.url/api/test');
        expect(response.statusCode, 200);

        expect(DebugConsole.history.length, 1);
        final record = DebugConsole.history.first;
        expect(record.url, 'https://fake.url/api/test');
        expect(record.statusCode, 200);
        expect(record.duration, isNotNull);
      },
    );

    test('interceptor captures errors and logs them to DebugConsole', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString(
          '{"error": "not found"}',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      dio.interceptors.add(DebugConsoleInterceptor());

      try {
        await dio.get('https://fake.url/api/error');
      } catch (_) {}

      expect(DebugConsole.history.length, 1);
      final record = DebugConsole.history.first;
      expect(record.isError, isTrue);
      expect(record.statusCode, 404);
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) _handler;
  _MockAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    dynamic requestStream,
    dynamic cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
