import '../../../../core/constants/api_endpoints.dart';
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
    } catch (_) {
      final name = Uri.decodeComponent(slug).replaceAll('-', ' ');
      return ApiSuccess(
        ProfileEntity(
          id: id,
          slug: slug,
          name: name,
          sections: [
            ProfileSectionEntity(
              section: lang == 'ar' ? 'معلومات الملعب' : 'Stadium Information',
              items: [
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الملعب' : 'Stadium',
                  content: name,
                ),
              ],
            ),
          ],
        ),
      );
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
    } catch (_) {
      final name = Uri.decodeComponent(slug).replaceAll('-', ' ');
      return ApiSuccess(
        ProfileEntity(
          id: id,
          slug: slug,
          name: name,
          sections: [
            ProfileSectionEntity(
              section: lang == 'ar' ? 'معلومات الحكم' : 'Referee Information',
              items: [
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الاسم' : 'Name',
                  content: name,
                ),
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الصفة' : 'Role',
                  content: lang == 'ar' ? 'حكم كرة قدم' : 'Football Referee',
                ),
              ],
            ),
          ],
        ),
      );
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
    } catch (_) {
      final name = Uri.decodeComponent(slug).replaceAll('-', ' ');
      return ApiSuccess(
        ProfileEntity(
          id: id,
          slug: slug,
          name: name,
          sections: [
            ProfileSectionEntity(
              section: lang == 'ar'
                  ? 'معلومات المعلق'
                  : 'Commentator Information',
              items: [
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الاسم' : 'Name',
                  content: name,
                ),
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الصفة' : 'Role',
                  content: lang == 'ar' ? 'معلق رياضي' : 'Sports Commentator',
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
