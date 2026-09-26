import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiClient apiClient;
  final LocalStorageService localStorage;

  NotificationsRepositoryImpl({
    required this.apiClient,
    required this.localStorage,
  });

  @override
  Future<ApiResult<List<AppNotificationEntity>>> getNotifications({String lang = 'ar'}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: {'lang': lang},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data['data'] != null) {
          final inner = data['data'];
          if (inner is Map && inner['notifications'] is List) {
            items = inner['notifications'] as List;
          } else if (inner is List) {
            items = inner;
          }
        } else if (data is List) {
          items = data;
        }

        final readIds = localStorage.getReadNotificationIds().toSet();
        final isNewsEnabled = localStorage.isNewsNotificationEnabled();
        final isLineupEnabled = localStorage.isMatchLineupNotificationEnabled();
        final isGoalsEnabled = localStorage.isMatchGoalsNotificationEnabled();
        final isStartEndEnabled = localStorage.isMatchStartEndNotificationEnabled();

        final result = items
            .map((item) {
              if (item is Map<String, dynamic>) {
                final model = NotificationModel.fromJson(item);
                final isRead = readIds.contains(model.id);
                return model.copyWith(isRead: isRead);
              }
              return null;
            })
            .whereType<AppNotificationEntity>()
            .where((notif) {
              // Apply user-configured preferences
              if (notif.type == NotificationType.news && !isNewsEnabled) return false;
              if (notif.type == NotificationType.lineup && !isLineupEnabled) return false;
              if ((notif.type == NotificationType.goal || notif.type == NotificationType.redCard) && !isGoalsEnabled) return false;
              if ((notif.type == NotificationType.matchStart || notif.type == NotificationType.matchHalftime || notif.type == NotificationType.matchEnd) && !isStartEndEnabled) return false;
              return true;
            })
            .toList();

        return ApiSuccess(result);
      }

      return const ApiFailure(ServerFailure('Failed to load notifications', statusCode: 500));
    } catch (e) {
      return ApiFailure(ServerFailure(e.toString()));
    }
  }

  @override
  List<String> getReadIds() => localStorage.getReadNotificationIds();

  @override
  Future<void> markAsRead(String id) => localStorage.markNotificationAsRead(id);

  @override
  Future<void> markAllAsRead(List<String> ids) => localStorage.markAllNotificationsAsRead(ids);
}
