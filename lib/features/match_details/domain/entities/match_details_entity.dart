import 'package:equatable/equatable.dart';

class MatchEventEntity extends Equatable {
  final String minute;
  final String playerName;
  final String? secondaryPlayerName;
  final String
  type; // goal, yellow_card, red_card, substitution, var, start-end-match
  final bool isHomeTeam;
  final String? score;
  final String? videoUrl;

  const MatchEventEntity({
    required this.minute,
    required this.playerName,
    this.secondaryPlayerName,
    required this.type,
    this.isHomeTeam = true,
    this.score,
    this.videoUrl,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  MatchEventEntity copyWith({
    String? minute,
    String? playerName,
    String? secondaryPlayerName,
    String? type,
    bool? isHomeTeam,
    String? score,
    String? videoUrl,
  }) {
    return MatchEventEntity(
      minute: minute ?? this.minute,
      playerName: playerName ?? this.playerName,
      secondaryPlayerName: secondaryPlayerName ?? this.secondaryPlayerName,
      type: type ?? this.type,
      isHomeTeam: isHomeTeam ?? this.isHomeTeam,
      score: score ?? this.score,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => [
    minute,
    playerName,
    secondaryPlayerName,
    type,
    isHomeTeam,
    score,
    videoUrl,
  ];
}

class MatchStatItemEntity extends Equatable {
  final String title;
  final String homeValue;
  final String awayValue;
  final double homePercentage;
  final String? category;

  const MatchStatItemEntity({
    required this.title,
    required this.homeValue,
    required this.awayValue,
    required this.homePercentage,
    this.category,
  });

  @override
  List<Object?> get props => [
    title,
    homeValue,
    awayValue,
    homePercentage,
    category,
  ];
}

class MatchInfoSectionEntity extends Equatable {
  final String section;
  final List<MatchInfoItemEntity> items;

  const MatchInfoSectionEntity({required this.section, required this.items});

  @override
  List<Object?> get props => [section, items];
}

typedef MatchInfoEntity = MatchInfoItemEntity;

class MatchInfoItemEntity extends Equatable {
  final String title;
  final String content;
  final String? entityType; // 'stadium', 'referee', 'commentator'
  final String? entityId;
  final String? slug;
  final String? link;

  String? get id => entityId;

  const MatchInfoItemEntity({
    required this.title,
    required this.content,
    String? id,
    String? entityId,
    this.entityType,
    this.slug,
    this.link,
  }) : entityId = entityId ?? id;

  bool get canNavigate =>
      entityType != null &&
      content.trim().isNotEmpty &&
      content.trim() != '-' &&
      content.trim() != 'غير محدد' &&
      content.trim() != 'N/A';

  @override
  List<Object?> get props => [title, content, entityType, entityId, slug, link];
}

class MatchNewsItemEntity extends Equatable {
  final String title;
  final String? image;
  final String? link;
  final String? date;

  const MatchNewsItemEntity({
    required this.title,
    this.image,
    this.link,
    this.date,
  });

  @override
  List<Object?> get props => [title, image, link, date];
}

class MatchLineupEntity extends Equatable {
  final String matchId;
  final bool lineupsAvailable;
  final String? formationType; // 'confirmed', 'probable'
  final TeamLineupEntity? home;
  final TeamLineupEntity? away;

  const MatchLineupEntity({
    required this.matchId,
    required this.lineupsAvailable,
    this.formationType,
    this.home,
    this.away,
  });

  bool get isConfirmed => formationType?.toLowerCase() == 'confirmed';
  bool get hasLineups =>
      lineupsAvailable &&
      ((home != null && home!.startingXi.isNotEmpty) ||
          (away != null && away!.startingXi.isNotEmpty));

  @override
  List<Object?> get props => [
    matchId,
    lineupsAvailable,
    formationType,
    home,
    away,
  ];
}

class TeamLineupEntity extends Equatable {
  final String? teamId;
  final String? teamName;
  final String? teamLogo;
  final String? formation; // e.g. "4-3-3", "4-2-3-1"
  final LineupCoachEntity? coach;
  final List<LineupPlayerEntity> startingXi;
  final List<LineupPlayerEntity> substitutes;
  final List<LineupInjuryEntity> injuries;

  const TeamLineupEntity({
    this.teamId,
    this.teamName,
    this.teamLogo,
    this.formation,
    this.coach,
    this.startingXi = const [],
    this.substitutes = const [],
    this.injuries = const [],
  });

  /// Sanitizes team name by removing scraped prefixes/suffixes like
  /// "أخبار نادي" / "اخبار نادي" in Arabic or the word "news" in English.
  static String sanitizeTeamName(String? name) {
    if (name == null) return '';
    final cleaned = name
        .replaceAll(
          RegExp(r'(أ|ا|إ|آ)خبار\s+(نادي|النادي)\s*', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\s*\bnews\b\s*', caseSensitive: false),
          ' ',
        )
        .trim();
    return cleaned.isEmpty ? name : cleaned;
  }

  String get displayName => sanitizeTeamName(teamName);

  @override
  List<Object?> get props => [
    teamId,
    teamName,
    teamLogo,
    formation,
    coach,
    startingXi,
    substitutes,
    injuries,
  ];
}

class LineupPlayerEntity extends Equatable {
  final String? playerId;
  final String name;
  final int? number;
  final String? position;
  final String? positionCode; // "G", "D", "M", "F", "SUB"
  final int? formationPosition;
  final String? photo;
  final String? rating;
  final bool isCaptain;
  final bool isStarter;
  final bool isSubstitute;

  const LineupPlayerEntity({
    this.playerId,
    required this.name,
    this.number,
    this.position,
    this.positionCode,
    this.formationPosition,
    this.photo,
    this.rating,
    this.isCaptain = false,
    this.isStarter = true,
    this.isSubstitute = false,
  });

  bool get isGoalkeeper =>
      positionCode == 'G' ||
      position?.toLowerCase().contains('goal') == true ||
      position?.contains('حارس') == true;

  @override
  List<Object?> get props => [
    playerId,
    name,
    number,
    position,
    positionCode,
    formationPosition,
    photo,
    rating,
    isCaptain,
    isStarter,
    isSubstitute,
  ];
}

class LineupCoachEntity extends Equatable {
  final String? coachId;
  final String? name;
  final String? photo;
  final String? link;

  const LineupCoachEntity({
    this.coachId,
    this.name,
    this.photo,
    this.link,
  });

  @override
  List<Object?> get props => [coachId, name, photo, link];
}

class LineupInjuryEntity extends Equatable {
  final String? playerId;
  final String name;
  final int? number;
  final String? position;
  final String? photo;
  final String? absenceReason;
  final int? absenceTypeId;

  const LineupInjuryEntity({
    this.playerId,
    required this.name,
    this.number,
    this.position,
    this.photo,
    this.absenceReason,
    this.absenceTypeId,
  });

  @override
  List<Object?> get props => [
    playerId,
    name,
    number,
    position,
    photo,
    absenceReason,
    absenceTypeId,
  ];
}

