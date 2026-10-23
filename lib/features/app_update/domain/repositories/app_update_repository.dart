import 'package:dio/dio.dart';

import '../../../../core/network/api_result.dart';
import '../entities/app_update_entity.dart';

abstract class AppUpdateRepository {
  Future<ApiResult<AppUpdateEntity>> getAppUpdate();

  Future<void> downloadApk({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });
}
