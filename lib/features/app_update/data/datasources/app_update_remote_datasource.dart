import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/app_update_dto.dart';

abstract class AppUpdateRemoteDataSource {
  Future<AppUpdateDto> getAppUpdate();

  Future<void> downloadApk({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });
}

class AppUpdateRemoteDataSourceImpl implements AppUpdateRemoteDataSource {
  final ApiClient _apiClient;

  AppUpdateRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<AppUpdateDto> getAppUpdate() async {
    final response = await _apiClient.get(
      ApiEndpoints.config,
      queryParameters: {'type': 'update'},
    );

    if (response is Map) {
      final safeMap = Map<String, dynamic>.from(response);
      return AppUpdateDto.fromJson(safeMap);
    }

    throw const FormatException('Invalid update response format from server');
  }

  @override
  Future<void> downloadApk({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _apiClient.dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      deleteOnError: true,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
