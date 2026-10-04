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
  final String? playerId;
  final int? playerNumber;
  final String? playerPhoto;
  final String? playerShortName;
  final String? secondaryPlayerId;
  final int? secondaryPlayerNumber;
  final String? secondaryPlayerPhoto;
  final String? secondaryPlayerShortName;
  final bool isPeriodMarker;

  const MatchEventEntity({
    required this.minute,
    required this.playerName,
    this.secondaryPlayerName,
    required this.type,
    this.isHomeTeam = true,
    this.score,
    this.videoUrl,
    this.playerId,
    this.playerNumber,
    this.playerPhoto,
    this.playerShortName,
    this.secondaryPlayerId,
    this.secondaryPlayerNumber,
    this.secondaryPlayerPhoto,
    this.secondaryPlayerShortName,
    this.isPeriodMarker = false,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;
  bool get isHome => isHomeTeam;

  MatchEventEntity copyWith({
    String? minute,
    String? playerName,
    String? secondaryPlayerName,
    String? type,
    bool? isHomeTeam,
    String? score,
    String? videoUrl,
    String? playerId,
    int? playerNumber,
    String? playerPhoto,
    String? playerShortName,
    String? secondaryPlayerId,
    int? secondaryPlayerNumber,
    String? secondaryPlayerPhoto,
    String? secondaryPlayerShortName,
    bool? isPeriodMarker,
  }) {
    return MatchEventEntity(
      minute: minute ?? this.minute,
      playerName: playerName ?? this.playerName,
      secondaryPlayerName: secondaryPlayerName ?? this.secondaryPlayerName,
      type: type ?? this.type,
      isHomeTeam: isHomeTeam ?? this.isHomeTeam,
      score: score ?? this.score,
      videoUrl: videoUrl ?? this.videoUrl,
      playerId: playerId ?? this.playerId,
      playerNumber: playerNumber ?? this.playerNumber,
      playerPhoto: playerPhoto ?? this.playerPhoto,
      playerShortName: playerShortName ?? this.playerShortName,
      secondaryPlayerId: secondaryPlayerId ?? this.secondaryPlayerId,
      secondaryPlayerNumber:
          secondaryPlayerNumber ?? this.secondaryPlayerNumber,
      secondaryPlayerPhoto: secondaryPlayerPhoto ?? this.secondaryPlayerPhoto,
      secondaryPlayerShortName:
          secondaryPlayerShortName ?? this.secondaryPlayerShortName,
      isPeriodMarker: isPeriodMarker ?? this.isPeriodMarker,
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
    playerId,
    playerNumber,
    playerPhoto,
    playerShortName,
    secondaryPlayerId,
    secondaryPlayerNumber,
    secondaryPlayerPhoto,
    secondaryPlayerShortName,
    isPeriodMarker,
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
  final String? description;
  final String? articleId;
  final String? slug;

  const MatchNewsItemEntity({
    required this.title,
    this.image,
    this.link,
    this.date,
    this.description,
    this.articleId,
    this.slug,
  });

  @override
  List<Object?> get props => [
    title,
    image,
    link,
    date,
    description,
    articleId,
    slug,
  ];
}

class MatchLineupEntity extends Equatable {
  final String matchId;
  final bool lineupsAvailable;
  final String? formationType; // 'confirmed', 'probable'
  final int? formationTypeId; // 0 = confirmed, 2 = probable
  final String? formationTypeText; // 'تشكيلة مؤكدة' / 'Confirmed Lineup'
  final bool? isConfirmed;
  final TeamLineupEntity? home;
  final TeamLineupEntity? away;

  const MatchLineupEntity({
    required this.matchId,
    required this.lineupsAvailable,
    this.formationType,
    this.formationTypeId,
    this.formationTypeText,
    this.isConfirmed,
    this.home,
    this.away,
  });

  bool get isConfirmedLineup {
    if (isConfirmed != null) return isConfirmed!;
    if (formationTypeId == 2 ||
        formationType?.toLowerCase() == 'probable' ||
        formationType?.toLowerCase() == 'predicted') {
      return false;
    }
    return formationTypeId == 0 || formationType?.toLowerCase() == 'confirmed';
  }

  bool get hasLineups =>
      lineupsAvailable &&
      ((home != null && home!.startingXi.isNotEmpty) ||
          (away != null && away!.startingXi.isNotEmpty));

  MatchLineupEntity copyWith({
    String? matchId,
    bool? lineupsAvailable,
    String? formationType,
    int? formationTypeId,
    String? formationTypeText,
    bool? isConfirmed,
    TeamLineupEntity? home,
    TeamLineupEntity? away,
  }) {
    return MatchLineupEntity(
      matchId: matchId ?? this.matchId,
      lineupsAvailable: lineupsAvailable ?? this.lineupsAvailable,
      formationType: formationType ?? this.formationType,
      formationTypeId: formationTypeId ?? this.formationTypeId,
      formationTypeText: formationTypeText ?? this.formationTypeText,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      home: home ?? this.home,
      away: away ?? this.away,
    );
  }

  @override
  List<Object?> get props => [
    matchId,
    lineupsAvailable,
    formationType,
    formationTypeId,
    formationTypeText,
    isConfirmed,
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

  TeamLineupEntity copyWith({
    String? teamId,
    String? teamName,
    String? teamLogo,
    String? formation,
    LineupCoachEntity? coach,
    List<LineupPlayerEntity>? startingXi,
    List<LineupPlayerEntity>? substitutes,
    List<LineupInjuryEntity>? injuries,
  }) {
    return TeamLineupEntity(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamLogo: teamLogo ?? this.teamLogo,
      formation: formation ?? this.formation,
      coach: coach ?? this.coach,
      startingXi: startingXi ?? this.startingXi,
      substitutes: substitutes ?? this.substitutes,
      injuries: injuries ?? this.injuries,
    );
  }

  /// Sanitizes team name by removing scraped prefixes/suffixes like
  /// "أخبار نادي" / "اخبار نادي" in Arabic or the word "news" in English.
  static String sanitizeTeamName(String? name) {
    if (name == null) return '';
    final cleaned = name
        .replaceAll(
          RegExp(r'(أ|ا|إ|آ)خبار\s+(نادي|النادي)\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s*\bnews\b\s*', caseSensitive: false), ' ')
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
  final String? shortName;
  final int? number;
  final String? position;
  final String? positionCode; // "G", "D", "M", "F", "SUB"
  final String?
  detailedPosition; // "GK", "RB", "CB", "LB", "CDM", "CM", "RW", "LW", "CF"
  final int? formationPosition;
  final String? photo;
  final String? rating;
  final bool isCaptain;
  final bool isStarter;
  final bool isSubstitute;
  final bool isManOfMatch;
  final int yellowCards;
  final int redCards;
  final int goals;
  final int ownGoals;
  final int assists;
  final bool substituteIn;
  final bool substituteOut;
  final int? substituteTime;
  final int? substitutePlus;
  final String? subbedForName;
  final String? subbedForId;

  const LineupPlayerEntity({
    this.playerId,
    required this.name,
    this.shortName,
    this.number,
    this.position,
    this.positionCode,
    this.detailedPosition,
    this.formationPosition,
    this.photo,
    this.rating,
    this.isCaptain = false,
    this.isStarter = true,
    this.isSubstitute = false,
    this.isManOfMatch = false,
    this.yellowCards = 0,
    this.redCards = 0,
    this.goals = 0,
    this.ownGoals = 0,
    this.assists = 0,
    this.substituteIn = false,
    this.substituteOut = false,
    this.substituteTime,
    this.substitutePlus,
    this.subbedForName,
    this.subbedForId,
  });

  String? get id => playerId;

  String get displayName => (shortName != null && shortName!.trim().isNotEmpty)
      ? shortName!.trim()
      : name;

  bool get isGoalkeeper =>
      positionCode == 'G' ||
      position?.toLowerCase().contains('goal') == true ||
      position?.contains('حارس') == true;

  LineupPlayerEntity copyWith({
    String? playerId,
    String? name,
    String? shortName,
    int? number,
    String? position,
    String? positionCode,
    String? detailedPosition,
    int? formationPosition,
    String? photo,
    String? rating,
    bool? isCaptain,
    bool? isStarter,
    bool? isSubstitute,
    bool? isManOfMatch,
    int? yellowCards,
    int? redCards,
    int? goals,
    int? ownGoals,
    int? assists,
    bool? substituteIn,
    bool? substituteOut,
    int? substituteTime,
    int? substitutePlus,
    String? subbedForName,
    String? subbedForId,
  }) {
    return LineupPlayerEntity(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      number: number ?? this.number,
      position: position ?? this.position,
      positionCode: positionCode ?? this.positionCode,
      detailedPosition: detailedPosition ?? this.detailedPosition,
      formationPosition: formationPosition ?? this.formationPosition,
      photo: photo ?? this.photo,
      rating: rating ?? this.rating,
      isCaptain: isCaptain ?? this.isCaptain,
      isStarter: isStarter ?? this.isStarter,
      isSubstitute: isSubstitute ?? this.isSubstitute,
      isManOfMatch: isManOfMatch ?? this.isManOfMatch,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      goals: goals ?? this.goals,
      ownGoals: ownGoals ?? this.ownGoals,
      assists: assists ?? this.assists,
      substituteIn: substituteIn ?? this.substituteIn,
      substituteOut: substituteOut ?? this.substituteOut,
      substituteTime: substituteTime ?? this.substituteTime,
      substitutePlus: substitutePlus ?? this.substitutePlus,
      subbedForName: subbedForName ?? this.subbedForName,
      subbedForId: subbedForId ?? this.subbedForId,
    );
  }

  @override
  List<Object?> get props => [
    playerId,
    name,
    shortName,
    number,
    position,
    positionCode,
    detailedPosition,
    formationPosition,
    photo,
    rating,
    isCaptain,
    isStarter,
    isSubstitute,
    isManOfMatch,
    yellowCards,
    redCards,
    goals,
    ownGoals,
    assists,
    substituteIn,
    substituteOut,
    substituteTime,
    substitutePlus,
    subbedForName,
    subbedForId,
  ];
}

class LineupCoachEntity extends Equatable {
  final String? coachId;
  final String? name;
  final String? photo;
  final String? link;

  const LineupCoachEntity({this.coachId, this.name, this.photo, this.link});

  @override
  List<Object?> get props => [coachId, name, photo, link];
}

class LineupInjuryEntity extends Equatable {
  final String? playerId;
  final String name;
  final String? shortName;
  final int? number;
  final String? position;
  final String? photo;
  final String? absenceReason;
  final int? absenceTypeId;

  const LineupInjuryEntity({
    this.playerId,
    required this.name,
    this.shortName,
    this.number,
    this.position,
    this.photo,
    this.absenceReason,
    this.absenceTypeId,
  });

  String get displayName => (shortName != null && shortName!.trim().isNotEmpty)
      ? shortName!.trim()
      : name;

  @override
  List<Object?> get props => [
    playerId,
    name,
    shortName,
    number,
    position,
    photo,
    absenceReason,
    absenceTypeId,
  ];
}

class MatchVideoItemEntity extends Equatable {
  final String title;
  final String url;
  final String?
  type; // 'summary', 'goals', 'full_match', 'alternative_summary', 'goal_clip'
  final String? minute;
  final String? playerName;

  const MatchVideoItemEntity({
    required this.title,
    required this.url,
    this.type,
    this.minute,
    this.playerName,
  });

  @override
  List<Object?> get props => [title, url, type, minute, playerName];
}

class MatchVideosEntity extends Equatable {
  final bool hasVideo;
  final MatchVideoItemEntity? summary;
  final MatchVideoItemEntity? goals;
  final MatchVideoItemEntity? fullMatch;
  final List<MatchVideoItemEntity> videoLinks;
  final List<MatchVideoItemEntity> goalClips;

  const MatchVideosEntity({
    this.hasVideo = false,
    this.summary,
    this.goals,
    this.fullMatch,
    this.videoLinks = const [],
    this.goalClips = const [],
  });

  /// All unique video items ready to display as chips or in a gallery
  List<MatchVideoItemEntity> get allChips {
    if (!hasVideo) return const [];
    final list = <MatchVideoItemEntity>[];
    final seenUrls = <String>{};

    void add(MatchVideoItemEntity? item) {
      if (item != null &&
          item.url.trim().isNotEmpty &&
          !seenUrls.contains(item.url.trim())) {
        seenUrls.add(item.url.trim());
        list.add(item);
      }
    }

    add(summary);
    add(goals);
    add(fullMatch);
    for (final vl in videoLinks) {
      add(vl);
    }
    for (final gc in goalClips) {
      add(gc);
    }
    return list;
  }

  bool get isEmpty => !hasVideo || allChips.isEmpty;
  bool get isNotEmpty => hasVideo && allChips.isNotEmpty;

  static MatchVideosEntity fromJson(dynamic json, {bool isArabic = true}) {
    if (json == null) return const MatchVideosEntity();

    Map<String, dynamic>? itemsMap;
    if (json is Map) {
      if (json['videos'] is Map ||
          json['match_summary'] != null ||
          json['has_video'] != null ||
          json['hasVideo'] != null) {
        itemsMap = Map<String, dynamic>.from(json);
      } else if (json['items'] is Map) {
        itemsMap = Map<String, dynamic>.from(json['items']);
      } else if (json['data'] is List && (json['data'] as List).isNotEmpty) {
        final first = (json['data'] as List).first;
        if (first is Map && first['items'] is Map) {
          itemsMap = Map<String, dynamic>.from(first['items']);
        } else if (first is Map) {
          itemsMap = Map<String, dynamic>.from(first);
        }
      } else if (json['data'] is Map) {
        final dataMap = Map<String, dynamic>.from(json['data']);
        if (dataMap['items'] is Map) {
          itemsMap = Map<String, dynamic>.from(dataMap['items']);
        } else {
          itemsMap = dataMap;
        }
      }
    } else if (json is List && json.isNotEmpty) {
      final first = json.first;
      if (first is Map && first['items'] is Map) {
        itemsMap = Map<String, dynamic>.from(first['items']);
      }
    }

    if (itemsMap == null) return const MatchVideosEntity();

    final videosContainer = itemsMap['videos'] is Map
        ? itemsMap['videos'] as Map
        : null;

    final explicitHasVideo =
        itemsMap['has_video'] ??
        itemsMap['hasVideo'] ??
        videosContainer?['has_video'] ??
        videosContainer?['hasVideo'];

    final bool isExplicitlyDisabled =
        (explicitHasVideo is bool && !explicitHasVideo) ||
        explicitHasVideo == 'false' ||
        explicitHasVideo == 0 ||
        explicitHasVideo == '0';

    if (isExplicitlyDisabled) {
      return const MatchVideosEntity(hasVideo: false);
    }

    final bool isExplicitlyEnabled =
        (explicitHasVideo is bool && explicitHasVideo) ||
        explicitHasVideo == 'true' ||
        explicitHasVideo == 1 ||
        explicitHasVideo == '1' ||
        itemsMap['video'] == 1 ||
        itemsMap['video'] == '1' ||
        itemsMap['video'] == true;

    MatchVideoItemEntity? parseItem(dynamic obj, {String? defaultTitle}) {
      if (obj == null) return null;
      if (obj is Map) {
        final url =
            (obj['url'] ?? obj['video_link'] ?? obj['video_url'] ?? obj['link'])
                ?.toString();
        if (url == null ||
            url.trim().isEmpty ||
            url == 'null' ||
            url == 'undefined') {
          return null;
        }
        final title =
            (obj['title'] ?? obj['name'] ?? defaultTitle)?.toString() ??
            defaultTitle ??
            '';
        return MatchVideoItemEntity(
          title: title.isNotEmpty ? title : (defaultTitle ?? ''),
          url: url.trim(),
          type: obj['category']?.toString() ?? obj['type']?.toString(),
          minute: obj['minute']?.toString() ?? obj['time']?.toString(),
          playerName:
              obj['player_name']?.toString() ?? obj['player']?.toString(),
        );
      }
      if (obj is String &&
          obj.trim().isNotEmpty &&
          obj != 'null' &&
          obj != 'undefined') {
        return MatchVideoItemEntity(
          title: defaultTitle ?? (isArabic ? 'فيديو' : 'Video'),
          url: obj.trim(),
        );
      }
      return null;
    }

    final summary = parseItem(
      videosContainer?['summary'] ?? itemsMap['match_summary'],
      defaultTitle: isArabic ? 'ملخص المباراة' : 'Match Highlights',
    );

    final goals = parseItem(
      videosContainer?['goals'] ?? itemsMap['match_goals'],
      defaultTitle: isArabic ? 'أهداف المباراة' : 'Match Goals',
    );

    final fullMatch = parseItem(
      videosContainer?['full_match'] ?? itemsMap['full_match'],
      defaultTitle: isArabic ? 'المباراة كاملة' : 'Full Match',
    );

    final videoLinks = <MatchVideoItemEntity>[];
    final rawLinks =
        (videosContainer?['all'] ?? itemsMap['video_links']) as List?;
    if (rawLinks != null) {
      for (final l in rawLinks) {
        final item = parseItem(l);
        if (item != null) videoLinks.add(item);
      }
    }

    final goalClips = <MatchVideoItemEntity>[];
    final rawClips =
        (videosContainer?['goal_clips'] ?? itemsMap['goal_clips']) as List?;
    if (rawClips != null) {
      for (final c in rawClips) {
        if (c is Map) {
          final pName =
              c['player_name']?.toString() ?? c['player']?.toString() ?? '';
          final timeStr =
              c['time']?.toString() ??
              (c['minute'] != null ? "${c['minute']}'" : '');
          final clipTitle = isArabic
              ? (pName.isNotEmpty
                    ? 'هدف: $pName${timeStr.isNotEmpty ? ' ($timeStr)' : ''}'
                    : 'هدف $timeStr')
              : (pName.isNotEmpty
                    ? 'Goal: $pName${timeStr.isNotEmpty ? ' ($timeStr)' : ''}'
                    : 'Goal $timeStr');
          final item = parseItem(c, defaultTitle: clipTitle);
          if (item != null) goalClips.add(item);
        }
      }
    }

    final resolvedHasVideo =
        isExplicitlyEnabled ||
        summary != null ||
        goals != null ||
        videoLinks.isNotEmpty ||
        goalClips.isNotEmpty;

    if (!resolvedHasVideo) {
      return const MatchVideosEntity(hasVideo: false);
    }

    return MatchVideosEntity(
      hasVideo: true,
      summary: summary,
      goals: goals,
      fullMatch: fullMatch,
      videoLinks: videoLinks,
      goalClips: goalClips,
    );
  }

  @override
  List<Object?> get props => [
    hasVideo,
    summary,
    goals,
    fullMatch,
    videoLinks,
    goalClips,
  ];
}

class MatchEventsPayload extends Equatable {
  final List<MatchEventEntity> events;
  final MatchVideosEntity videos;
  final String? championshipId;
  final Map<String, dynamic>? halfScores;

  const MatchEventsPayload({
    this.events = const [],
    this.videos = const MatchVideosEntity(),
    this.championshipId,
    this.halfScores,
  });

  @override
  List<Object?> get props => [events, videos, championshipId, halfScores];
}

class MatchH2HSummaryEntity extends Equatable {
  final int homeWins;
  final int awayWins;
  final int draws;
  final String? homeTeamName;
  final String? awayTeamName;

  const MatchH2HSummaryEntity({
    required this.homeWins,
    required this.awayWins,
    required this.draws,
    this.homeTeamName,
    this.awayTeamName,
  });

  int get totalMatches => homeWins + awayWins + draws;

  double get homeWinRatio => totalMatches > 0 ? homeWins / totalMatches : 0.0;
  double get drawRatio => totalMatches > 0 ? draws / totalMatches : 0.0;
  double get awayWinRatio => totalMatches > 0 ? awayWins / totalMatches : 0.0;

  @override
  List<Object?> get props => [
    homeWins,
    awayWins,
    draws,
    homeTeamName,
    awayTeamName,
  ];
}

class MatchFormItemEntity extends Equatable {
  final String matchId;
  final String opponentName;
  final String? opponentLogo;
  final String score;
  final String winType; // 'win', 'lose', 'equal'
  final bool isHome;

  const MatchFormItemEntity({
    required this.matchId,
    required this.opponentName,
    this.opponentLogo,
    required this.score,
    required this.winType,
    this.isHome = true,
  });

  bool get isWin => winType.toLowerCase() == 'win';
  bool get isDraw =>
      winType.toLowerCase() == 'equal' || winType.toLowerCase() == 'draw';
  bool get isLoss =>
      winType.toLowerCase() == 'lose' || winType.toLowerCase() == 'loss';

  @override
  List<Object?> get props => [
    matchId,
    opponentName,
    opponentLogo,
    score,
    winType,
    isHome,
  ];
}

class MatchRecentFormEntity extends Equatable {
  final List<MatchFormItemEntity> homeMatches;
  final List<MatchFormItemEntity> awayMatches;
  final String? homeTeamName;
  final String? awayTeamName;

  const MatchRecentFormEntity({
    this.homeMatches = const [],
    this.awayMatches = const [],
    this.homeTeamName,
    this.awayTeamName,
  });

  @override
  List<Object?> get props => [
    homeMatches,
    awayMatches,
    homeTeamName,
    awayTeamName,
  ];
}

class MatchReturnLegEntity extends Equatable {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final int homeScores;
  final int awayScores;
  final String? aggResult;
  final String? penalties;

  const MatchReturnLegEntity({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScores,
    required this.awayScores,
    this.aggResult,
    this.penalties,
  });

  String get scoreText => '$homeScores - $awayScores';

  @override
  List<Object?> get props => [
    matchId,
    homeTeam,
    awayTeam,
    homeScores,
    awayScores,
    aggResult,
    penalties,
  ];
}

class MatchQuickStatsEntity extends Equatable {
  final String? homePossession;
  final String? awayPossession;
  final int? homeShots;
  final int? awayShots;
  final int? homeFouls;
  final int? awayFouls;
  final int? homeOffsides;
  final int? awayOffsides;

  const MatchQuickStatsEntity({
    this.homePossession,
    this.awayPossession,
    this.homeShots,
    this.awayShots,
    this.homeFouls,
    this.awayFouls,
    this.homeOffsides,
    this.awayOffsides,
  });

  bool get isEmpty =>
      homePossession == null &&
      awayPossession == null &&
      homeShots == null &&
      awayShots == null &&
      homeFouls == null &&
      awayFouls == null &&
      homeOffsides == null &&
      awayOffsides == null;

  @override
  List<Object?> get props => [
    homePossession,
    awayPossession,
    homeShots,
    awayShots,
    homeFouls,
    awayFouls,
    homeOffsides,
    awayOffsides,
  ];
}

class MatchRefereeItemEntity extends Equatable {
  final String? id;
  final String name;
  final String role;

  const MatchRefereeItemEntity({
    this.id,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [id, name, role];
}

class MatchOverviewDataEntity extends Equatable {
  final String matchId;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final String? homeTeamId;
  final String? awayTeamId;
  final String? championshipId;
  final String? championshipTitle;
  final String? championshipLogo;
  final String? score1;
  final String? score2;
  final String? status;
  final String? statusCode;
  final String? note;
  final String? time;
  final String? date;
  final String? round;
  final String? stadiumName;
  final String? stadiumId;
  final MatchReturnLegEntity? returnLeg;
  final MatchH2HSummaryEntity? h2hSummary;
  final MatchRecentFormEntity? recentForm;
  final MatchQuickStatsEntity? quickStats;
  final List<MatchRefereeItemEntity> referees;
  final List<MatchInfoItemEntity> channels;

  const MatchOverviewDataEntity({
    required this.matchId,
    this.homeTeamName,
    this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeTeamId,
    this.awayTeamId,
    this.championshipId,
    this.championshipTitle,
    this.championshipLogo,
    this.score1,
    this.score2,
    this.status,
    this.statusCode,
    this.note,
    this.time,
    this.date,
    this.round,
    this.stadiumName,
    this.stadiumId,
    this.returnLeg,
    this.h2hSummary,
    this.recentForm,
    this.quickStats,
    this.referees = const [],
    this.channels = const [],
  });

  @override
  List<Object?> get props => [
    matchId,
    homeTeamName,
    awayTeamName,
    homeTeamLogo,
    awayTeamLogo,
    homeTeamId,
    awayTeamId,
    championshipId,
    championshipTitle,
    championshipLogo,
    score1,
    score2,
    status,
    statusCode,
    note,
    time,
    date,
    round,
    stadiumName,
    stadiumId,
    returnLeg,
    h2hSummary,
    recentForm,
    quickStats,
    referees,
    channels,
  ];
}

class MatchDetailsPayload extends Equatable {
  final List<MatchInfoSectionEntity> sections;
  final MatchOverviewDataEntity? overview;

  const MatchDetailsPayload({this.sections = const [], this.overview});

  @override
  List<Object?> get props => [sections, overview];
}
