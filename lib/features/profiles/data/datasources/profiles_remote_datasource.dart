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

    String name = UrlHelper.slugToName(slug);
    String? englishName;
    String? image;
    String? flag;
    String? country;
    String? channel;
    String? birthDate;
    String? commentaryLanguage;
    String? voiceUrl;
    String? role;
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
              final title =
                  (it['title'] ?? it['label'] ?? '').toString().trim();
              final content =
                  (it['content'] ?? it['value'] ?? '').toString().trim();
              final icon = it['icon']?.toString();
              final link = (it['link'] ?? it['url'])?.toString();

              if (title.isEmpty && content.isEmpty) continue;

              final tLower = title.toLowerCase();

              // Check if item is an image or flag URL
              final isImageItem =
                  tLower == 'image' ||
                  tLower == 'photo' ||
                  title == 'الصورة' ||
                  title.contains('صورة') ||
                  content.contains('imgs.ysscores.com');

              final isFlagItem =
                  tLower.contains('flag') ||
                  tLower.contains('country logo') ||
                  title.contains('شعار الدولة') ||
                  title.contains('علم') ||
                  content.contains('/flags/');

              if (isImageItem) {
                image = UrlHelper.normalizeImageUrl(content);
                continue; // Do not display raw image URL as text row
              }

              if (isFlagItem) {
                flag = UrlHelper.normalizeImageUrl(content);
                continue; // Do not display raw flag URL as text row
              }

              // Extract key entity attributes
              if (tLower == 'name' || title == 'الاسم') {
                if (content.isNotEmpty) name = content;
              } else if (tLower.contains('english') ||
                  title.contains('الانجليزي')) {
                if (content.isNotEmpty) englishName = content;
              } else if (tLower == 'country' ||
                  tLower == 'nationality' ||
                  title == 'الدولة' ||
                  title == 'الجنسية') {
                if (content.isNotEmpty) country = content;
              } else if (tLower.contains('channel') ||
                  tLower.contains('network') ||
                  title.contains('القناة') ||
                  title.contains('شبكة')) {
                if (content.isNotEmpty) channel = content;
              } else if (tLower.contains('birth') ||
                  tLower.contains('age') ||
                  title.contains('الميلاد') ||
                  title.contains('العمر')) {
                if (content.isNotEmpty) birthDate = content;
              } else if (tLower.contains('language') || title.contains('لغة')) {
                if (content.isNotEmpty) commentaryLanguage = content;
              } else if (tLower.contains('voice') ||
                  tLower.contains('audio') ||
                  title.contains('صوت')) {
                if (content.isNotEmpty) voiceUrl = link ?? content;
              } else if (tLower == 'role' ||
                  title.contains('الصفة') ||
                  title.contains('المهنة')) {
                if (content.isNotEmpty) role = content;
              }

              // Retain valid text items in sections
              if (title.isNotEmpty && content.isNotEmpty) {
                items.add(
                  ProfileItemEntity(
                    title: title,
                    content: content,
                    icon: icon,
                    link: link,
                  ),
                );
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
      englishName: englishName,
      image: image,
      countryFlag: flag,
      country: country,
      channel: channel,
      birthDate: birthDate,
      commentaryLanguage: commentaryLanguage,
      voiceUrl: voiceUrl,
      role: role,
      sections: sections,
    );
  }
}
