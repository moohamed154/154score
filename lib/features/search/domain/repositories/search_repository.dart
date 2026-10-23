import '../../../../core/network/api_result.dart';
import '../entities/search_result_entity.dart';

abstract class SearchRepository {
  Future<ApiResult<SearchResultsEntity>> search(
    String query, {
    String lang = 'ar',
  });
}
