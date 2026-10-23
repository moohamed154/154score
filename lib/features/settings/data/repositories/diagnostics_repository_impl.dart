import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/diagnostics_repository.dart';

class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  final ApiClient _apiClient;

  DiagnosticsRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<String> ping() async {
    final response = await _apiClient.get(ApiEndpoints.ping);
    return response.toString();
  }

  @override
  Future<String> checkServerHealth() async {
    final response = await _apiClient.get(ApiEndpoints.serverHealth);
    return response.toString();
  }

  @override
  Future<String> fetchMetrics() async {
    try {
      final metrics = await _apiClient.get(
        ApiEndpoints.metrics,
        options: Options(headers: {'X-Developer-Token': 'MOhamed_2002'}),
      );
      if (metrics is Map) {
        final data = metrics['data'] as Map? ?? metrics;
        return 'Metrics Online (${data.length} metrics)';
      }
      return 'Metrics Online';
    } catch (e) {
      if (e.toString().contains('ADMIN_AUTH_REQUIRED')) {
        return 'محمي إدارياً (السيرفر يعمل بنجاح)';
      }
      rethrow;
    }
  }
}
