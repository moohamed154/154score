import '../../domain/entities/notification_entity.dart';

class NotificationModel extends AppNotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.category,
    required super.title,
    required super.body,
    super.image,
    required super.timestamp,
    required super.createdAt,
    super.isRead,
    super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: AppNotificationEntity.parseType(json['type']?.toString()),
      category: json['category']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      image: json['image']?.toString(),
      timestamp:
          json['timestamp'] is num ? (json['timestamp'] as num).toInt() : 0,
      createdAt: json['created_at']?.toString() ?? '',
      isRead: json['is_read'] == true,
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'category': category,
      'title': title,
      'body': body,
      'image': image,
      'timestamp': timestamp,
      'created_at': createdAt,
      'is_read': isRead,
      'data': data,
    };
  }
}
