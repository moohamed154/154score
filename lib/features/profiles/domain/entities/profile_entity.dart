import 'package:equatable/equatable.dart';

class ProfileItemEntity extends Equatable {
  final String title;
  final String content;

  const ProfileItemEntity({required this.title, required this.content});

  @override
  List<Object?> get props => [title, content];
}

class ProfileSectionEntity extends Equatable {
  final String section;
  final List<ProfileItemEntity> items;

  const ProfileSectionEntity({required this.section, required this.items});

  @override
  List<Object?> get props => [section, items];
}

class ProfileEntity extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? image;
  final String? countryFlag;
  final List<ProfileSectionEntity> sections;

  const ProfileEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.image,
    this.countryFlag,
    required this.sections,
  });

  @override
  List<Object?> get props => [id, slug, name, image, countryFlag, sections];
}
