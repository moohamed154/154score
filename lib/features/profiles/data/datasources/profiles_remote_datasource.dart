import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/profile_entity.dart';

abstract class ProfilesRemoteDataSource {
  Future<ProfileEntity> getProfile(
    String endpoint,
    String id,
    String slug, {
    required String lang,
  });
}

class ProfilesRemoteDataSourceImpl implements ProfilesRemoteDataSource {
  final ApiClient _client;

  ProfilesRemoteDataSourceImpl(this._client);

  @override
  Future<ProfileEntity> getProfile(
    String endpoint,
    String id,
    String slug, {
    required String lang,
  }) async {
    final response = await _client.get(
      endpoint,
      queryParameters: {'lang': lang},
    );

    String name = slug.replaceAll('-', ' ');
    String? image;
    String? flag;
    final sections = <ProfileSectionEntity>[];

    if (response is Map && response['data'] is List) {
      final list = response['data'] as List;
      for (final sec in list) {
        if (sec is Map) {
          final sName = sec['section']?.toString() ?? 'Info';
          final rawItems = sec['items'] as List? ?? [];
          final items = <ProfileItemEntity>[];

          for (final it in rawItems) {
            if (it is Map) {
              final title = it['title']?.toString() ?? '';
              final content = it['content']?.toString() ?? '';

              if (title.toLowerCase() == 'name' ||
                  title.toLowerCase() == 'الاسم') {
                name = content;
              } else if (title.toLowerCase() == 'image' ||
                  title.toLowerCase() == 'الصورة') {
                image = UrlHelper.normalizeImageUrl(content);
              } else if (title.toLowerCase().contains('flag') ||
                  title.toLowerCase().contains('country logo') ||
                  title.toLowerCase().contains('شعار الدولة') ||
                  title.toLowerCase().contains('علم')) {
                flag = UrlHelper.normalizeImageUrl(content);
              } else if (title.isNotEmpty && content.isNotEmpty) {
                items.add(ProfileItemEntity(title: title, content: content));
              }
            }
          }

          if (items.isNotEmpty) {
            sections.add(ProfileSectionEntity(section: sName, items: items));
          }
        }
      }
    }

    return ProfileEntity(
      id: id,
      slug: slug,
      name: name,
      image: image,
      countryFlag: flag,
      sections: sections,
    );
  }
}
