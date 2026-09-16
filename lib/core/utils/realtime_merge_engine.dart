import '../../features/matches/domain/entities/match_entity.dart';
import '../../features/match_details/domain/entities/match_details_entity.dart';
import '../../features/transfers/domain/entities/transfer_entity.dart';
import '../websocket/websocket_event.dart';
import 'match_status_helper.dart';

class RealtimeMergeResult<T> {
  final T data;
  final bool isUpdated;

  const RealtimeMergeResult({required this.data, required this.isUpdated});
}

class RealtimeMergeEngine {
  RealtimeMergeEngine._();

  /// Merges an incremental LiveMatchUpdate into an existing list of LeagueGroupEntity
  static RealtimeMergeResult<List<LeagueGroupEntity>> mergeMatchesWithRealtime({
    required List<LeagueGroupEntity> existingLeagues,
    required LiveMatchUpdate update,
  }) {
    if (existingLeagues.isEmpty) {
      return RealtimeMergeResult(data: existingLeagues, isUpdated: false);
    }

    bool matchFound = false;

    final updatedLeagues = existingLeagues.map((league) {
      bool leagueHasMatch = false;

      final updatedMatches = league.matches.map((m) {
        final matchesId = update.matchId != null && m.id == update.matchId;
        final matchesTeams =
            (update.team1 != null &&
            update.team2 != null &&
            update.team1!.isNotEmpty &&
            update.team2!.isNotEmpty &&
            m.team1.toLowerCase().contains(update.team1!.toLowerCase()) &&
            m.team2.toLowerCase().contains(update.team2!.toLowerCase()));

        if (matchesId || matchesTeams) {
          matchFound = true;
          leagueHasMatch = true;

          final newScore1 = (update.score1 != null && update.score1!.isNotEmpty)
              ? update.score1
              : (update.rawPayload['score_1']?.toString() ??
                  update.rawPayload['score1']?.toString() ??
                  update.rawPayload['home_score']?.toString() ??
                  m.score1);
          final newScore2 = (update.score2 != null && update.score2!.isNotEmpty)
              ? update.score2
              : (update.rawPayload['score_2']?.toString() ??
                  update.rawPayload['score2']?.toString() ??
                  update.rawPayload['away_score']?.toString() ??
                  m.score2);
          final newStatus = (update.status != null && update.status!.isNotEmpty)
              ? update.status
              : m.status;
          final newStatusCode = (update.statusCode != null && update.statusCode!.isNotEmpty)
              ? update.statusCode
              : m.statusCode;
          final newMinute = (update.minute != null && update.minute!.isNotEmpty)
              ? update.minute
              : m.minute;
          final newPeriod = (update.period != null && update.period!.isNotEmpty)
              ? update.period
              : m.period;
          final newExtraTime = (update.extraTime != null && update.extraTime!.isNotEmpty)
              ? update.extraTime
              : m.extraTime;
          final newTeam1Logo = (update.team1Logo != null && update.team1Logo!.isNotEmpty)
              ? update.team1Logo
              : m.team1Logo;
          final newTeam2Logo = (update.team2Logo != null && update.team2Logo!.isNotEmpty)
              ? update.team2Logo
              : m.team2Logo;

          final newPenaltyScore1 = (update.penaltyScore1 != null && update.penaltyScore1!.isNotEmpty)
              ? update.penaltyScore1
              : (update.rawPayload['penalty_score_1']?.toString() ??
                  update.rawPayload['penalties_1']?.toString() ??
                  (update.rawPayload['penalties'] is Map ? update.rawPayload['penalties']['home']?.toString() : null) ??
                  m.penaltyScore1);
          final newPenaltyScore2 = (update.penaltyScore2 != null && update.penaltyScore2!.isNotEmpty)
              ? update.penaltyScore2
              : (update.rawPayload['penalty_score_2']?.toString() ??
                  update.rawPayload['penalties_2']?.toString() ??
                  (update.rawPayload['penalties'] is Map ? update.rawPayload['penalties']['away']?.toString() : null) ??
                  m.penaltyScore2);

          return m.copyWith(
            score1: newScore1,
            score2: newScore2,
            penaltyScore1: newPenaltyScore1,
            penaltyScore2: newPenaltyScore2,
            status: newStatus,
            statusCode: newStatusCode,
            minute: newMinute,
            period: newPeriod,
            extraTime: newExtraTime,
            team1Logo: newTeam1Logo,
            team2Logo: newTeam2Logo,
          );
        }
        return m;
      }).toList();

      if (leagueHasMatch) {
        // Sort matches within league: Live -> Upcoming -> Finished
        updatedMatches.sort((a, b) {
          final pA = MatchStatusHelper.getPriority(
            MatchStatusHelper.parseStatus(a.status, time: a.time),
          );
          final pB = MatchStatusHelper.getPriority(
            MatchStatusHelper.parseStatus(b.status, time: b.time),
          );
          return pA.compareTo(pB);
        });
      }

      return league.copyWith(matches: updatedMatches);
    }).toList();

    if (!matchFound) {
      return RealtimeMergeResult(data: existingLeagues, isUpdated: false);
    }

    // Sort leagues so leagues containing active live matches appear first
    updatedLeagues.sort((a, b) {
      final aHasLive = a.matches.any(
        (m) => MatchStatusHelper.isLive(
          MatchStatusHelper.parseStatus(m.status, time: m.time),
        ),
      );
      final bHasLive = b.matches.any(
        (m) => MatchStatusHelper.isLive(
          MatchStatusHelper.parseStatus(m.status, time: m.time),
        ),
      );
      if (aHasLive && !bHasLive) return -1;
      if (!aHasLive && bHasLive) return 1;
      return 0;
    });

    return RealtimeMergeResult(data: updatedLeagues, isUpdated: true);
  }

  /// Reconciles incoming REST leagues snapshot with existing state to prevent
  /// older in-flight REST responses from rolling back newer WebSocket realtime updates.
  static List<LeagueGroupEntity> reconcileRestLeaguesWithRealtime({
    required List<LeagueGroupEntity> restLeagues,
    required List<LeagueGroupEntity> currentLeagues,
  }) {
    if (currentLeagues.isEmpty) return restLeagues;

    // Index current matches by ID
    final currentMatchesMap = <String, MatchEntity>{};
    for (final l in currentLeagues) {
      for (final m in l.matches) {
        currentMatchesMap[m.id] = m;
      }
    }

    final reconciled = restLeagues.map((league) {
      final matches = league.matches.map((restMatch) {
        final currentMatch = currentMatchesMap[restMatch.id];
        if (currentMatch == null) return restMatch;

        // Compare match progress/score to ensure NEWER DATA ALWAYS WINS
        final restPhase = MatchStatusHelper.parseStatus(
          restMatch.status,
          minute: restMatch.minute,
          time: restMatch.time,
        );
        final currPhase = MatchStatusHelper.parseStatus(
          currentMatch.status,
          minute: currentMatch.minute,
          time: currentMatch.time,
        );

        final currIsLive = MatchStatusHelper.isLive(currPhase);
        final restIsUpcoming = MatchStatusHelper.isUpcoming(restPhase);

        if (currIsLive && restIsUpcoming) {
          // Current state is live from WS; delayed REST snapshot says upcoming -> keep live state
          return restMatch.copyWith(
            score1: currentMatch.score1,
            score2: currentMatch.score2,
            status: currentMatch.status,
            minute: currentMatch.minute,
          );
        }

        // If current state has higher scores or progressed minute, preserve current state
        final currGoals =
            (int.tryParse(currentMatch.score1 ?? '0') ?? 0) +
            (int.tryParse(currentMatch.score2 ?? '0') ?? 0);
        final restGoals =
            (int.tryParse(restMatch.score1 ?? '0') ?? 0) +
            (int.tryParse(restMatch.score2 ?? '0') ?? 0);

        final currMin =
            int.tryParse(
              currentMatch.minute?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            ) ??
            0;
        final restMin =
            int.tryParse(
              restMatch.minute?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            ) ??
            0;

        if (currGoals > restGoals || (currIsLive && currMin > restMin) || currentMatch.hasPenalties) {
          return restMatch.copyWith(
            score1: currentMatch.score1 ?? restMatch.score1,
            score2: currentMatch.score2 ?? restMatch.score2,
            penaltyScore1: currentMatch.penaltyScore1 ?? restMatch.penaltyScore1,
            penaltyScore2: currentMatch.penaltyScore2 ?? restMatch.penaltyScore2,
            status: currentMatch.status ?? restMatch.status,
            minute: currentMatch.minute ?? restMatch.minute,
          );
        }

        return restMatch;
      }).toList();

      return league.copyWith(matches: matches);
    }).toList();

    return reconciled;
  }

  /// Merges incremental MatchDetailRealtimeUpdate events into existing match events
  static RealtimeMergeResult<List<MatchEventEntity>> mergeMatchDetailsEvents({
    required List<MatchEventEntity> existingEvents,
    required MatchDetailRealtimeUpdate update,
  }) {
    if (update.eventType == null || update.eventType!.isEmpty) {
      return RealtimeMergeResult(data: existingEvents, isUpdated: false);
    }

    final newEvent = MatchEventEntity(
      minute: update.eventMinute ?? update.minute ?? '',
      type: update.eventType!,
      playerName: update.eventPlayer ?? '',
      secondaryPlayerName: update.eventAssist,
      score: (update.score1 != null && update.score2 != null)
          ? '${update.score1} - ${update.score2}'
          : null,
      isHomeTeam: update.isHomeTeam ?? true,
      videoUrl: update.videoUrl,
    );

    // Deduplication check
    final key = _generateEventKey(newEvent);
    final exists = existingEvents.any((e) => _generateEventKey(e) == key);

    if (exists) {
      return RealtimeMergeResult(data: existingEvents, isUpdated: false);
    }

    final merged = List<MatchEventEntity>.from(existingEvents)..add(newEvent);

    // Sort by minute ascending
    merged.sort((a, b) {
      final minA =
          int.tryParse(a.minute.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final minB =
          int.tryParse(b.minute.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return minA.compareTo(minB);
    });

    return RealtimeMergeResult(data: merged, isUpdated: true);
  }

  static String _generateEventKey(MatchEventEntity event) {
    final cleanMin = event.minute.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPlayer = event.playerName.trim().toLowerCase();
    final cleanType = event.type.trim().toLowerCase();
    return '${cleanMin}_${cleanType}_${cleanPlayer}_${event.isHomeTeam}';
  }

  /// Merges a real-time transfer update into an existing list of TransferEntity
  static RealtimeMergeResult<List<TransferEntity>> mergeTransfersWithRealtime({
    required List<TransferEntity> existingTransfers,
    required TransferUpdate update,
  }) {
    final newTransfer = TransferEntity(
      id: update.transferId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      playerName: update.playerName,
      playerPosition: update.playerPosition,
      playerImage: update.playerImage,
      fromTeamName: update.fromTeamName,
      fromTeamImage: update.fromTeamLogo,
      toTeamName: update.toTeamName,
      toTeamImage: update.toTeamLogo,
      transferType: update.transferType,
      transferPrice: update.transferFee,
      date: update.transferDate ?? 'Today',
    );

    final key = _generateTransferKey(newTransfer);
    final exists = existingTransfers.any((t) => _generateTransferKey(t) == key);

    if (exists) {
      return RealtimeMergeResult(data: existingTransfers, isUpdated: false);
    }

    final merged = [newTransfer, ...existingTransfers];
    return RealtimeMergeResult(data: merged, isUpdated: true);
  }

  static String _generateTransferKey(TransferEntity transfer) {
    if (transfer.id.isNotEmpty && transfer.id.length > 3) {
      return transfer.id;
    }
    final player = transfer.playerName.trim().toLowerCase();
    final from = (transfer.fromTeamName ?? '').trim().toLowerCase();
    final to = (transfer.toTeamName ?? '').trim().toLowerCase();
    final date = (transfer.date ?? '').trim().toLowerCase();
    return '${player}_${from}_${to}_$date';
  }
}
