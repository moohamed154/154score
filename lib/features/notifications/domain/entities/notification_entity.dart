import 'package:equatable/equatable.dart';

enum NotificationType {
  news,
  lineup,
  goal,
  redCard,
  matchStart,
  matchHalftime,
  matchEnd,
  other,
}

class AppNotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String category; // 'news', 'match'
  final String title;
  final String body;
  final String? image;
  final int timestamp;
  final String createdAt;
  final bool isRead;
  final Map<String, dynamic> data;

  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    this.image,
    required this.timestamp,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  AppNotificationEntity copyWith({
    String? id,
    NotificationType? type,
    String? category,
    String? title,
    String? body,
    String? image,
    int? timestamp,
    String? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  static NotificationType parseType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'news':
        return NotificationType.news;
      case 'lineup':
        return NotificationType.lineup;
      case 'goal':
        return NotificationType.goal;
      case 'red_card':
        return NotificationType.redCard;
      case 'match_start':
        return NotificationType.matchStart;
      case 'match_halftime':
        return NotificationType.matchHalftime;
      case 'match_end':
        return NotificationType.matchEnd;
      default:
        return NotificationType.other;
    }
  }

  @override
  List<Object?> get props => [
    id,
    type,
    category,
    title,
    body,
    image,
    timestamp,
    createdAt,
    isRead,
    data,
  ];
}
