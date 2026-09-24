import 'package:equatable/equatable.dart';

import '../../../matches/domain/entities/match_entity.dart';
import '../../../standings/domain/entities/standings_entity.dart';

class TeamChampionshipEntity extends Equatable {
  final String id;
  final String? urlId;
  final String title;
  final String? logo;
  final int? type;
  final int? ranking;

  const TeamChampionshipEntity({
    required this.id,
    this.urlId,
    required this.title,
    this.logo,
    this.type,
    this.ranking,
  });

  @override
  List<Object?> get props => [id, urlId, title, logo, type, ranking];
}

class TeamCupEntity extends Equatable {
  final String title;
  final String? logo;
  final String? cupImage;
  final int count;
  final List<String> years;

  const TeamCupEntity({
    required this.title,
    this.logo,
    this.cupImage,
    required this.count,
    this.years = const [],
  });

  @override
  List<Object?> get props => [title, logo, cupImage, count, years];
}

class TeamCoachEntity extends Equatable {
  final String id;
  final String name;
  final String? photo;

  const TeamCoachEntity({required this.id, required this.name, this.photo});

  @override
  List<Object?> get props => [id, name, photo];
}

class TeamSquadPlayerEntity extends Equatable {
  final String id;
  final String name;
  final String? number;
  final String? position;
  final String? category;
  final String? photo;
  final String? url;

  const TeamSquadPlayerEntity({
    required this.id,
    required this.name,
    this.number,
    this.position,
    this.category,
    this.photo,
    this.url,
  });

  @override
  List<Object?> get props => [id, name, number, position, category, photo, url];
}

class TeamCategorizedSquadEntity extends Equatable {
  final TeamCoachEntity? coach;
  final List<TeamSquadPlayerEntity> goalkeepers;
  final List<TeamSquadPlayerEntity> defenders;
  final List<TeamSquadPlayerEntity> midfielders;
  final List<TeamSquadPlayerEntity> attackers;

  const TeamCategorizedSquadEntity({
    this.coach,
    this.goalkeepers = const [],
    this.defenders = const [],
    this.midfielders = const [],
    this.attackers = const [],
  });

  @override
  List<Object?> get props => [
    coach,
    goalkeepers,
    defenders,
    midfielders,
    attackers,
  ];
}

class TeamTransferPartyEntity extends Equatable {
  final String id;
  final String name;
  final String? logo;

  const TeamTransferPartyEntity({
    required this.id,
    required this.name,
    this.logo,
  });

  @override
  List<Object?> get props => [id, name, logo];
}

class TeamTransferItemEntity extends Equatable {
  final TeamSquadPlayerEntity player;
  final TeamTransferPartyEntity teamIn;
  final TeamTransferPartyEntity teamOut;
  final String value;
  final String type;
  final String? dateFrom;
  final String? dateTo;

  const TeamTransferItemEntity({
    required this.player,
    required this.teamIn,
    required this.teamOut,
    required this.value,
    required this.type,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [
    player,
    teamIn,
    teamOut,
    value,
    type,
    dateFrom,
    dateTo,
  ];
}

class TeamTransfersEntity extends Equatable {
  final List<TeamTransferItemEntity> important;
  final List<TeamTransferItemEntity> all;

  const TeamTransfersEntity({this.important = const [], this.all = const []});

  @override
  List<Object?> get props => [important, all];
}

class TeamNewsItemEntity extends Equatable {
  final String id;
  final String title;
  final String? slug;
  final String? description;
  final String? image;
  final String? createdAt;
  final String? url;

  const TeamNewsItemEntity({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    this.image,
    this.createdAt,
    this.url,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    slug,
    description,
    image,
    createdAt,
    url,
  ];
}

class TeamProfileEntity extends Equatable {
  final String teamId;
  final String teamName;
  final String? teamLogo;
  final String? leagueId;
  final String? leagueName;
  final String? country;
  final String? countryFlag;
  final String? countryCode;
  final String? about;
  final String? federation;
  final String? division;
  final String? stadiumId;
  final String? stadiumName;
  final int? worldRanking;
  final List<TeamChampionshipEntity> championships;
  final List<TeamCupEntity> cups;
  final List<MatchEntity> onlineMatches;
  final List<MatchEntity> upcomingMatches;
  final List<MatchEntity> recentMatches;
  final List<MatchEntity> postponedMatches;
  final StandingRowEntity? standingsRow;
  final List<String> form;
  final List<TeamSquadPlayerEntity> squad;
  final TeamCategorizedSquadEntity? categorizedSquad;
  final TeamTransfersEntity? transfers;
  final List<TeamNewsItemEntity> news;

  const TeamProfileEntity({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.leagueId,
    this.leagueName,
    this.country,
    this.countryFlag,
    this.countryCode,
    this.about,
    this.federation,
    this.division,
    this.stadiumId,
    this.stadiumName,
    this.worldRanking,
    this.championships = const [],
    this.cups = const [],
    this.onlineMatches = const [],
    this.upcomingMatches = const [],
    this.recentMatches = const [],
    this.postponedMatches = const [],
    this.standingsRow,
    this.form = const [],
    this.squad = const [],
    this.categorizedSquad,
    this.transfers,
    this.news = const [],
  });

  @override
  List<Object?> get props => [
    teamId,
    teamName,
    teamLogo,
    leagueId,
    leagueName,
    country,
    countryFlag,
    countryCode,
    about,
    federation,
    division,
    stadiumId,
    stadiumName,
    worldRanking,
    championships,
    cups,
    onlineMatches,
    upcomingMatches,
    recentMatches,
    postponedMatches,
    standingsRow,
    form,
    squad,
    categorizedSquad,
    transfers,
    news,
  ];
}
