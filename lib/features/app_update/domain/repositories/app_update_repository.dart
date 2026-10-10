import '../../../../core/network/api_result.dart';
import '../entities/app_update_entity.dart';

abstract class AppUpdateRepository {
  Future<ApiResult<AppUpdateEntity>> getAppUpdate();
}
