import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

export '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;

  SearchRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<SearchResultsEntity>> search(
    String query, {
    String lang = 'ar',
  }) async {
    try {
      final results = await _remoteDataSource.search(query, lang: lang);
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
