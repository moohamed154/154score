import '../entities/maintenance_info.dart';

abstract class MaintenanceRepository {
  Future<MaintenanceInfo> checkMaintenanceStatus();
}
