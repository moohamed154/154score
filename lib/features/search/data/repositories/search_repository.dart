import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../data/models/search_result_dto.dart';
import '../../domain/entities/search_result_entity.dart';

class SearchRepository {
  final ApiClient _apiClient;

  SearchRepository(this._apiClient);

  Future<ApiResult<SearchResultsEntity>> search(
    String query, {
    String lang = 'ar',
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query, 'lang': lang},
      );

      final Map<String, dynamic> data = (response is Map<String, dynamic>)
          ? response
          : (response is Map ? Map<String, dynamic>.from(response) : {});
      final results = SearchResultDto.fromJson(data, query);
      return ApiSuccess(results);
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message));
    } on DioException catch (e) {
      return ApiFailure(
        NetworkFailure(e.message ?? 'Network error during search'),
      );
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }
}
