import 'package:equatable/equatable.dart';
import '../../../matches/domain/entities/match_entity.dart';

class ProfileItemEntity extends Equatable {
  final String title;
  final String content;
  final String? icon;
  final String? link;

  const ProfileItemEntity({
    required this.title,
    required this.content,
    this.icon,
    this.link,
  });

  @override
  List<Object?> get props => [title, content, icon, link];
}

class ProfileSectionEntity extends Equatable {
  final String section;
  final List<ProfileItemEntity> items;

  const ProfileSectionEntity({required this.section, required this.items});

  @override
  List<Object?> get props => [section, items];
}

class ProfileTeamEntity extends Equatable {
  final String id;
  final String name;
  final String? fullName;
  final String? logo;
  final int? worldRanking;
  final String? role;
  final String? from;
  final String? to;
  final String? duration;
  final bool isCurrent;

  const ProfileTeamEntity({
    required this.id,
    required this.name,
    this.fullName,
    this.logo,
    this.worldRanking,
    this.role,
    this.from,
    this.to,
    this.duration,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        fullName,
        logo,
        worldRanking,
        role,
        from,
        to,
        duration,
        isCurrent,
      ];
}

class ProfileEntity extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? englishName;
  final String? image;
  final String? countryFlag;
  final String? country;
  final String? channel;
  final String? birthDate;
  final String? commentaryLanguage;
  final String? voiceUrl;
  final String? role;
  final String? capacity;
  final String? builtDate;
  final String? pitchSurface;
  final String? city;
  final String? mapUrl;
  final ProfileTeamEntity? currentTeam;
  final List<ProfileTeamEntity> career;
  final List<ProfileSectionEntity> sections;
  final List<MatchEntity> upcomingMatches;
  final List<MatchEntity> recentMatches;
  final List<ProfileTeamEntity> residentTeams;

  const ProfileEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.englishName,
    this.image,
    this.countryFlag,
    this.country,
    this.channel,
    this.birthDate,
    this.commentaryLanguage,
    this.voiceUrl,
    this.role,
    this.capacity,
    this.builtDate,
    this.pitchSurface,
    this.city,
    this.mapUrl,
    this.currentTeam,
    this.career = const [],
    required this.sections,
    this.upcomingMatches = const [],
    this.recentMatches = const [],
    this.residentTeams = const [],
  });

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    englishName,
    image,
    countryFlag,
    country,
    channel,
    birthDate,
    commentaryLanguage,
    voiceUrl,
    role,
    capacity,
    builtDate,
    pitchSurface,
    city,
    mapUrl,
    currentTeam,
    career,
    sections,
    upcomingMatches,
    recentMatches,
    residentTeams,
  ];
}
