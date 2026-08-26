import 'package:equatable/equatable.dart';

class TransferEntity extends Equatable {
  final String id;
  final String playerName;
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

  @override
  List<Object?> get props => [
        id,
        playerName,
        playerPosition,
        playerImage,
        fromTeamImage,
        toTeamImage,
        transferType,
        transferPrice,
        date,
      ];
}
