import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/search_result_entity.dart';
import '../models/search_result_dto.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResultsEntity> search(
    String query, {
    String lang = 'ar',
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiClient _apiClient;

  SearchRemoteDataSourceImpl(this._apiClient);

  @override
  Future<SearchResultsEntity> search(
    String query, {
    String lang = 'ar',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.search,
      queryParameters: {'q': query, 'lang': lang},
    );

    final Map<String, dynamic> data = (response is Map<String, dynamic>)
        ? response
        : (response is Map ? Map<String, dynamic>.from(response) : {});
    return SearchResultDto.fromJson(data, query);
  }
}
