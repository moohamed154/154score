import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../security/security_signer.dart';
import '../storage/local_storage_service.dart';
import 'debug_console.dart';

class ApiClient {
  final Dio _dio;
  final LocalStorageService? _localStorageService;

  ApiClient({Dio? dio, LocalStorageService? localStorageService})
    : _localStorageService = localStorageService,
      _dio = dio ?? _createDefaultDio(localStorageService) {
    if (!_dio.interceptors.any((i) => i is DebugConsoleInterceptor)) {
      _dio.interceptors.insert(0, DebugConsoleInterceptor());
    }
  }

  static Dio _createDefaultDio([LocalStorageService? localStorageService]) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'User-Agent': '154Score-Flutter/1.0',
        },
      ),
    );

    // Anti-Proxy / MITM defense: prevent Charles / Burp Suite WiFi proxies in production release builds
    if (!kIsWeb && dio.httpClientAdapter is IOHttpClientAdapter) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        if (kReleaseMode) {
          client.findProxy = (uri) => 'DIRECT';
        }
        return client;
      };
    }

    // Network Debug Console Interceptor: captures and prints responses
    dio.interceptors.add(DebugConsoleInterceptor());

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            final requiresApiKey = !_isPublicEndpoint(options.path);
            if (requiresApiKey) {
              options.headers['X-API-Key'] = AppConfig.validateApiKey();
            }
          } on ConfigurationException catch (error) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
                type: DioExceptionType.unknown,
              ),
            );
            return;
          }

          // Anti-Tampering & Anti-Scraping: attach dynamic cryptographic signature (HMAC-SHA256, Nonce, Timestamp)
          final signPath = options.uri.path.isNotEmpty ? options.uri.path : options.path;
          final securityHeaders = SecuritySigner.buildSecurityHeaders(
            method: options.method,
            path: signPath,
          );
          options.headers.addAll(securityHeaders);

          // Resolve current timezone offset from LocalStorageService (default to 3)
          int offset = 3;
          if (localStorageService != null) {
            offset = localStorageService.getTimezoneOffset();
          } else {
            try {
              if (GetIt.instance.isRegistered<LocalStorageService>()) {
                offset = GetIt.instance<LocalStorageService>()
                    .getTimezoneOffset();
              }
            } catch (_) {}
          }

          // 1. If options.queryParameters already has 'utc-offset', ensure it's a String
          if (options.queryParameters.containsKey('utc-offset')) {
            options.queryParameters['utc-offset'] = options
                .queryParameters['utc-offset']
                .toString();
          } else {
            // 2. Automatically inject utc-offset as String for any match-related endpoint
            final path = options.path;
            final isMatchEndpoint =
                path.startsWith('/api/matches') ||
                path.startsWith(ApiEndpoints.matches) ||
                path.contains('/matches') ||
                path.contains('/teams') ||
                path.contains('/leagues');
            if (isMatchEndpoint) {
              options.queryParameters['utc-offset'] = offset.toString();
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.data != null) {
            response.data = _sanitizeResponseData(response.data);
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  Dio get dio => _dio;
  LocalStorageService? get localStorageService => _localStorageService;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Unexpected error occurred: $e');
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Unexpected error occurred: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    final requestId = _extractRequestId(error);
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timed out. Please check your internet connection.',
          requestId: requestId,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'Could not connect to 154Score server. Please check your internet connection.',
          requestId: requestId,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String message = 'Server error occurred ($statusCode)';
        String? code;

        if (responseData is Map) {
          if (responseData.containsKey('message') &&
              responseData['message'] != null) {
            message = responseData['message'].toString();
          } else if (responseData.containsKey('error') &&
              responseData['error'] != null) {
            message = responseData['error'].toString();
          } else if (responseData.containsKey('detail') &&
              responseData['detail'] != null) {
            message = responseData['detail'].toString();
          }
          if (responseData.containsKey('code') &&
              responseData['code'] != null) {
            code = responseData['code'].toString();
          }
        }

        if (statusCode == 401) {
          final resolvedCode =
              code ?? _extractErrorCode(responseData) ?? 'AUTH_REQUIRED';
          return ApiAuthenticationException(
            _normalizeErrorMessage(message, 'Authentication required.'),
            code: resolvedCode,
            requestId: requestId,
            statusCode: statusCode,
          );
        }

        if (statusCode == 403) {
          return ForbiddenException(
            _normalizeErrorMessage(message, 'Access forbidden.'),
            requestId: requestId,
            statusCode: statusCode,
          );
        }

        if (statusCode == 429) {
          final retryAfter = _parseRetryAfter(error.response?.headers);
          return RateLimitException(
            'Too many requests. Please try again shortly.',
            requestId: requestId,
            statusCode: statusCode,
            retryAfter: retryAfter,
          );
        }

        if (statusCode == 503) {
          if (message.isEmpty || message.startsWith('Server error occurred')) {
            message = 'Upstream data source is temporarily busy. Please retry shortly.';
          }
        } else if (statusCode == 404) {
          if (message.isEmpty || message.startsWith('Server error occurred')) {
            message = 'The requested sports data was not found.';
          }
        }

        return ServerException(
          _normalizeErrorMessage(message, 'Server error occurred.'),
          statusCode: statusCode,
          requestId: requestId,
        );

      case DioExceptionType.cancel:
        return const ServerException('Request was cancelled.');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException(
            'No internet connection. Please verify your network.',
            requestId: requestId,
          );
        }
        if (error.error is ConfigurationException) {
          return const ConfigurationException(
            'API configuration is missing. Please provide --dart-define=API_KEY=YOUR_API_KEY.',
          );
        }
        return ServerException(
          error.message ?? 'Unknown network error occurred.',
          requestId: requestId,
        );

      default:
        return ServerException(
          error.message ?? 'Unexpected server error.',
          requestId: requestId,
        );
    }
  }

  static String _normalizeErrorMessage(String? value, String fallback) {
    final message = (value ?? '').trim();
    if (message.isEmpty || message == 'null') {
      return fallback;
    }
    return message;
  }

  static String? _extractErrorCode(dynamic responseData) {
    if (responseData is Map) {
      for (final key in ['code', 'error', 'error_code']) {
        final value = responseData[key];
        if (value != null) {
          return value.toString();
        }
      }
    }
    return null;
  }

  static String? _extractRequestId(DioException error) {
    final headers = error.response?.headers;
    if (headers == null) return null;
    return headers.value('x-request-id') ??
        headers.value('X-Request-ID') ??
        headers.value('x-request-id');
  }

  static Duration? _parseRetryAfter(Headers? headers) {
    final value = headers?.value('retry-after');
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      final diff = parsed.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    }
    return null;
  }

  static bool _isPublicEndpoint(String path) {
    final normalized = path.trim();
    return normalized == '/' ||
        normalized == '/ping' ||
        normalized == ApiEndpoints.config ||
        normalized == ApiEndpoints.health ||
        normalized == ApiEndpoints.update ||
        normalized == ApiEndpoints.maintenance;
  }

  static dynamic _sanitizeResponseData(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      return _sanitizeString(data);
    }
    if (data is List) {
      final sanitizedList = [];
      for (final item in data) {
        if (_shouldDropItem(item)) continue;
        sanitizedList.add(_sanitizeResponseData(item));
      }
      return sanitizedList;
    }
    if (data is Map) {
      final sanitizedMap = <String, dynamic>{};
      for (final entry in data.entries) {
        sanitizedMap[entry.key.toString()] = _sanitizeResponseData(entry.value);
      }
      return sanitizedMap;
    }
    return data;
  }

  static final RegExp _forbiddenRegExp = RegExp(
    r'(تحميل تطبيق يلا شووت|تحميل تطبيق يلا شوت|تحميل تطبيق يلاشووت|تحميل تطبيق يلاشود|download\s*yalla[- ]*shoot(\s*app)?|download\s*ys\s*scores?(\s*app)?)',
    caseSensitive: false,
  );

  static String _sanitizeString(String str) {
    if (str.length < 5) return str;
    // Fast path: avoid expensive regex execution if string doesn't contain forbidden patterns
    if (!str.contains('يلا') &&
        !str.toLowerCase().contains('download') &&
        !str.toLowerCase().contains('shoot') &&
        !str.toLowerCase().contains('scores')) {
      return str;
    }
    if (!_forbiddenRegExp.hasMatch(str)) return str;
    return str.replaceAll(_forbiddenRegExp, '').trim();
  }

  static bool _shouldDropItem(dynamic item) {
    if (item is! Map) return false;
    final title = (item['title'] ?? item['name'] ?? item['news_title'] ?? '')
        .toString()
        .trim();
    final url = (item['url'] ?? item['link'] ?? item['href'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (_forbiddenRegExp.hasMatch(title) ||
        (title.contains('تحميل تطبيق') &&
            (title.contains('يلا') ||
                title.contains('شووت') ||
                title.contains('شوت')))) {
      return true;
    }

    if (url.contains('download-yalla-shoot') ||
        url.contains('download-ysscores') ||
        url.contains('download-app')) {
      return true;
    }

    return false;
  }
}
