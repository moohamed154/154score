abstract class DiagnosticsRepository {
  Future<String> ping();
  Future<String> checkServerHealth();
  Future<String> fetchMetrics();
}
