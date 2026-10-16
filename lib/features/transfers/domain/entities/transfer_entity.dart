import 'package:equatable/equatable.dart';

class TransferEntity extends Equatable {
  final String id;
  final String playerName;
  final String? playerId;
  final String? playerPosition;
  final String? playerImage;
  final String? playerLink;
  final String? fromTeamImage;
  final String? fromTeamName;
  final String? toTeamImage;
  final String? toTeamName;
  final String? transferType;
  final String? transferPrice;
  final String? date;

  const TransferEntity({
    required this.id,
    required this.playerName,
    this.playerId,
    this.playerPosition,
    this.playerImage,
    this.playerLink,
    this.fromTeamImage,
    this.fromTeamName,
    this.toTeamImage,
    this.toTeamName,
    this.transferType,
    this.transferPrice,
    this.date,
  });

  /// Resolves the canonical or best available player ID for navigation.
  String get effectivePlayerId {
    if (playerId != null && playerId!.isNotEmpty && playerId != '0') {
      return playerId!;
    }
    if (playerLink != null && playerLink!.isNotEmpty) {
      final match = RegExp(r'/player(?:s)?/(\d+)').firstMatch(playerLink!);
      if (match != null) return match.group(1)!;
    }
    return (playerName.trim().isNotEmpty) ? '0' : '';
  }

  @override
  List<Object?> get props => [
        id,
        playerName,
        playerId,
        playerPosition,
        playerImage,
        playerLink,
        fromTeamImage,
        toTeamImage,
        transferType,
        transferPrice,
        date,
      ];
}
