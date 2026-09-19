import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/player_profile_entity.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_datasource.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerRemoteDataSource _remoteDataSource;

  PlayerRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<PlayerProfileEntity>> getPlayerProfile(
    String id, {
    String? slug,
    required String lang,
  }) async {
    try {
      final profile = await _remoteDataSource.getPlayerProfile(
        id,
        slug: slug,
        lang: lang,
      );
      return ApiSuccess(profile);
    } on NetworkException catch (e) {
      return ApiFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ApiFailure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return ApiFailure(ServerFailure('Failed to load player profile: $e'));
    }
  }
}
