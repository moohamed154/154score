import '../../../../core/network/api_result.dart';
import '../entities/profile_entity.dart';

abstract class ProfilesRepository {
  Future<ApiResult<ProfileEntity>> getStadiumProfile(
    String id,
    String slug, {
    required String lang,
  });
  Future<ApiResult<ProfileEntity>> getRefereeProfile(
    String id,
    String slug, {
    required String lang,
  });
  Future<ApiResult<ProfileEntity>> getCommentatorProfile(
    String id,
    String slug, {
    required String lang,
  });
  Future<ApiResult<ProfileEntity>> getPlayerProfile(
    String id,
    String slug, {
    required String lang,
  });
  Future<ApiResult<ProfileEntity>> getCoachProfile(
    String id,
    String slug, {
    required String lang,
  });
}
