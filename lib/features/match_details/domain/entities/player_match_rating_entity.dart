import 'package:equatable/equatable.dart';

class PlayerRatingMetric extends Equatable {
  final int percent;
  final int success;
  final int total;

  const PlayerRatingMetric({
    this.percent = 0,
    this.success = 0,
    this.total = 0,
  });

  factory PlayerRatingMetric.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingMetric();
    return PlayerRatingMetric(
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      success: (json['success'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [percent, success, total];
}

class PlayerRatingDuels extends Equatable {
  final int won;
  final int lost;
  final int total;

  const PlayerRatingDuels({
    this.won = 0,
    this.lost = 0,
    this.total = 0,
  });

  factory PlayerRatingDuels.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingDuels();
    return PlayerRatingDuels(
      won: (json['won'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [won, lost, total];
}

class PlayerRatingInfo extends Equatable {
  final String id;
  final String name;
  final int? number;
  final String? position;
  final String? positionTitle;
  final String? rating;
  final String? photo;
  final String? teamId;

  const PlayerRatingInfo({
    required this.id,
    required this.name,
    this.number,
    this.position,
    this.positionTitle,
    this.rating,
    this.photo,
    this.teamId,
  });

  factory PlayerRatingInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PlayerRatingInfo(id: '', name: '');
    }
    return PlayerRatingInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt(),
      position: json['position']?.toString(),
      positionTitle: json['position_title']?.toString(),
      rating: json['rating']?.toString(),
      photo: json['photo']?.toString() ?? json['image']?.toString(),
      teamId: json['team_id']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        number,
        position,
        positionTitle,
        rating,
        photo,
        teamId,
      ];
}

class PlayerRatingHighlights extends Equatable {
  final int goals;
  final int assists;
  final int keyPasses;
  final int bigChances;

  const PlayerRatingHighlights({
    this.goals = 0,
    this.assists = 0,
    this.keyPasses = 0,
    this.bigChances = 0,
  });

  factory PlayerRatingHighlights.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingHighlights();
    return PlayerRatingHighlights(
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      keyPasses: (json['key_passes'] as num?)?.toInt() ?? 0,
      bigChances: (json['big_chances'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [goals, assists, keyPasses, bigChances];
}

class PlayerRatingPassing extends Equatable {
  final PlayerRatingMetric accuracy;
  final PlayerRatingMetric crosses;
  final PlayerRatingMetric longBalls;
  final int keyPasses;
  final int finalThird;
  final int backward;

  const PlayerRatingPassing({
    this.accuracy = const PlayerRatingMetric(),
    this.crosses = const PlayerRatingMetric(),
    this.longBalls = const PlayerRatingMetric(),
    this.keyPasses = 0,
    this.finalThird = 0,
    this.backward = 0,
  });

  factory PlayerRatingPassing.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingPassing();
    return PlayerRatingPassing(
      accuracy: PlayerRatingMetric.fromJson(
        json['accuracy'] is Map ? json['accuracy'] as Map<String, dynamic> : null,
      ),
      crosses: PlayerRatingMetric.fromJson(
        json['crosses'] is Map ? json['crosses'] as Map<String, dynamic> : null,
      ),
      longBalls: PlayerRatingMetric.fromJson(
        json['long_balls'] is Map
            ? json['long_balls'] as Map<String, dynamic>
            : null,
      ),
      keyPasses: (json['key_passes'] as num?)?.toInt() ?? 0,
      finalThird: (json['final_third'] as num?)?.toInt() ?? 0,
      backward: (json['backward'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        accuracy,
        crosses,
        longBalls,
        keyPasses,
        finalThird,
        backward,
      ];
}

class PlayerRatingShooting extends Equatable {
  final int bigChances;
  final int onTarget;
  final int offTarget;
  final int woodwork;

  const PlayerRatingShooting({
    this.bigChances = 0,
    this.onTarget = 0,
    this.offTarget = 0,
    this.woodwork = 0,
  });

  factory PlayerRatingShooting.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingShooting();
    return PlayerRatingShooting(
      bigChances: (json['big_chances'] as num?)?.toInt() ?? 0,
      onTarget: (json['on_target'] as num?)?.toInt() ?? 0,
      offTarget: (json['off_target'] as num?)?.toInt() ?? 0,
      woodwork: (json['woodwork'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [bigChances, onTarget, offTarget, woodwork];
}

class PlayerRatingDribblesDuels extends Equatable {
  final PlayerRatingMetric dribbles;
  final PlayerRatingDuels duels;
  final int dribbledPast;

  const PlayerRatingDribblesDuels({
    this.dribbles = const PlayerRatingMetric(),
    this.duels = const PlayerRatingDuels(),
    this.dribbledPast = 0,
  });

  factory PlayerRatingDribblesDuels.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingDribblesDuels();
    return PlayerRatingDribblesDuels(
      dribbles: PlayerRatingMetric.fromJson(
        json['dribbles'] is Map
            ? json['dribbles'] as Map<String, dynamic>
            : null,
      ),
      duels: PlayerRatingDuels.fromJson(
        json['duels'] is Map ? json['duels'] as Map<String, dynamic> : null,
      ),
      dribbledPast: (json['dribbled_past'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [dribbles, duels, dribbledPast];
}

class PlayerRatingStatItem extends Equatable {
  final int? id;
  final String code;
  final String title;
  final dynamic value;

  const PlayerRatingStatItem({
    this.id,
    required this.code,
    required this.title,
    required this.value,
  });

  factory PlayerRatingStatItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PlayerRatingStatItem(code: '', title: '', value: 0);
    }
    return PlayerRatingStatItem(
      id: (json['id'] as num?)?.toInt(),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: json['value'],
    );
  }

  @override
  List<Object?> get props => [id, code, title, value];
}

class PlayerMatchRatingEntity extends Equatable {
  final String matchId;
  final PlayerRatingInfo player;
  final PlayerRatingHighlights highlights;
  final PlayerRatingPassing passing;
  final PlayerRatingShooting shooting;
  final PlayerRatingDribblesDuels dribblesDuels;
  final List<PlayerRatingStatItem> statistics;

  const PlayerMatchRatingEntity({
    required this.matchId,
    required this.player,
    this.highlights = const PlayerRatingHighlights(),
    this.passing = const PlayerRatingPassing(),
    this.shooting = const PlayerRatingShooting(),
    this.dribblesDuels = const PlayerRatingDribblesDuels(),
    this.statistics = const [],
  });

  factory PlayerMatchRatingEntity.fromJson(Map<String, dynamic> json) {
    final rawPlayer = json['player'] is Map ? json['player'] as Map<String, dynamic> : null;
    final rawHighlights = json['highlights'] is Map ? json['highlights'] as Map<String, dynamic> : null;
    final rawPassing = json['passing'] is Map ? json['passing'] as Map<String, dynamic> : null;
    final rawShooting = json['shooting'] is Map ? json['shooting'] as Map<String, dynamic> : null;
    final rawDribbles = json['dribbles_duels'] is Map ? json['dribbles_duels'] as Map<String, dynamic> : null;

    final statsList = <PlayerRatingStatItem>[];
    if (json['statistics'] is List) {
      for (final s in json['statistics'] as List) {
        if (s is Map) {
          statsList.add(PlayerRatingStatItem.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    return PlayerMatchRatingEntity(
      matchId: json['match_id']?.toString() ?? '',
      player: PlayerRatingInfo.fromJson(rawPlayer),
      highlights: PlayerRatingHighlights.fromJson(rawHighlights),
      passing: PlayerRatingPassing.fromJson(rawPassing),
      shooting: PlayerRatingShooting.fromJson(rawShooting),
      dribblesDuels: PlayerRatingDribblesDuels.fromJson(rawDribbles),
      statistics: statsList,
    );
  }

  PlayerRatingStatItem? getStatByCode(String code) {
    try {
      return statistics.firstWhere(
        (s) => s.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  int getStatValue(String code, {int defaultValue = 0}) {
    final stat = getStatByCode(code);
    if (stat == null || stat.value == null) return defaultValue;
    if (stat.value is num) return (stat.value as num).toInt();
    return int.tryParse(stat.value.toString()) ?? defaultValue;
  }

  int get tacklesTotal => getStatValue('Tackles');
  int get tacklesWon => getStatValue('Tackles Won');
  int get interceptions => getStatValue('Interceptions');
  int get possessionLost => getStatValue('Possession Lost');
  int get dispossessed => getStatValue('Dispossessed');
  int get foulsDrawn => getStatValue('Fouls Drawn');
  int get foulsCommitted => getStatValue('Fouls Committed');

  /// Filter out primary metrics already prominently displayed in dedicated sections
  List<PlayerRatingStatItem> get otherStatistics {
    const excludedCodes = {
      'goal',
      'assist',
      'shots off target',
      'shots on target',
      'passes',
      'key passes',
      'interceptions',
      'possession lost',
      'dispossessed',
      'fouls drawn',
      'fouls committed',
      'duels won',
      'duels lost',
    };

    return statistics.where((s) => !excludedCodes.contains(s.code.toLowerCase())).toList();
  }

  @override
  List<Object?> get props => [
        matchId,
        player,
        highlights,
        passing,
        shooting,
        dribblesDuels,
        statistics,
      ];
}
