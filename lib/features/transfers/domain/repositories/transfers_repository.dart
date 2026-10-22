import '../../../../core/network/api_result.dart';
import '../entities/transfer_entity.dart';

abstract class TransfersRepository {
  Future<ApiResult<List<TransferEntity>>> getTransfers({
    required String lang,
    int page = 1,
    List<String>? loadedIds,
  });
}
