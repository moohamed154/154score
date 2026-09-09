import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Represents a recorded network request and response pair.
class DebugNetworkRecord {
  final String id;
  final String method;
  final String url;
  final Map<String, dynamic>? queryParameters;
  final Map<String, dynamic>? headers;
  final dynamic requestData;
  final int? statusCode;
  final String? statusMessage;
  final dynamic responseData;
  final String? errorMessage;
  final DateTime requestedAt;
  final Duration? duration;
  final bool isError;

  const DebugNetworkRecord({
    required this.id,
    required this.method,
    required this.url,
    this.queryParameters,
    this.headers,
    this.requestData,
    this.statusCode,
    this.statusMessage,
    this.responseData,
    this.errorMessage,
    required this.requestedAt,
    this.duration,
    this.isError = false,
  });

  /// Pretty formats the response body or data.
  String get formattedResponseString {
    if (responseData == null) {
      if (errorMessage != null) return 'Error: $errorMessage';
      return '(empty response)';
    }

    try {
      if (responseData is Map || responseData is List) {
        return const JsonEncoder.withIndent('  ').convert(responseData);
      }
      if (responseData is String) {
        // Attempt to parse JSON string if possible
        try {
          final decoded = json.decode(responseData as String);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return responseData as String;
        }
      }
      return responseData.toString();
    } catch (_) {
      return responseData.toString();
    }
  }

  /// Short summary for listing in console or UI.
  String get summaryLine {
    final status = statusCode != null ? '$statusCode' : (isError ? 'ERR' : '???');
    final timeMs = duration != null ? '${duration!.inMilliseconds}ms' : '';
    return '[$method] [$status] ${timeMs.isNotEmpty ? '($timeMs) ' : ''}$url';
  }
}

/// Central Network Debug Console utility.
///
/// Keeps an in-memory buffer of recent HTTP interactions and prints formatted
/// requests and responses to the IDE Debug Console safely without truncation.
class DebugConsole {
  DebugConsole._();

  /// Whether debug console logging features are enabled.
  static bool enabled = kDebugMode;

  /// Whether to automatically print every response to the debug console when received.
  static bool autoPrintResponses = true;

  /// Whether to automatically print requests when dispatched.
  static bool autoPrintRequests = false;

  /// Whether to automatically print errors when they occur.
  static bool autoPrintErrors = true;

  /// Maximum number of records to keep in memory.
  static int maxHistorySize = 50;

  /// In-memory history of recent network operations.
  static final List<DebugNetworkRecord> _history = [];

  /// ValueNotifier to allow UI listeners to reactively refresh.
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static int _idCounter = 0;

  /// Returns an unmodifiable list of recent records (newest first).
  static List<DebugNetworkRecord> get history => List.unmodifiable(_history.reversed);

  /// Active route or page name.
  static String? currentPage;

  /// Logs page navigation events prominently in the debug console.
  static void logPageNavigation(String action, String pageName) {
    currentPage = pageName;
    if (enabled) {
      _safePrint(
        '╔═════════════════════════════════════════════════════════════════════════════\n'
        '║ 📱 [PAGE $action] $pageName\n'
        '╚═════════════════════════════════════════════════════════════════════════════',
        name: 'DebugConsole:Page',
      );
    }
  }

  /// Records and optionally prints an incoming response.
  static DebugNetworkRecord logResponse(Response response, {Duration? duration}) {
    final record = DebugNetworkRecord(
      id: 'req_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}',
      method: response.requestOptions.method.toUpperCase(),
      url: response.requestOptions.uri.toString(),
      queryParameters: response.requestOptions.queryParameters.isNotEmpty
          ? Map<String, dynamic>.from(response.requestOptions.queryParameters)
          : null,
      headers: Map<String, dynamic>.from(response.requestOptions.headers),
      requestData: response.requestOptions.data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      responseData: response.data,
      requestedAt: DateTime.now(),
      duration: duration,
      isError: false,
    );

    _addRecord(record);

    if (enabled && autoPrintResponses) {
      printRecord(record);
    }

    return record;
  }

  /// Records and optionally prints a network error.
  static DebugNetworkRecord logError(DioException error, {Duration? duration}) {
    final record = DebugNetworkRecord(
      id: 'err_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}',
      method: error.requestOptions.method.toUpperCase(),
      url: error.requestOptions.uri.toString(),
      queryParameters: error.requestOptions.queryParameters.isNotEmpty
          ? Map<String, dynamic>.from(error.requestOptions.queryParameters)
          : null,
      headers: Map<String, dynamic>.from(error.requestOptions.headers),
      requestData: error.requestOptions.data,
      statusCode: error.response?.statusCode,
      statusMessage: error.response?.statusMessage,
      responseData: error.response?.data,
      errorMessage: error.message ?? error.type.toString(),
      requestedAt: DateTime.now(),
      duration: duration,
      isError: true,
    );

    _addRecord(record);

    if (enabled && autoPrintErrors) {
      printRecord(record);
    }

    return record;
  }

  /// Prints a single [DebugNetworkRecord] to the debug console.
  ///
  /// Uses chunking, developer.log, and debugPrintSynchronously to ensure
  /// zero line drops on Android logcat and no truncation in IDE consoles.
  static void printRecord(DebugNetworkRecord record, {String tag = 'DebugConsole'}) {
    final buf = StringBuffer();
    final statusText = record.statusCode != null
        ? '${record.statusCode} ${record.statusMessage ?? ''}'.trim()
        : (record.isError ? 'ERROR' : 'UNKNOWN');
    final durationText = record.duration != null ? ' (${record.duration!.inMilliseconds} ms)' : '';
    final pageText = currentPage != null ? ' [Page: $currentPage]' : '';

    buf.writeln('┌─────────────────────────────────────────────────────────────────────────────');
    if (record.isError) {
      buf.writeln('│ 🔴 [PAGE ERROR]$pageText [$statusText]$durationText');
    } else {
      buf.writeln('│ 🟢 [PAGE RESPONSE]$pageText [$statusText]$durationText');
    }
    buf.writeln('│ URL: ${record.url}');
    buf.writeln('│ Method: ${record.method}');
    buf.writeln('│ Timestamp: ${record.requestedAt.toIso8601String()}');

    if (record.queryParameters != null && record.queryParameters!.isNotEmpty) {
      buf.writeln('│ Query: ${record.queryParameters}');
    }

    if (record.isError && record.errorMessage != null) {
      buf.writeln('│ Error: ${record.errorMessage}');
    }

    buf.writeln('│ Response Body:');
    final formattedBody = record.formattedResponseString;
    for (final line in formattedBody.split('\n')) {
      buf.writeln('│ $line');
    }
    buf.writeln('└─────────────────────────────────────────────────────────────────────────────');

    _safePrint(buf.toString(), name: tag);
  }

  /// Prints the most recent response to the debug console on demand.
  static void printLatestResponse() {
    if (_history.isEmpty) {
      _safePrint('[DebugConsole] No network responses recorded yet.');
      return;
    }
    printRecord(_history.last, tag: 'DebugConsole:Latest');
  }

  /// Prints every recorded response in the history to the debug console when requested.
  static void printAllResponses() {
    if (_history.isEmpty) {
      _safePrint('[DebugConsole] No network responses recorded in history.');
      return;
    }

    _safePrint(
      '═════════════════════════════════════════════════════════════════════════════\n'
      '🚀 PRINTING ALL RECORDED RESPONSES (${_history.length} items):\n'
      '═════════════════════════════════════════════════════════════════════════════',
    );

    for (int i = 0; i < _history.length; i++) {
      printRecord(_history[i], tag: 'DebugConsole:${i + 1}/${_history.length}');
    }

    _safePrint(
      '═════════════════════════════════════════════════════════════════════════════\n'
      '🏁 END OF RECORDED RESPONSES DUMP\n'
      '═════════════════════════════════════════════════════════════════════════════',
    );
  }

  /// Clears recorded history.
  static void clear() {
    _history.clear();
    changeNotifier.value++;
  }

  static void _addRecord(DebugNetworkRecord record) {
    if (_history.length >= maxHistorySize) {
      _history.removeAt(0);
    }
    _history.add(record);
    changeNotifier.value++;
  }

  /// Prints text reliably across Dart DevTools, IDE Debug Console, and terminal
  /// without line truncation or Android rate-limiting line drops.
  static void _safePrint(String message, {String name = 'DebugConsole'}) {
    // 1. DevTools logging
    developer.log(message, name: name);

    // 2. Synchronous chunked printing ensures immediate Android logcat output without throttling
    const int maxChunkSize = 800;
    for (final line in message.split('\n')) {
      if (line.length <= maxChunkSize) {
        debugPrintSynchronously(line);
      } else {
        for (int i = 0; i < line.length; i += maxChunkSize) {
          final end = (i + maxChunkSize < line.length) ? i + maxChunkSize : line.length;
          debugPrintSynchronously(line.substring(i, end));
        }
      }
    }
  }
}

/// NavigatorObserver that tracks active pages and logs navigation events.
class DebugConsoleRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _onRouteChanged('OPENED', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _onRouteChanged('RETURNED TO', previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _onRouteChanged('REPLACED WITH', newRoute);
    }
  }

  void _onRouteChanged(String action, Route<dynamic> route) {
    final name = route.settings.name ?? route.settings.arguments?.toString();
    final description = name != null && name.isNotEmpty ? name : route.toString();
    DebugConsole.logPageNavigation(action, description);
  }
}

/// Dio Interceptor that connects all requests, responses, and errors to [DebugConsole].
class DebugConsoleInterceptor extends Interceptor {
  static const String _startTimeKey = 'debug_console_start_time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;

    if (DebugConsole.enabled && DebugConsole.autoPrintRequests) {
      final buf = StringBuffer()
        ..writeln('┌─────────────────────────────────────────────────────────────────────────────')
        ..writeln('│ 🌐 [API REQUEST] ${options.method.toUpperCase()} ${options.uri}')
        ..writeln('│ Headers: ${options.headers}');
      if (options.data != null) {
        buf.writeln('│ Body: ${options.data}');
      }
      buf.writeln('└─────────────────────────────────────────────────────────────────────────────');
      debugPrint(buf.toString());
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Duration? duration;
    final startTime = response.requestOptions.extra[_startTimeKey] as int?;
    if (startTime != null) {
      duration = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - startTime);
    }

    DebugConsole.logResponse(response, duration: duration);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Duration? duration;
    final startTime = err.requestOptions.extra[_startTimeKey] as int?;
    if (startTime != null) {
      duration = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - startTime);
    }

    DebugConsole.logError(err, duration: duration);
    super.onError(err, handler);
  }
}
