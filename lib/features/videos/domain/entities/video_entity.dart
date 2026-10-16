import 'package:equatable/equatable.dart';

class VideoItemEntity extends Equatable {
  final String id;
  final String title;
  final String? image;
  final String? link;
  final String? date;
  final String? championship;

  const VideoItemEntity({
    required this.id,
    required this.title,
    this.image,
    this.link,
    this.date,
    this.championship,
  });

  @override
  List<Object?> get props => [id, title, image, link, date, championship];
}

class VideoCategoryEntity extends Equatable {
  final String id;
  final String title;

  const VideoCategoryEntity({required this.id, required this.title});

  @override
  List<Object?> get props => [id, title];
}

class VideoDetailEntity extends Equatable {
  final String id;
  final String title;
  final String? image;
  final String? videoUrl;
  final String? embedUrl;
  final String? matchInfo;
  final String? description;
  final List<String> tags;
  final List<VideoItemEntity> relatedVideos;

  const VideoDetailEntity({
    required this.id,
    required this.title,
    this.image,
    this.videoUrl,
    this.embedUrl,
    this.matchInfo,
    this.description,
    this.tags = const [],
    this.relatedVideos = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        image,
        videoUrl,
        embedUrl,
        matchInfo,
        description,
        tags,
        relatedVideos,
      ];
}
