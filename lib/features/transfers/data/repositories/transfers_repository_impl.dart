import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfers_repository.dart';
import '../datasources/transfers_remote_datasource.dart';

class TransfersRepositoryImpl implements TransfersRepository {
  final TransfersRemoteDataSource _remoteDataSource;
  final Map<String, ({List<TransferEntity> entities, DateTime timestamp})>
  _transfersCache = {};

  TransfersRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<TransferEntity>>> getTransfers({
    required String lang,
  }) async {
    final cached = _transfersCache[lang];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <
            const Duration(minutes: 5)) {
      return ApiSuccess(cached.entities);
    }

    try {
      final dtos = await _remoteDataSource.getTransfers(lang: lang);
      final entities = dtos.map((d) => d.toEntity()).toList();
      _transfersCache[lang] = (entities: entities, timestamp: DateTime.now());
      return ApiSuccess(entities);
    } on NetworkException catch (e) {
      if (cached != null) return ApiSuccess(cached.entities);
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return ApiSuccess(cached.entities);
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      if (cached != null) return ApiSuccess(cached.entities);
      return ApiFailure(ServerFailure('Failed to load transfers: $e'));
    }
  }
}
