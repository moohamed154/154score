import 'package:equatable/equatable.dart';

class PlayerTeamEntity extends Equatable {
  final String id;
  final String name;
  final String fullName;
  final String? logo;
  final int worldRanking;

  const PlayerTeamEntity({
    required this.id,
    required this.name,
    required this.fullName,
    this.logo,
    this.worldRanking = 0,
  });

  @override
  List<Object?> get props => [id, name, fullName, logo, worldRanking];
}

class PlayerCountryEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? flag;

  const PlayerCountryEntity({
    required this.id,
    required this.name,
    required this.code,
    this.flag,
  });

  @override
  List<Object?> get props => [id, name, code, flag];
}

class PlayerLeagueEntity extends Equatable {
  final String id;
  final String? seasonId;
  final String name;
  final String? logo;
  final String? logoLight;
  final int? type;
  final int? ranking;
  final bool followed;

  const PlayerLeagueEntity({
    required this.id,
    this.seasonId,
    required this.name,
    this.logo,
    this.logoLight,
    this.type,
    this.ranking,
    this.followed = false,
  });

  @override
  List<Object?> get props => [
    id,
    seasonId,
    name,
    logo,
    logoLight,
    type,
    ranking,
    followed,
  ];
}

class PlayerStatisticEntity extends Equatable {
  final PlayerLeagueEntity league;
  final int appearances;
  final int goals;
  final int assists;
  final int scorePenalty;
  final int missPenalty;
  final int cancelGoal;
  final int ownGoal;
  final int yellowCards;
  final int redCards;
  final int cleanSheets;
  final int manOfMatch;

  const PlayerStatisticEntity({
    required this.league,
    this.appearances = 0,
    this.goals = 0,
    this.assists = 0,
    this.scorePenalty = 0,
    this.missPenalty = 0,
    this.cancelGoal = 0,
    this.ownGoal = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.cleanSheets = 0,
    this.manOfMatch = 0,
  });

  @override
  List<Object?> get props => [
    league,
    appearances,
    goals,
    assists,
    scorePenalty,
    missPenalty,
    cancelGoal,
    ownGoal,
    yellowCards,
    redCards,
    cleanSheets,
    manOfMatch,
  ];
}

class PlayerTransferEntity extends Equatable {
  final PlayerTeamEntity? team;
  final String type;
  final String fee;
  final String rawFee;
  final bool important;
  final bool active;
  final String? dateFrom;
  final String? dateTo;
  final String season;

  const PlayerTransferEntity({
    this.team,
    required this.type,
    required this.fee,
    required this.rawFee,
    this.important = false,
    this.active = false,
    this.dateFrom,
    this.dateTo,
    required this.season,
  });

  @override
  List<Object?> get props => [
    team,
    type,
    fee,
    rawFee,
    important,
    active,
    dateFrom,
    dateTo,
    season,
  ];
}

class PlayerProfileEntity extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? photo;
  final String? cover;
  final PlayerTeamEntity? team;
  final PlayerCountryEntity? country;
  final int? clubNumber;
  final int? interNumber;
  final int? height;
  final int? weight;
  final String? birthDay;
  final int? age;
  final String? position;
  final String positionName;
  final String? foot;
  final String? footName;
  final String? city;
  final bool retired;
  final bool died;
  final int playerStatus;
  final List<PlayerStatisticEntity> statistics;
  final List<PlayerTransferEntity> transfers;
  final List<Map<String, String>> metadata;
  final String? url;

  const PlayerProfileEntity({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.photo,
    this.cover,
    this.team,
    this.country,
    this.clubNumber,
    this.interNumber,
    this.height,
    this.weight,
    this.birthDay,
    this.age,
    this.position,
    this.positionName = '',
    this.foot,
    this.footName,
    this.city,
    this.retired = false,
    this.died = false,
    this.playerStatus = 1,
    this.statistics = const [],
    this.transfers = const [],
    this.metadata = const [],
    this.url,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    nameAr,
    nameEn,
    photo,
    cover,
    team,
    country,
    clubNumber,
    interNumber,
    height,
    weight,
    birthDay,
    age,
    position,
    positionName,
    foot,
    footName,
    city,
    retired,
    died,
    playerStatus,
    statistics,
    transfers,
    metadata,
    url,
  ];
}
