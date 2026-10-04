import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/maintenance_info.dart';
import '../../domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final ApiClient _apiClient;

  MaintenanceRepositoryImpl(this._apiClient);

  @override
  Future<MaintenanceInfo> checkMaintenanceStatus() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.config,
        queryParameters: {'type': 'maintenance'},
      );

      if (response.data is Map<String, dynamic>) {
        return MaintenanceInfo.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // In case /api/config?type=maintenance threw or returned 503
      try {
        final fallbackResponse = await _apiClient.get(ApiEndpoints.maintenance);
        if (fallbackResponse.data is Map<String, dynamic>) {
          return MaintenanceInfo.fromJson(
            fallbackResponse.data as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }

    return const MaintenanceInfo(
      isMaintenanceMode: false,
    );
  }
}
