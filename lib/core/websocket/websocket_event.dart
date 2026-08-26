import 'package:equatable/equatable.dart';

enum SocketConnectionStatus {
  initial,
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

class LiveMatchUpdate extends Equatable {
  final String? matchId;
  final String? leagueTitle;
  final String? team1;
  final String? team2;
  final String? score1;
  final String? score2;
  final String? time;
  final String? status;
  final String? minute;
  final String? eventType; // goal, card, substitution, etc.
  final String? playerName;
  final Map<String, dynamic> rawPayload;

  const LiveMatchUpdate({
    this.matchId,
    this.leagueTitle,
    this.team1,
    this.team2,
    this.score1,
    this.score2,
    this.time,
    this.status,
    this.minute,
    this.eventType,
    this.playerName,
    this.rawPayload = const {},
  });

  factory LiveMatchUpdate.fromJson(Map<String, dynamic> json) {
    return LiveMatchUpdate(
      matchId: json['id']?.toString() ?? json['match_id']?.toString(),
      leagueTitle: json['league_title']?.toString() ?? json['league']?.toString(),
      team1: json['team_1']?.toString() ?? json['home_team']?.toString(),
      team2: json['team_2']?.toString() ?? json['away_team']?.toString(),
      score1: json['score_1']?.toString() ?? json['home_score']?.toString(),
      score2: json['score_2']?.toString() ?? json['away_score']?.toString(),
      time: json['time']?.toString(),
      status: json['status']?.toString(),
      minute: json['minute']?.toString(),
      eventType: json['event_type']?.toString() ?? json['type']?.toString(),
      playerName: json['player_name']?.toString() ?? json['player']?.toString(),
      rawPayload: json,
    );
  }

  @override
  List<Object?> get props => [
        matchId,
        leagueTitle,
        team1,
        team2,
        score1,
        score2,
        time,
        status,
        minute,
        eventType,
        playerName,
      ];
}
