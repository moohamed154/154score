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
    return VideoDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Football Highlight',
      image: json['image']?.toString(),
      link: json['link']?.toString(),
      date: json['date']?.toString(),
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
