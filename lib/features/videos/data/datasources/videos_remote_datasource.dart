import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/video_entity.dart';
import '../models/video_dto.dart';

abstract class VideosRemoteDataSource {
  Future<(List<VideoItemEntity>, List<VideoCategoryEntity>)>
  getVideosAndCategories({required String champId, required String lang});

  Future<VideoDetailEntity> getVideoDetail(String id, {required String lang});
}

class VideosRemoteDataSourceImpl implements VideosRemoteDataSource {
  final ApiClient _client;

  VideosRemoteDataSourceImpl(this._client);

  @override
  Future<(List<VideoItemEntity>, List<VideoCategoryEntity>)>
  getVideosAndCategories({
    required String champId,
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.videos,
      queryParameters: {'champ_id': champId, 'lang': lang},
    );

    final videos = <VideoItemEntity>[];
    final categories = <VideoCategoryEntity>[];

    if (response is Map && response['data'] is List) {
      final sections = response['data'] as List;
      for (final sec in sections) {
        if (sec is Map) {
          final sectionName = sec['section']?.toString() ?? '';
          final items = sec['items'] as List? ?? [];

          if (sectionName.toLowerCase().contains('championship') ||
              sectionName.toLowerCase().contains('بطول') ||
              sectionName.toLowerCase().contains('appearances')) {
            for (final item in items) {
              if (item is Map) {
                categories.add(
                  VideoCategoryEntity(
                    id: item['id']?.toString() ?? 'all',
                    title: item['title']?.toString() ?? 'Category',
                  ),
                );
              }
            }
          } else if (sectionName.toLowerCase().contains('video') ||
              sectionName.toLowerCase().contains('فيديو')) {
            for (final item in items) {
              if (item is Map<String, dynamic>) {
                videos.add(VideoDto.fromJson(item).toEntity());
              } else if (item is Map) {
                videos.add(
                  VideoDto.fromJson(Map<String, dynamic>.from(item)).toEntity(),
                );
              }
            }
          }
        }
      }
    }

    return (videos, categories);
  }

  @override
  Future<VideoDetailEntity> getVideoDetail(
    String id, {
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.videoDetails(id),
      queryParameters: {'lang': lang},
    );

    String title = 'Video Highlight';
    String? rawImage;
    String? rawVideoUrl;
    String? embed;
    String? matchInfo;
    String? desc;
    final tags = <String>[];
    final related = <VideoItemEntity>[];

    if (response is Map && response['data'] is List) {
      final list = response['data'] as List;
      for (final sec in list) {
        if (sec is Map) {
          final sTitle = sec['section']?.toString().toLowerCase() ?? '';
          final items = sec['items'] as List? ?? [];

          if (sTitle.contains('info') ||
              sTitle.contains('معلومات') ||
              sTitle.contains('مقطع') ||
              sTitle.contains('details')) {
            for (final it in items) {
              if (it is Map) {
                final itemTitle = it['title']?.toString().toLowerCase() ?? '';
                final itemContent = it['content']?.toString();
                final itemLink =
                    it['link']?.toString() ?? it['url']?.toString();

                if (itemTitle.contains('title') ||
                    itemTitle.contains('عنوان') ||
                    itemTitle.contains('الاسم')) {
                  title = itemContent ?? it['name']?.toString() ?? title;
                }

                if (itemTitle.contains('image') ||
                    itemTitle.contains('صورة') ||
                    itemTitle.contains('thumbnail')) {
                  rawImage = itemContent ?? itemLink ?? rawImage;
                }

                if (itemTitle.contains('video') ||
                    itemTitle.contains('رابط') ||
                    itemTitle.contains('فيديو') ||
                    itemTitle.contains('link') ||
                    itemTitle.contains('url') ||
                    itemTitle.contains('source') ||
                    itemTitle.contains('youtube') ||
                    itemTitle.contains('تضمين') ||
                    itemTitle.contains('embed')) {
                  rawVideoUrl = itemLink ?? itemContent ?? rawVideoUrl;
                  embed = itemContent ?? itemLink ?? embed;
                }
              }
            }
          } else if (sTitle.contains('tag') ||
              sTitle.contains('وسوم') ||
              sTitle.contains('الكلمات') ||
              sTitle.contains('keywords')) {
            for (final it in items) {
              if (it is Map && it['content'] != null) {
                tags.add(it['content'].toString());
              }
            }
          } else if (sTitle.contains('match') ||
              sTitle.contains('مباراة') ||
              sTitle.contains('مركز') ||
              sTitle.contains('center')) {
            final matchParts = <String>[];
            for (final it in items) {
              if (it is Map && it['content'] != null) {
                final t = it['title']?.toString();
                if (t != null && t.isNotEmpty) {
                  matchParts.add('$t: ${it['content']}');
                } else {
                  matchParts.add(it['content'].toString());
                }
              }
            }
            if (matchParts.isNotEmpty) {
              matchInfo = matchParts.join(' · ');
            }
          } else if (sTitle.contains('about') ||
              sTitle.contains('حول') ||
              sTitle.contains('عن') ||
              sTitle.contains('وصف') ||
              sTitle.contains('desc')) {
            final parts = <String>[];
            for (final it in items) {
              if (it is Map && it['content'] != null) {
                parts.add(it['content'].toString());
              }
            }
            desc = parts.join('\n');
          } else if (sTitle.contains('related') ||
              sTitle.contains('أخرى') ||
              sTitle.contains('ذات صلة') ||
              sTitle.contains('صلة') ||
              sTitle.contains('more')) {
            for (final it in items) {
              if (it is Map) {
                final rId = it['link'] != null
                    ? it['link'].toString().split('/').last
                    : (it['id']?.toString() ?? '');
                final rImg =
                    it['image']?.toString() ?? it['thumbnail']?.toString();
                related.add(
                  VideoItemEntity(
                    id: rId,
                    title: it['title']?.toString() ?? 'Highlight',
                    image: UrlHelper.normalizeImageUrl(rImg),
                    link: it['link']?.toString() ?? it['url']?.toString(),
                  ),
                );
              }
            }
          }
        }
      }
    }

    final normalizedImg = UrlHelper.normalizeImageUrl(rawImage);
    final normalizedVideoUrl = UrlHelper.normalizeVideoUrl(
      rawVideoUrl,
      thumbnail: normalizedImg,
    );

    return VideoDetailEntity(
      id: id,
      title: title,
      image: normalizedImg,
      videoUrl: normalizedVideoUrl,
      embedUrl: embed ?? normalizedVideoUrl,
      matchInfo: matchInfo,
      description: desc,
      tags: tags,
      relatedVideos: related,
    );
  }
}
