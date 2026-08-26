import 'package:equatable/equatable.dart';

class MatchEventEntity extends Equatable {
  final String minute;
  final String playerName;
  final String? secondaryPlayerName;
  final String type; // goal, yellow_card, red_card, substitution, var
  final bool isHomeTeam;
  final String? score;

  const MatchEventEntity({
    required this.minute,
    required this.playerName,
    this.secondaryPlayerName,
    required this.type,
    this.isHomeTeam = true,
    this.score,
  });

  @override
  List<Object?> get props => [
        minute,
        playerName,
        secondaryPlayerName,
        type,
        isHomeTeam,
        score,
      ];
}

class MatchStatItemEntity extends Equatable {
  final String title;
  final String homeValue;
  final String awayValue;
  final double homePercentage;

  const MatchStatItemEntity({
    required this.title,
    required this.homeValue,
    required this.awayValue,
    required this.homePercentage,
  });

  @override
  List<Object?> get props => [title, homeValue, awayValue, homePercentage];
}

class MatchInfoSectionEntity extends Equatable {
  final String section;
  final List<MatchInfoItemEntity> items;

  const MatchInfoSectionEntity({
    required this.section,
    required this.items,
  });

  @override
  List<Object?> get props => [section, items];
}

class MatchInfoItemEntity extends Equatable {
  final String title;
  final String content;
  final String? id;
  final String? slug;
  final String? link;

  const MatchInfoItemEntity({
    required this.title,
    required this.content,
    this.id,
    this.slug,
    this.link,
  });

  @override
  List<Object?> get props => [title, content, id, slug, link];
}

class MatchNewsItemEntity extends Equatable {
  final String title;
  final String? image;
  final String? link;
  final String? date;

  const MatchNewsItemEntity({
    required this.title,
    this.image,
    this.link,
    this.date,
  });

  @override
  List<Object?> get props => [title, image, link, date];
}
