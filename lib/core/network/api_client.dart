import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  static Dio _createDefaultDio() {
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

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
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

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Connection timed out. Please check your internet connection.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          'Could not connect to 154Score server. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String message = 'Server error occurred ($statusCode)';

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
        }

        if (statusCode == 503) {
          if (message.isEmpty || message.startsWith('Server error occurred')) {
            message = 'Upstream data source is temporarily busy. Please retry shortly.';
          }
        } else if (statusCode == 429) {
          message = 'Too many requests. Please wait a moment before retrying.';
        } else if (statusCode == 404) {
          if (message.isEmpty || message.startsWith('Server error occurred')) {
            message = 'The requested sports data was not found.';
          }
        }

        return ServerException(message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return const ServerException('Request was cancelled.');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkException(
            'No internet connection. Please verify your network.',
          );
        }
        return ServerException(
          error.message ?? 'Unknown network error occurred.',
        );

      default:
        return ServerException(error.message ?? 'Unexpected server error.');
    }
  }
}
