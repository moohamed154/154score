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
      final dynamic raw = await _apiClient.get(
        ApiEndpoints.config,
        queryParameters: {'type': 'maintenance'},
      );

      final Map<String, dynamic>? data = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : null);

      if (data != null) {
        return MaintenanceInfo.fromJson(data);
      }
    } catch (_) {
      try {
        final dynamic fallbackRaw =
            await _apiClient.get(ApiEndpoints.maintenance);
        final Map<String, dynamic>? fallbackData =
            fallbackRaw is Map<String, dynamic>
                ? fallbackRaw
                : (fallbackRaw is Map
                    ? Map<String, dynamic>.from(fallbackRaw)
                    : null);

        if (fallbackData != null) {
          return MaintenanceInfo.fromJson(fallbackData);
        }
      } catch (_) {}
    }

    return const MaintenanceInfo(
      isMaintenanceMode: false,
    );
  }
}
