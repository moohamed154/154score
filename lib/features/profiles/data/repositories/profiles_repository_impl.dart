import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profiles_repository.dart';
import '../datasources/profiles_remote_datasource.dart';

class ProfilesRepositoryImpl implements ProfilesRepository {
  final ProfilesRemoteDataSource _remoteDataSource;

  ProfilesRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<ProfileEntity>> getStadiumProfile(
    String id,
    String slug, {
    required String lang,
  }) async {
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.stadium(id, slug),
        id,
        slug,
        lang: lang,
      );
      return ApiSuccess(data);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load stadium profile: $e'));
    }
  }

  @override
  Future<ApiResult<ProfileEntity>> getRefereeProfile(
    String id,
    String slug, {
    required String lang,
  }) async {
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.referee(id, slug),
        id,
        slug,
        lang: lang,
      );
      return ApiSuccess(data);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load referee profile: $e'));
    }
  }

  @override
  Future<ApiResult<ProfileEntity>> getCommentatorProfile(
    String id,
    String slug, {
    required String lang,
  }) async {
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.commentator(id, slug),
        id,
        slug,
        lang: lang,
      );
      return ApiSuccess(data);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(
        ServerFailure('Failed to load commentator profile: $e'),
      );
    }
  }
}
