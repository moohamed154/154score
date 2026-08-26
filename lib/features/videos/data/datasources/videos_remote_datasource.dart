import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/video_entity.dart';
import '../models/video_dto.dart';

abstract class VideosRemoteDataSource {
  Future<(List<VideoItemEntity>, List<VideoCategoryEntity>)> getVideosAndCategories({
    required String champId,
    required String lang,
  });

  Future<VideoDetailEntity> getVideoDetail(String id, {required String lang});
}

class VideosRemoteDataSourceImpl implements VideosRemoteDataSource {
  final ApiClient _client;

  VideosRemoteDataSourceImpl(this._client);

  @override
  Future<(List<VideoItemEntity>, List<VideoCategoryEntity>)> getVideosAndCategories({
    required String champId,
    required String lang,
  }) async {
    final response = await _client.get(
      ApiEndpoints.videos,
      queryParameters: {
        'champ_id': champId,
        'lang': lang,
      },
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
                categories.add(VideoCategoryEntity(
                  id: item['id']?.toString() ?? 'all',
                  title: item['title']?.toString() ?? 'Category',
                ));
              }
            }
          } else if (sectionName.toLowerCase().contains('video') ||
              sectionName.toLowerCase().contains('فيديو')) {
            for (final item in items) {
              if (item is Map<String, dynamic>) {
                videos.add(VideoDto.fromJson(item).toEntity());
              }
            }
          }
        }
      }
    }

    return (videos, categories);
  }

  @override
  Future<VideoDetailEntity> getVideoDetail(String id, {required String lang}) async {
    final response = await _client.get(
      ApiEndpoints.videoDetails(id),
      queryParameters: {'lang': lang},
    );

    String title = 'Video Highlight';
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

          if (sTitle.contains('info') || sTitle.contains('معلومات')) {
            for (final it in items) {
              if (it is Map && it['title']?.toString().toLowerCase().contains('title') == true) {
                title = it['content']?.toString() ?? title;
              }
              if (it is Map && it['title']?.toString().toLowerCase().contains('embed') == true) {
                embed = it['content']?.toString();
              }
            }
          } else if (sTitle.contains('tag') || sTitle.contains('وسوم')) {
            for (final it in items) {
              if (it is Map && it['content'] != null) {
                tags.add(it['content'].toString());
              }
            }
          } else if (sTitle.contains('match') || sTitle.contains('مباراة')) {
            for (final it in items) {
              if (it is Map && it['content'] != null) {
                matchInfo = "${it['title'] ?? ''}: ${it['content']}";
              }
            }
          } else if (sTitle.contains('about') || sTitle.contains('حول')) {
            final parts = <String>[];
            for (final it in items) {
              if (it is Map && it['content'] != null) {
                parts.add(it['content'].toString());
              }
            }
            desc = parts.join('\n');
          } else if (sTitle.contains('related') || sTitle.contains('أخرى') || sTitle.contains('ذات صلة')) {
            for (final it in items) {
              if (it is Map) {
                final rId = it['link'] != null
                    ? it['link'].toString().split('/').last
                    : (it['id']?.toString() ?? '');
                related.add(VideoItemEntity(
                  id: rId,
                  title: it['title']?.toString() ?? 'Highlight',
                  image: it['image']?.toString(),
                  link: it['link']?.toString(),
                ));
              }
            }
          }
        }
      }
    }

    return VideoDetailEntity(
      id: id,
      title: title,
      embedUrl: embed,
      matchInfo: matchInfo,
      description: desc,
      tags: tags,
      relatedVideos: related,
    );
  }
}
