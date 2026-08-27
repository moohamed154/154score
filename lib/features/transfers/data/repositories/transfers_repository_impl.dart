import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfers_repository.dart';
import '../datasources/transfers_remote_datasource.dart';

class TransfersRepositoryImpl implements TransfersRepository {
  final TransfersRemoteDataSource _remoteDataSource;

  TransfersRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<TransferEntity>>> getTransfers({
    required String lang,
  }) async {
    try {
      final dtos = await _remoteDataSource.getTransfers(lang: lang);
      final entities = dtos.map((d) => d.toEntity()).toList();
      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load transfers: $e'));
    }
  }
}
