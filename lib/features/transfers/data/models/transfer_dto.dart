import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/transfer_entity.dart';

class TransferDto {
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

  const TransferDto({
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

  factory TransferDto.fromJson(Map<String, dynamic> json) {
    String name = 'Player';
    String? position;
    String? playerImg;
    String? pLink;

    if (json['player'] is Map) {
      final pMap = json['player'] as Map;
      name = pMap['name']?.toString() ?? name;
      position = pMap['position']?.toString();
      playerImg = pMap['image']?.toString();
      pLink = pMap['link']?.toString();
    }

    String? fromImg = json['from_team_logo']?.toString();
    String? fromName = json['from_team_name']?.toString();
    if (json['from_team'] is Map) {
      final fMap = json['from_team'] as Map;
      fromImg ??= fMap['logo']?.toString() ?? fMap['image']?.toString();
      fromName ??= fMap['title']?.toString() ?? fMap['name']?.toString();
    }

    String? toImg = json['to_team_logo']?.toString();
    String? toName = json['to_team_name']?.toString();
    String? toDate = json['transfer_date']?.toString();
    if (json['to_team'] is Map) {
      final tMap = json['to_team'] as Map;
      toImg ??= tMap['logo']?.toString() ?? tMap['image']?.toString();
      toName ??= tMap['title']?.toString() ?? tMap['name']?.toString();
      toDate ??= tMap['date']?.toString();
    }

    String? type;
    String? price;
    if (json['details'] is Map) {
      final dMap = json['details'] as Map;
      type = dMap['type']?.toString();
      price = dMap['price']?.toString();
    }

    return TransferDto(
      id: json['id']?.toString() ?? name,
      playerName: name,
      playerPosition: position,
      playerImage: UrlHelper.normalizeImageUrl(playerImg),
      playerLink: pLink,
      fromTeamImage: UrlHelper.normalizeImageUrl(fromImg),
      fromTeamName: fromName,
      toTeamImage: UrlHelper.normalizeImageUrl(toImg),
      toTeamName: toName,
      transferType: type,
      transferPrice: price,
      date: toDate ?? json['date']?.toString(),
    );
  }

  TransferEntity toEntity() {
    return TransferEntity(
      id: id,
      playerName: playerName,
      playerPosition: playerPosition,
      playerImage: playerImage,
      playerLink: playerLink,
      fromTeamImage: fromTeamImage,
      fromTeamName: fromTeamName,
      toTeamImage: toTeamImage,
      toTeamName: toTeamName,
      transferType: transferType,
      transferPrice: transferPrice,
      date: date,
    );
  }
}
