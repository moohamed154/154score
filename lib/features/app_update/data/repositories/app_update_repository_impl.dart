import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_update_entity.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_datasource.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDataSource _remoteDataSource;

  AppUpdateRepositoryImpl({
    required AppUpdateRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<ApiResult<AppUpdateEntity>> getAppUpdate() async {
    try {
      final dto = await _remoteDataSource.getAppUpdate();
      return ApiSuccess(dto);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load update info: $e'));
    }
  }
}
