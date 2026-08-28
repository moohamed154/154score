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

          // Safe value merging - never convert null to "null" or create undefined/NaN
          final newScore1 = (update.score1 != null && update.score1!.isNotEmpty)
              ? update.score1
              : m.score1;
          final newScore2 = (update.score2 != null && update.score2!.isNotEmpty)
              ? update.score2
              : m.score2;
          final newStatus = (update.status != null && update.status!.isNotEmpty)
              ? update.status
              : m.status;
          final newMinute = (update.minute != null && update.minute!.isNotEmpty)
              ? update.minute
              : m.minute;

          return m.copyWith(
            score1: newScore1,
            score2: newScore2,
            status: newStatus,
            minute: newMinute,
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
