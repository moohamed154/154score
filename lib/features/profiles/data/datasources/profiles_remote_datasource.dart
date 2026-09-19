import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../matches/data/models/match_dto.dart';
import '../../../matches/domain/entities/match_entity.dart';
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
    } else if (response is Map && response['data'] is Map) {
      final map = response['data'] as Map;
      if (map['name'] != null && map['name'].toString().isNotEmpty) {
        name = map['name'].toString();
      }
      if (map['name_en'] != null && map['name_en'].toString().isNotEmpty) {
        englishName = map['name_en'].toString();
      }
      if (map['photo'] != null || map['image'] != null) {
        final rawImg = (map['photo'] ?? map['image'])?.toString();
        if (rawImg != null &&
            (map['seats'] != null ||
                map['capacity'] != null ||
                map['stadium_teams'] != null)) {
          image = UrlHelper.normalizeStadiumImageUrl(rawImg);
        } else {
          image = UrlHelper.normalizeImageUrl(rawImg);
        }
      }
      if (map['country_flag'] != null || map['flag'] != null) {
        flag = UrlHelper.normalizeImageUrl(
          (map['country_flag'] ?? map['flag'])?.toString(),
        );
      }
      if (map['role'] != null) {
        role = map['role'].toString();
      }

      // Check metadata list
      final metaList = map['metadata'] as List? ?? [];
      final metaItems = <ProfileItemEntity>[];
      for (final it in metaList) {
        if (it is Map) {
          final t = (it['title'] ?? it['label'] ?? '').toString().trim();
          final c = (it['content'] ?? it['value'] ?? '').toString().trim();
          if (t.isNotEmpty && c.isNotEmpty) {
            final tLower = t.toLowerCase();
            if (tLower.contains('birth') ||
                tLower.contains('عمر') ||
                tLower.contains('ميلاد')) {
              birthDate ??= c;
            } else if (tLower.contains('country') ||
                tLower.contains('دولة') ||
                tLower.contains('جنسية')) {
              country ??= c;
            } else if (tLower.contains('مركز') ||
                tLower.contains('position')) {
              role ??= c;
            }
            metaItems.add(ProfileItemEntity(title: t, content: c));
          }
        }
      }
      if (metaItems.isNotEmpty) {
        sections.add(
          ProfileSectionEntity(
            section: lang == 'ar' ? 'معلومات عامة' : 'Overview',
            items: metaItems,
          ),
        );
      }

      // Check transfers list
      final transfersList = map['transfers'] as List? ?? [];
      final transferItems = <ProfileItemEntity>[];
      for (final tr in transfersList) {
        if (tr is Map) {
          final season =
              tr['season']?.toString() ?? tr['date']?.toString() ?? '';
          final from = tr['from_team']?.toString() ?? '';
          final to = tr['to_team']?.toString() ?? '';
          final fee = tr['fee']?.toString() ?? tr['price']?.toString() ?? '';
          final desc = '$from ➔ $to ${fee.isNotEmpty ? "($fee)" : ""}'.trim();
          if (season.isNotEmpty || desc.isNotEmpty) {
            transferItems.add(
              ProfileItemEntity(
                title: season.isNotEmpty
                    ? season
                    : (lang == 'ar' ? 'انتقال' : 'Transfer'),
                content: desc,
              ),
            );
          }
        }
      }
      if (map['country'] != null && map['country'].toString().isNotEmpty) {
        country = map['country'].toString();
      }
      if (map['channel'] != null && map['channel'].toString().isNotEmpty) {
        channel = map['channel'].toString();
      }
      if (map['birth_date'] != null && map['birth_date'].toString().isNotEmpty) {
        birthDate = map['birth_date'].toString();
      }
      if (map['commentary_language'] != null &&
          map['commentary_language'].toString().isNotEmpty) {
        commentaryLanguage = map['commentary_language'].toString();
      }
      if (map['voice_url'] != null && map['voice_url'].toString().isNotEmpty) {
        voiceUrl = map['voice_url'].toString();
      } else if (map['link_commentator'] != null &&
          map['link_commentator'].toString().isNotEmpty) {
        voiceUrl = map['link_commentator'].toString();
      }

      // Check sections from map if not yet populated
      if (map['sections'] is List && sections.isEmpty) {
        for (final sec in map['sections'] as List) {
          if (sec is Map) {
            final sName = sec['section']?.toString() ?? '';
            final rawItems = sec['items'] as List? ?? [];
            final items = <ProfileItemEntity>[];
            for (final it in rawItems) {
              if (it is Map) {
                final t = (it['title'] ?? it['label'] ?? '').toString().trim();
                final c = (it['content'] ?? it['value'] ?? '').toString().trim();
                if (t.isNotEmpty && c.isNotEmpty) {
                  items.add(
                    ProfileItemEntity(
                      title: t,
                      content: c,
                      icon: it['icon']?.toString(),
                      link: (it['link'] ?? it['url'])?.toString(),
                    ),
                  );
                }
              }
            }
            if (items.isNotEmpty && sName.isNotEmpty) {
              sections.add(ProfileSectionEntity(section: sName, items: items));
            }
          }
        }
      }
    }

    final upcomingMatches = <MatchEntity>[];
    final recentMatches = <MatchEntity>[];
    final residentTeams = <ProfileTeamEntity>[];
    String? capacity;
    String? builtDate;
    String? pitchSurface;
    String? city;
    String? mapUrl;

    if (response is Map && response['data'] is Map) {
      final map = response['data'] as Map;
      capacity = (map['capacity'] ?? map['seats'])?.toString();
      builtDate = (map['built_date'] ?? map['create'])?.toString();
      pitchSurface = (map['pitch_surface'] ?? map['floor'] ?? map['surface'])?.toString();
      city = map['city']?.toString();
      mapUrl = (map['map_link'] ?? map['link_map'])?.toString();

      final rawUpcoming = map['upcoming_matches'] as List? ??
          (map['matches'] is Map
              ? (map['matches']['coming'] as List? ??
                  (map['matches']['coming'] is Map
                      ? map['matches']['coming']['data'] as List?
                      : null))
              : null) ??
          [];
      for (final m in rawUpcoming) {
        if (m is Map) {
          try {
            upcomingMatches.add(
              MatchDto.fromJson(Map<String, dynamic>.from(m)).toEntity(),
            );
          } catch (_) {}
        }
      }

      final rawRecent = map['recent_matches'] as List? ??
          (map['matches'] is Map
              ? (map['matches']['end'] as List? ??
                  (map['matches']['end'] is Map
                      ? map['matches']['end']['data'] as List?
                      : null))
              : null) ??
          [];
      for (final m in rawRecent) {
        if (m is Map) {
          try {
            recentMatches.add(
              MatchDto.fromJson(Map<String, dynamic>.from(m)).toEntity(),
            );
          } catch (_) {}
        }
      }

      final rawTeams = map['teams'] as List? ??
          (map['stadium_teams'] is List
              ? map['stadium_teams'] as List
              : (map['stadium_teams'] is Map
                  ? (map['stadium_teams'] as Map).values.toList()
                  : null)) ??
          [];
      for (final t in rawTeams) {
        if (t is Map) {
          final tId = (t['id'] ?? t['row_id'] ?? '').toString();
          final tName = (t['name'] ?? t['title'] ?? '').toString();
          final tFullName = (t['full_name'] ?? t['full_title'])?.toString();
          final tLogo = UrlHelper.normalizeImageUrl((t['logo'] ?? t['image'])?.toString());
          final tRank = t['world_ranking'] is num ? (t['world_ranking'] as num).toInt() : null;
          if (tId.isNotEmpty || tName.isNotEmpty) {
            residentTeams.add(
              ProfileTeamEntity(
                id: tId,
                name: tName,
                fullName: tFullName,
                logo: tLogo,
                worldRanking: tRank,
              ),
            );
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
      capacity: capacity,
      builtDate: builtDate,
      pitchSurface: pitchSurface,
      city: city,
      mapUrl: mapUrl,
      sections: sections,
      upcomingMatches: upcomingMatches,
      recentMatches: recentMatches,
      residentTeams: residentTeams,
    );
  }
}
