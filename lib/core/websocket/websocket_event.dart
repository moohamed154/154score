import 'package:equatable/equatable.dart';

enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

// Backward compatibility alias
typedef SocketConnectionStatus = SocketConnectionState;

/// Comprehensive connection health and observability metrics
class WebSocketConnectionHealth extends Equatable {
  final SocketConnectionState state;
  final String currentTransport; // 'websocket', 'polling', 'none'
  final String? socketId;
  final int? latencyMs;
  final DateTime? lastConnectedAt;
  final DateTime? lastDisconnectedAt;
  final int reconnectAttempts;
  final String? lastError;
  final Set<String> activeSubscriptions;
  final int totalEventsReceived;
  final int duplicateEventsSuppressed;
  final int staleEventsSuppressed;
  final int eventsIgnored;
  final String? lastEventName;
  final DateTime? lastEventTimestamp;
  final bool restFallbackActive;
  final DateTime? lastRestRefreshAt;

  const WebSocketConnectionHealth({
    this.state = SocketConnectionState.disconnected,
    this.currentTransport = 'none',
    this.socketId,
    this.latencyMs,
    this.lastConnectedAt,
    this.lastDisconnectedAt,
    this.reconnectAttempts = 0,
    this.lastError,
    this.activeSubscriptions = const {},
    this.totalEventsReceived = 0,
    this.duplicateEventsSuppressed = 0,
    this.staleEventsSuppressed = 0,
    this.eventsIgnored = 0,
    this.lastEventName,
    this.lastEventTimestamp,
    this.restFallbackActive = false,
    this.lastRestRefreshAt,
  });

  WebSocketConnectionHealth copyWith({
    SocketConnectionState? state,
    String? currentTransport,
    String? socketId,
    int? latencyMs,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    int? reconnectAttempts,
    String? lastError,
    Set<String>? activeSubscriptions,
    int? totalEventsReceived,
    int? duplicateEventsSuppressed,
    int? staleEventsSuppressed,
    int? eventsIgnored,
    String? lastEventName,
    DateTime? lastEventTimestamp,
    bool? restFallbackActive,
    DateTime? lastRestRefreshAt,
  }) {
    return WebSocketConnectionHealth(
      state: state ?? this.state,
      currentTransport: currentTransport ?? this.currentTransport,
      socketId: socketId ?? this.socketId,
      latencyMs: latencyMs ?? this.latencyMs,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastError: lastError,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
      totalEventsReceived: totalEventsReceived ?? this.totalEventsReceived,
      duplicateEventsSuppressed:
          duplicateEventsSuppressed ?? this.duplicateEventsSuppressed,
      staleEventsSuppressed:
          staleEventsSuppressed ?? this.staleEventsSuppressed,
      eventsIgnored: eventsIgnored ?? this.eventsIgnored,
      lastEventName: lastEventName ?? this.lastEventName,
      lastEventTimestamp: lastEventTimestamp ?? this.lastEventTimestamp,
      restFallbackActive: restFallbackActive ?? this.restFallbackActive,
      lastRestRefreshAt: lastRestRefreshAt ?? this.lastRestRefreshAt,
    );
  }

  @override
  List<Object?> get props => [
    state,
    currentTransport,
    socketId,
    latencyMs,
    lastConnectedAt,
    lastDisconnectedAt,
    reconnectAttempts,
    lastError,
    activeSubscriptions,
    totalEventsReceived,
    duplicateEventsSuppressed,
    staleEventsSuppressed,
    eventsIgnored,
    lastEventName,
    lastEventTimestamp,
    restFallbackActive,
    lastRestRefreshAt,
  ];
}

/// Strongly typed Live Match real-time update model
class LiveMatchUpdate extends Equatable {
  final String? matchId;
  final String? leagueTitle;
  final String? leagueId;
  final String? team1;
  final String? team2;
  final String? team1Logo;
  final String? team2Logo;
  final String? score1;
  final String? score2;
  final String? penaltyScore1;
  final String? penaltyScore2;
  final String? time;
  final String? status;
  final String? statusCode;
  final String? minute;
  final String? period;
  final String? extraTime;
  final String? eventType; // goal, card, substitution, etc.
  final String? playerName;
  final int? timestamp;
  final int? sequence;
  final Map<String, dynamic> rawPayload;

  const LiveMatchUpdate({
    this.matchId,
    this.leagueTitle,
    this.leagueId,
    this.team1,
    this.team2,
    this.team1Logo,
    this.team2Logo,
    this.score1,
    this.score2,
    this.penaltyScore1,
    this.penaltyScore2,
    this.time,
    this.status,
    this.statusCode,
    this.minute,
    this.period,
    this.extraTime,
    this.eventType,
    this.playerName,
    this.timestamp,
    this.sequence,
    this.rawPayload = const {},
  });

  /// Deterministic fingerprint for duplicate-event suppression
  String get fingerprint {
    return '${matchId ?? ''}_${score1 ?? ''}_${score2 ?? ''}_${penaltyScore1 ?? ''}_${penaltyScore2 ?? ''}_${status ?? ''}_${statusCode ?? ''}_${minute ?? ''}_${eventType ?? ''}_${playerName ?? ''}';
  }

  factory LiveMatchUpdate.fromJson(
    Map<String, dynamic> json, {
    String? defaultLeagueTitle,
    String? defaultLeagueId,
  }) {
    int? parsedTimestamp;
    if (json['timestamp'] != null) {
      parsedTimestamp = int.tryParse(json['timestamp'].toString());
    } else if (json['updated_at'] != null || json['updatedAt'] != null) {
      final raw = json['updated_at'] ?? json['updatedAt'];
      if (raw is int) {
        parsedTimestamp = raw;
      } else {
        final dt = DateTime.tryParse(raw.toString());
        if (dt != null) parsedTimestamp = dt.millisecondsSinceEpoch;
      }
    }

    int? parsedSequence;
    if (json['sequence'] != null || json['version'] != null) {
      parsedSequence = int.tryParse(
        (json['sequence'] ?? json['version']).toString(),
      );
    }

    // Teams extraction
    Map? homeTeamMap;
    Map? awayTeamMap;
    if (json['teams'] is Map) {
      if (json['teams']['home'] is Map) homeTeamMap = json['teams']['home'] as Map;
      if (json['teams']['away'] is Map) awayTeamMap = json['teams']['away'] as Map;
    }

    final t1 =
        json['team_1']?.toString() ??
        homeTeamMap?['name']?.toString() ??
        json['home_team']?.toString();
    final t2 =
        json['team_2']?.toString() ??
        awayTeamMap?['name']?.toString() ??
        json['away_team']?.toString();

    final t1Logo =
        json['team_1_logo']?.toString() ??
        homeTeamMap?['logo']?.toString() ??
        json['home_logo']?.toString();
    final t2Logo =
        json['team_2_logo']?.toString() ??
        awayTeamMap?['logo']?.toString() ??
        json['away_logo']?.toString();

    // Scores extraction
    String? s1;
    String? s2;
    if (json['score'] is Map) {
      final sMap = json['score'] as Map;
      if (sMap['home'] != null) s1 = sMap['home'].toString();
      if (sMap['away'] != null) s2 = sMap['away'].toString();
    }
    s1 ??= json['score_1']?.toString() ?? json['home_score']?.toString();
    s2 ??= json['score_2']?.toString() ?? json['away_score']?.toString();
    if (s1 == 'null') s1 = null;
    if (s2 == 'null') s2 = null;

    // Penalty shootout extraction
    String? pen1;
    String? pen2;
    if (json['score'] is Map && json['score']['penalties'] is Map) {
      final pMap = json['score']['penalties'] as Map;
      if (pMap['home'] != null) pen1 = pMap['home'].toString();
      if (pMap['away'] != null) pen2 = pMap['away'].toString();
    }
    pen1 ??=
        json['penalty_score_1']?.toString() ??
        json['penalties_1']?.toString() ??
        json['penalties_home']?.toString() ??
        (json['penalties'] is Map
            ? json['penalties']['home']?.toString()
            : null);
    pen2 ??=
        json['penalty_score_2']?.toString() ??
        json['penalties_2']?.toString() ??
        json['penalties_away']?.toString() ??
        (json['penalties'] is Map
            ? json['penalties']['away']?.toString()
            : null);
    if (pen1 == 'null') pen1 = null;
    if (pen2 == 'null') pen2 = null;

    // League extraction
    Map? leagueMap;
    if (json['league'] is Map) leagueMap = json['league'] as Map;
    final lTitle =
        defaultLeagueTitle ??
        json['league_title']?.toString() ??
        leagueMap?['name']?.toString() ??
        json['league']?.toString();
    final lId =
        defaultLeagueId ??
        json['league_id']?.toString() ??
        leagueMap?['id']?.toString();

    return LiveMatchUpdate(
      matchId: json['match_id']?.toString() ?? json['id']?.toString(),
      leagueTitle: lTitle,
      leagueId: lId,
      team1: t1,
      team2: t2,
      team1Logo: t1Logo,
      team2Logo: t2Logo,
      score1: s1,
      score2: s2,
      penaltyScore1: pen1,
      penaltyScore2: pen2,
      time: json['time']?.toString(),
      status: json['status']?.toString(),
      statusCode: json['status_code']?.toString(),
      minute: (json['clock'] != null && json['clock'].toString().contains(':'))
          ? json['clock'].toString()
          : json['minute']?.toString(),
      period: json['period']?.toString(),
      extraTime: (json['extra_time'] is! Map && json['extra_time'] != null && json['extra_time'] != 'null')
          ? json['extra_time']?.toString()
          : (json['added_time']?.toString() ?? json['stoppage_time']?.toString() ?? json['injury_time']?.toString()),
      eventType: json['event_type']?.toString() ?? json['type']?.toString(),
      playerName: json['player_name']?.toString() ?? json['player']?.toString(),
      timestamp: parsedTimestamp,
      sequence: parsedSequence,
      rawPayload: json,
    );
  }

  @override
  List<Object?> get props => [
    matchId,
    leagueTitle,
    leagueId,
    team1,
    team2,
    team1Logo,
    team2Logo,
    score1,
    score2,
    penaltyScore1,
    penaltyScore2,
    time,
    status,
    statusCode,
    minute,
    period,
    extraTime,
    eventType,
    playerName,
    timestamp,
    sequence,
  ];
}

/// Strongly typed Transfer real-time update model
class TransferUpdate extends Equatable {
  final String? transferId;
  final String playerName;
  final String? playerPosition;
  final String? playerImage;
  final String? fromTeamName;
  final String? fromTeamLogo;
  final String? toTeamName;
  final String? toTeamLogo;
  final String? transferType;
  final String? transferFee;
  final String? transferDate;
  final int? timestamp;
  final Map<String, dynamic> rawPayload;

  const TransferUpdate({
    this.transferId,
    required this.playerName,
    this.playerPosition,
    this.playerImage,
    this.fromTeamName,
    this.fromTeamLogo,
    this.toTeamName,
    this.toTeamLogo,
    this.transferType,
    this.transferFee,
    this.transferDate,
    this.timestamp,
    this.rawPayload = const {},
  });

  /// Deterministic fingerprint for duplicate suppression
  String get fingerprint {
    return transferId ??
        '${playerName}_${fromTeamName ?? ''}_${toTeamName ?? ''}_${transferDate ?? ''}_${transferFee ?? ''}';
  }

  factory TransferUpdate.fromJson(Map<String, dynamic> json) {
    int? parsedTimestamp;
    if (json['timestamp'] != null) {
      parsedTimestamp = int.tryParse(json['timestamp'].toString());
    }

    return TransferUpdate(
      transferId: json['id']?.toString() ?? json['transfer_id']?.toString(),
      playerName:
          json['player_name']?.toString() ??
          json['player']?.toString() ??
          'Unknown Player',
      playerPosition:
          json['player_position']?.toString() ?? json['position']?.toString(),
      playerImage:
          json['player_image']?.toString() ?? json['player_photo']?.toString(),
      fromTeamName:
          json['from_team_name']?.toString() ?? json['from_team']?.toString(),
      fromTeamLogo:
          json['from_team_logo']?.toString() ?? json['from_logo']?.toString(),
      toTeamName:
          json['to_team_name']?.toString() ?? json['to_team']?.toString(),
      toTeamLogo:
          json['to_team_logo']?.toString() ?? json['to_logo']?.toString(),
      transferType:
          json['transfer_type']?.toString() ?? json['type']?.toString(),
      transferFee: json['transfer_fee']?.toString() ?? json['fee']?.toString(),
      transferDate:
          json['transfer_date']?.toString() ?? json['date']?.toString(),
      timestamp: parsedTimestamp,
      rawPayload: json,
    );
  }

  @override
  List<Object?> get props => [
    transferId,
    playerName,
    playerPosition,
    playerImage,
    fromTeamName,
    fromTeamLogo,
    toTeamName,
    toTeamLogo,
    transferType,
    transferFee,
    transferDate,
    timestamp,
  ];
}

/// Strongly typed Match Detail real-time update model for match:{id} room
class MatchDetailRealtimeUpdate extends Equatable {
  final String matchId;
  final String? score1;
  final String? score2;
  final String? status;
  final String? statusCode;
  final String? minute;
  final String? extraTime;
  final String? period;
  final String? eventType;
  final String? eventPlayer;
  final String? eventAssist;
  final String? eventMinute;
  final bool? isHomeTeam;
  final int? timestamp;
  final String? videoUrl;
  final Map<String, dynamic> rawPayload;

  const MatchDetailRealtimeUpdate({
    required this.matchId,
    this.score1,
    this.score2,
    this.status,
    this.statusCode,
    this.minute,
    this.extraTime,
    this.period,
    this.eventType,
    this.eventPlayer,
    this.eventAssist,
    this.eventMinute,
    this.isHomeTeam,
    this.timestamp,
    this.videoUrl,
    this.rawPayload = const {},
  });

  /// Deterministic fingerprint for event deduplication
  String get eventFingerprint {
    return '${matchId}_${score1 ?? ''}_${score2 ?? ''}_${status ?? ''}_${minute ?? ''}_${extraTime ?? ''}_${eventMinute ?? ''}_${eventType ?? ''}_${eventPlayer ?? ''}_$isHomeTeam';
  }

  factory MatchDetailRealtimeUpdate.fromJson(
    Map<String, dynamic> json, {
    String? fallbackMatchId,
  }) {
    int? parsedTimestamp;
    if (json['timestamp'] != null) {
      parsedTimestamp = int.tryParse(json['timestamp'].toString());
    } else if (json['updatedAt'] != null) {
      parsedTimestamp = int.tryParse(json['updatedAt'].toString());
    }

    final Map<String, dynamic> payload = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    String parsedMatchId = (
            json['match_id'] ??
            json['matchId'] ??
            payload['match_id'] ??
            payload['matchId'] ??
            fallbackMatchId ??
            json['id'] ??
            payload['id'] ??
            '')
        .toString()
        .replaceAll('match:', '')
        .trim();

    if (parsedMatchId.isEmpty && json['channel'] != null) {
      final ch = json['channel'].toString();
      if (ch.startsWith('match:')) {
        parsedMatchId = ch.substring('match:'.length).trim();
      }
    }

    if (parsedMatchId.isEmpty && fallbackMatchId != null) {
      parsedMatchId = fallbackMatchId.replaceAll('match:', '').trim();
    }

    String? s1 =
        payload['score_1']?.toString() ?? payload['home_score']?.toString();
    String? s2 =
        payload['score_2']?.toString() ?? payload['away_score']?.toString();
    if (payload['score'] is Map) {
      final sMap = payload['score'] as Map;
      if (sMap['home'] != null) s1 ??= sMap['home'].toString();
      if (sMap['away'] != null) s2 ??= sMap['away'].toString();
    }
    String? st = payload['status']?.toString();
    final rawClock = payload['clock']?.toString() ?? json['clock']?.toString();
    final rawMin = payload['minute']?.toString() ?? json['minute']?.toString();
    final min = (rawClock != null && rawClock.contains(':'))
        ? rawClock
        : (rawMin ?? rawClock);
    final period = payload['period']?.toString() ?? json['period']?.toString();
    final extraTime = (payload['extra_time'] is! Map &&
            payload['extra_time'] != null &&
            payload['extra_time'] != 'null')
        ? payload['extra_time']?.toString()
        : (payload['added_time']?.toString() ??
            payload['stoppage_time']?.toString() ??
            payload['injury_time']?.toString() ??
            json['extra_time']?.toString() ??
            json['added_time']?.toString());

    // If backend sent scraped sections list: {"data": [{"section": "معلومات اللقاء", "items": [...]}]}
    if (json['data'] is List) {
      final list = json['data'] as List;
      for (final sec in list) {
        if (sec is Map && sec['items'] is List) {
          for (final item in sec['items']) {
            if (item is Map) {
              final t = item['title']?.toString() ?? '';
              final c = item['content']?.toString() ?? '';
              if (t.contains('النتيجة') || t.toLowerCase().contains('score')) {
                final parts = c.split(RegExp(r'[-–:]'));
                if (parts.length == 2) {
                  s1 ??= parts[0].trim();
                  s2 ??= parts[1].trim();
                }
              }
              if (t.contains('حالة') || t.toLowerCase().contains('status')) {
                st ??= c.trim();
              }
            }
          }
        }
      }
    }

    final statusCode =
        payload['status_code']?.toString() ?? json['status_code']?.toString();

    final isHome =
        payload['is_home'] == true ||
        payload['team'] == '1' ||
        payload['team'] == 'home' ||
        payload['team_type'] == 'home';

    return MatchDetailRealtimeUpdate(
      matchId: parsedMatchId,
      score1: s1,
      score2: s2,
      status: st,
      statusCode: statusCode,
      minute: min,
      extraTime: extraTime,
      period: period,
      eventType:
          payload['event_type']?.toString() ?? payload['type']?.toString(),
      eventPlayer:
          payload['player_name']?.toString() ?? payload['player']?.toString(),
      eventAssist:
          payload['assist_player']?.toString() ??
          payload['assist']?.toString(),
      eventMinute:
          payload['event_minute']?.toString() ?? payload['minute']?.toString(),
      isHomeTeam: isHome,
      timestamp: parsedTimestamp,
      videoUrl: payload['video_url']?.toString() ??
          payload['videoUrl']?.toString() ??
          payload['video']?.toString(),
      rawPayload: json,
    );
  }

  @override
  List<Object?> get props => [
    matchId,
    score1,
    score2,
    status,
    minute,
    extraTime,
    period,
    eventType,
    eventPlayer,
    eventAssist,
    eventMinute,
    isHomeTeam,
    timestamp,
    videoUrl,
  ];
}
