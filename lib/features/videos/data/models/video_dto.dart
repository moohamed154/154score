import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/video_entity.dart';

class VideoDto {
  final String id;
  final String title;
  final String? image;
  final String? link;
  final String? date;

  const VideoDto({
    required this.id,
    required this.title,
    this.image,
    this.link,
    this.date,
  });

  factory VideoDto.fromJson(Map<String, dynamic> json) {
    final rawLink = json['link']?.toString() ?? json['url']?.toString();
    String id = json['id']?.toString() ?? '';
    if (id.isEmpty && rawLink != null) {
      final segments = rawLink.split('/');
      if (segments.isNotEmpty) {
        id = segments.last;
      }
    }

    final rawImage = json['image']?.toString() ?? json['thumbnail']?.toString();

    return VideoDto(
      id: id.isNotEmpty ? id : 'video',
      title: json['title']?.toString() ?? 'Football Highlight',
      image: UrlHelper.normalizeImageUrl(rawImage),
      link: rawLink,
      date: json['date']?.toString() ?? json['published_at']?.toString(),
    );
  }

  VideoItemEntity toEntity({String? championship}) {
    return VideoItemEntity(
      id: id,
      title: title,
      image: image,
      link: link,
      date: date,
      championship: championship,
    );
  }
}
