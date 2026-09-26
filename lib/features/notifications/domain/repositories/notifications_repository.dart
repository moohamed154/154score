import '../../../../core/network/api_result.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<ApiResult<List<AppNotificationEntity>>> getNotifications({String lang = 'ar'});
  List<String> getReadIds();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead(List<String> ids);
}
