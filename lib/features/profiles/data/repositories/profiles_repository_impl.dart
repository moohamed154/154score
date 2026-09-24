import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/commentator_resolver.dart';
import '../../../../core/utils/url_helper.dart';
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
    final cleanSlug = UrlHelper.safeDecodeComponent(slug);
    final encodedSlug = Uri.encodeComponent(cleanSlug);
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.stadium(id, encodedSlug),
        id,
        cleanSlug,
        lang: lang,
      );
      return ApiSuccess(data);
    } catch (_) {
      final name = UrlHelper.slugToName(slug);
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
    final cleanSlug = UrlHelper.safeDecodeComponent(slug);
    final encodedSlug = Uri.encodeComponent(cleanSlug);
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.referee(id, encodedSlug),
        id,
        cleanSlug,
        lang: lang,
      );
      return ApiSuccess(data);
    } catch (_) {
      final name = UrlHelper.slugToName(slug);
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
    final cleanSlug = UrlHelper.safeDecodeComponent(slug);
    String effectiveId = id;
    String effectiveSlug = cleanSlug;

    // Resolve known commentators when navigation arrives with missing or 0 id
    if (effectiveId == '0' || effectiveId.isEmpty) {
      final resolvedId =
          CommentatorResolver.resolveId(cleanSlug) ??
          CommentatorResolver.resolveId(slug);
      if (resolvedId != null) {
        effectiveId = resolvedId;
        effectiveSlug = CommentatorResolver.getSlug(resolvedId);
      }
    }

    final encodedSlug = Uri.encodeComponent(effectiveSlug);
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.commentator(effectiveId, encodedSlug),
        effectiveId,
        effectiveSlug,
        lang: lang,
      );
      return ApiSuccess(data);
    } catch (_) {
      final name = UrlHelper.slugToName(slug);
      return ApiSuccess(
        ProfileEntity(
          id: id,
          slug: slug,
          name: name,
          role: lang == 'ar' ? 'معلق رياضي' : 'Sports Commentator',
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

  @override
  Future<ApiResult<ProfileEntity>> getPlayerProfile(
    String id,
    String slug, {
    required String lang,
  }) async {
    final cleanSlug = UrlHelper.safeDecodeComponent(slug);
    final encodedSlug = Uri.encodeComponent(cleanSlug);
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.playerProfile(id, encodedSlug),
        id,
        cleanSlug,
        lang: lang,
      );
      return ApiSuccess(data);
    } catch (_) {
      final name = UrlHelper.slugToName(slug);
      return ApiSuccess(
        ProfileEntity(
          id: id,
          slug: slug,
          name: name,
          role: lang == 'ar' ? 'لاعب كرة قدم' : 'Football Player',
          sections: [
            ProfileSectionEntity(
              section: lang == 'ar' ? 'معلومات اللاعب' : 'Player Information',
              items: [
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الاسم' : 'Name',
                  content: name,
                ),
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الصفة' : 'Role',
                  content: lang == 'ar' ? 'لاعب كرة قدم' : 'Football Player',
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  @override
  Future<ApiResult<ProfileEntity>> getCoachProfile(
    String id,
    String slug, {
    required String lang,
  }) async {
    final cleanSlug = UrlHelper.safeDecodeComponent(slug);
    final encodedSlug = Uri.encodeComponent(cleanSlug);
    try {
      final data = await _remoteDataSource.getProfile(
        ApiEndpoints.coach(id, encodedSlug),
        id,
        cleanSlug,
        lang: lang,
      );
      return ApiSuccess(data);
    } catch (_) {
      final name = UrlHelper.slugToName(slug);
      return ApiSuccess(
        ProfileEntity(
          id: id,
          slug: slug,
          name: name,
          role: lang == 'ar' ? 'المدير الفني' : 'Head Coach',
          sections: [
            ProfileSectionEntity(
              section: lang == 'ar' ? 'معلومات المدرب' : 'Coach Information',
              items: [
                ProfileItemEntity(
                  title: lang == 'ar' ? 'الاسم' : 'Name',
                  content: name,
                ),
                ProfileItemEntity(
                  title: lang == 'ar' ? 'المنصب' : 'Role',
                  content: lang == 'ar' ? 'المدير الفني' : 'Head Coach',
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
