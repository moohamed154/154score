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
  final String? score1;
  final String? score2;
  final String? time;
  final String? status;
  final String? minute;
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
    this.score1,
    this.score2,
    this.time,
    this.status,
    this.minute,
    this.eventType,
    this.playerName,
    this.timestamp,
    this.sequence,
    this.rawPayload = const {},
  });

  /// Deterministic fingerprint for duplicate-event suppression
  String get fingerprint {
    return '${matchId ?? ''}_${score1 ?? ''}_${score2 ?? ''}_${status ?? ''}_${minute ?? ''}_${eventType ?? ''}_${playerName ?? ''}';
  }

  factory LiveMatchUpdate.fromJson(Map<String, dynamic> json) {
    int? parsedTimestamp;
    if (json['timestamp'] != null) {
      parsedTimestamp = int.tryParse(json['timestamp'].toString());
    } else if (json['updated_at'] != null) {
      final dt = DateTime.tryParse(json['updated_at'].toString());
      if (dt != null) parsedTimestamp = dt.millisecondsSinceEpoch;
    }

    int? parsedSequence;
    if (json['sequence'] != null || json['version'] != null) {
      parsedSequence = int.tryParse(
        (json['sequence'] ?? json['version']).toString(),
      );
    }

    return LiveMatchUpdate(
      matchId: json['id']?.toString() ?? json['match_id']?.toString(),
      leagueTitle:
          json['league_title']?.toString() ?? json['league']?.toString(),
      leagueId: json['league_id']?.toString(),
      team1: json['team_1']?.toString() ?? json['home_team']?.toString(),
      team2: json['team_2']?.toString() ?? json['away_team']?.toString(),
      score1: json['score_1']?.toString() ?? json['home_score']?.toString(),
      score2: json['score_2']?.toString() ?? json['away_score']?.toString(),
      time: json['time']?.toString(),
      status: json['status']?.toString(),
      minute: json['minute']?.toString(),
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
    score1,
    score2,
    time,
    status,
    minute,
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
  final String? minute;
  final String? eventType;
  final String? eventPlayer;
  final String? eventAssist;
  final String? eventMinute;
  final bool? isHomeTeam;
  final int? timestamp;
  final Map<String, dynamic> rawPayload;

  const MatchDetailRealtimeUpdate({
    required this.matchId,
    this.score1,
    this.score2,
    this.status,
    this.minute,
    this.eventType,
    this.eventPlayer,
    this.eventAssist,
    this.eventMinute,
    this.isHomeTeam,
    this.timestamp,
    this.rawPayload = const {},
  });

  /// Deterministic fingerprint for event deduplication
  String get eventFingerprint {
    return '${matchId}_${eventMinute ?? minute ?? ''}_${eventType ?? ''}_${eventPlayer ?? ''}_$isHomeTeam';
  }

  factory MatchDetailRealtimeUpdate.fromJson(Map<String, dynamic> json) {
    int? parsedTimestamp;
    if (json['timestamp'] != null) {
      parsedTimestamp = int.tryParse(json['timestamp'].toString());
    }

    final isHome =
        json['is_home'] == true ||
        json['team'] == '1' ||
        json['team'] == 'home' ||
        json['team_type'] == 'home';

    return MatchDetailRealtimeUpdate(
      matchId: (json['id'] ?? json['match_id'] ?? json['matchId'] ?? '')
          .toString(),
      score1: json['score_1']?.toString() ?? json['home_score']?.toString(),
      score2: json['score_2']?.toString() ?? json['away_score']?.toString(),
      status: json['status']?.toString(),
      minute: json['minute']?.toString(),
      eventType: json['event_type']?.toString() ?? json['type']?.toString(),
      eventPlayer:
          json['player_name']?.toString() ?? json['player']?.toString(),
      eventAssist:
          json['assist_player']?.toString() ?? json['assist']?.toString(),
      eventMinute:
          json['event_minute']?.toString() ?? json['minute']?.toString(),
      isHomeTeam: isHome,
      timestamp: parsedTimestamp,
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
    eventType,
    eventPlayer,
    eventAssist,
    eventMinute,
    isHomeTeam,
    timestamp,
  ];
}
