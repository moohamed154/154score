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
    final queryParameters = <String, dynamic>{'lang': lang};
    if (champId.isNotEmpty && champId != 'all') {
      queryParameters['champ_id'] = champId;
    }

    final response = await _client.get(
      ApiEndpoints.videos,
      queryParameters: queryParameters,
    );

    final videos = <VideoItemEntity>[];
    final categories = <VideoCategoryEntity>[];

    if (response is Map && response['data'] is List) {
      final data = response['data'] as List;
      for (final rawItem in data) {
        if (rawItem is! Map) continue;

        final item = Map<String, dynamic>.from(rawItem);
        final sectionName = item['section']?.toString().toLowerCase() ?? '';
        final sectionItems = item['items'];

        // Current API shape: data is a flat list of video objects.
        if (item['title'] != null && sectionItems is! List) {
          videos.add(
            VideoDto.fromJson(item)
                .toEntity(championship: item['championship']?.toString()),
          );
          continue;
        }

        if (sectionItems is! List) continue;

        if (sectionName.contains('championship') ||
            sectionName.contains('بطول') ||
            sectionName.contains('appearances')) {
          for (final rawCategory in sectionItems) {
            if (rawCategory is Map) {
              categories.add(
                VideoCategoryEntity(
                  id: rawCategory['id']?.toString() ?? 'all',
                  title: rawCategory['title']?.toString() ?? 'Category',
                ),
              );
            }
          }
        } else if (sectionName.contains('video') ||
            sectionName.contains('فيديو')) {
          for (final rawVideo in sectionItems) {
            if (rawVideo is Map) {
              final video = Map<String, dynamic>.from(rawVideo);
              videos.add(
                VideoDto.fromJson(video)
                    .toEntity(championship: video['championship']?.toString()),
              );
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
