import 'dart:io';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class LiveActivityRemoteDataSource {
  Future<bool> registerActivity({
    required String activityId,
    required String matchId,
    required String pushToken,
    String? platform,
    String? deviceId,
    String? lang,
  });

  Future<bool> updateToken({
    required String activityId,
    required String matchId,
    required String pushToken,
  });

  Future<bool> stopActivity({
    String? activityId,
    String? matchId,
    String? pushToken,
  });
}

class LiveActivityRemoteDataSourceImpl implements LiveActivityRemoteDataSource {
  final ApiClient apiClient;

  LiveActivityRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<bool> registerActivity({
    required String activityId,
    required String matchId,
    required String pushToken,
    String? platform,
    String? deviceId,
    String? lang,
  }) async {
    final payload = {
      'activity_id': activityId,
      'match_id': matchId,
      'push_token': pushToken,
      'platform': platform ?? (Platform.isIOS ? 'ios' : 'android'),
      if (deviceId != null) 'device_id': deviceId,
      'lang': lang ?? 'ar',
    };

    try {
      final response = await apiClient.post(
        ApiEndpoints.liveActivityRegister,
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (_) {
      try {
        final fallbackRes = await apiClient.post(
          ApiEndpoints.liveActivityRegisterFallback,
          data: payload,
        );
        return fallbackRes.statusCode == 200 || fallbackRes.statusCode == 201;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  @override
  Future<bool> updateToken({
    required String activityId,
    required String matchId,
    required String pushToken,
  }) async {
    final payload = {
      'activity_id': activityId,
      'match_id': matchId,
      'push_token': pushToken,
    };

    try {
      final response = await apiClient.post(
        ApiEndpoints.liveActivityUpdateToken,
        data: payload,
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final fallbackRes = await apiClient.post(
          ApiEndpoints.liveActivityUpdateTokenFallback,
          data: payload,
        );
        return fallbackRes.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<bool> stopActivity({
    String? activityId,
    String? matchId,
    String? pushToken,
  }) async {
    final payload = {
      if (activityId != null) 'activity_id': activityId,
      if (matchId != null) 'match_id': matchId,
      if (pushToken != null) 'push_token': pushToken,
    };

    try {
      final response = await apiClient.post(
        ApiEndpoints.liveActivityStop,
        data: payload,
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final fallbackRes = await apiClient.post(
          ApiEndpoints.liveActivityStopFallback,
          data: payload,
        );
        return fallbackRes.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }
}
