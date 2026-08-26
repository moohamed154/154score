import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/transfer_dto.dart';

abstract class TransfersRemoteDataSource {
  Future<List<TransferDto>> getTransfers({required String lang});
}

class TransfersRemoteDataSourceImpl implements TransfersRemoteDataSource {
  final ApiClient _client;

  TransfersRemoteDataSourceImpl(this._client);

  @override
  Future<List<TransferDto>> getTransfers({required String lang}) async {
    final response = await _client.get(
      ApiEndpoints.transfers,
      queryParameters: {'lang': lang},
    );

    if (response is Map && response['data'] is List) {
      final list = response['data'] as List;
      return list.map((item) {
        if (item is Map<String, dynamic>) {
          return TransferDto.fromJson(item);
        }
        return const TransferDto(id: '', playerName: '');
      }).where((t) => t.playerName.isNotEmpty).toList();
    }

    return [];
  }
}
