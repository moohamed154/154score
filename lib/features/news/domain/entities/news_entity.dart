import 'package:equatable/equatable.dart';

class NewsArticleEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final String? thumbnail;
  final String? publishedAt;
  final String? slug;
  final String? url;

  const NewsArticleEntity({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.thumbnail,
    this.publishedAt,
    this.slug,
    this.url,
  });

  @override
  List<Object?> get props => [id, title];
}

class NewsTeamFilterEntity extends Equatable {
  final String id;
  final String name;
  final String? logo;

  const NewsTeamFilterEntity({
    required this.id,
    required this.name,
    this.logo,
  });

  @override
  List<Object?> get props => [id, name];
}

class NewsFeedEntity extends Equatable {
  final NewsArticleEntity? main;
  final List<NewsArticleEntity> important;
  final List<NewsTeamFilterEntity> teams;
  final List<NewsArticleEntity> latest;

  const NewsFeedEntity({
    this.main,
    this.important = const [],
    this.teams = const [],
    this.latest = const [],
  });

  @override
  List<Object?> get props => [main, important, teams, latest];
}

class NewsDetailEntity extends Equatable {
  final String id;
  final String title;
  final String? image;
  final String? publishedAt;
  final List<String> paragraphs;
  final String? content;
  final List<String> tags;
  final String? url;

  const NewsDetailEntity({
    required this.id,
    required this.title,
    this.image,
    this.publishedAt,
    this.paragraphs = const [],
    this.content,
    this.tags = const [],
    this.url,
  });

  @override
  List<Object?> get props => [id, title];
}
