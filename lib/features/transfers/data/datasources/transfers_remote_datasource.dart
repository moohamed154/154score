import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/transfer_dto.dart';

abstract class TransfersRemoteDataSource {
  Future<List<TransferDto>> getTransfers({
    required String lang,
    int page = 1,
    List<String>? loadedIds,
  });
}

class TransfersRemoteDataSourceImpl implements TransfersRemoteDataSource {
  final ApiClient _client;

  TransfersRemoteDataSourceImpl(this._client);

  @override
  Future<List<TransferDto>> getTransfers({
    required String lang,
    int page = 1,
    List<String>? loadedIds,
  }) async {
    final queryParams = <String, dynamic>{
      'lang': lang,
      if (page > 1) 'page': page,
      if (loadedIds != null && loadedIds.isNotEmpty)
        'loaded_ids': loadedIds.join(','),
    };

    final response = await _client.get(
      ApiEndpoints.transfers,
      queryParameters: queryParams,
    );

    if (response is Map && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) {
            if (item is Map<String, dynamic>) {
              return TransferDto.fromJson(item);
            }
            return const TransferDto(id: '', playerName: '');
          })
          .where((t) => t.playerName.isNotEmpty)
          .toList();
    }

    return [];
  }
}
