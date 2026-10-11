import 'dart:async';
import 'package:flutter/services.dart';

abstract class LiveActivityPlatformDataSource {
  Future<bool> areActivitiesEnabled();
  Future<Map<String, dynamic>> startLiveActivity(Map<String, dynamic> data);
  Future<bool> updateLiveActivity(Map<String, dynamic> data);
  Future<bool> stopLiveActivity({String? matchId, String? activityId});
  Future<List<String>> getActiveActivities();
  Stream<Map<String, dynamic>> get onPushTokenRotatedStream;
  Stream<String> get onTrackingStoppedStream;
}

class LiveActivityPlatformDataSourceImpl implements LiveActivityPlatformDataSource {
  static const MethodChannel _channel = MethodChannel('com.hamdy.app154score/live_activity');

  final StreamController<Map<String, dynamic>> _pushTokenRotatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _trackingStoppedController =
      StreamController<String>.broadcast();

  LiveActivityPlatformDataSourceImpl() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPushTokenRotated':
        if (call.arguments is Map) {
          final map = Map<String, dynamic>.from(call.arguments as Map);
          _pushTokenRotatedController.add(map);
        }
        break;
      case 'onTrackingStopped':
        if (call.arguments is Map) {
          final matchId = (call.arguments as Map)['matchId']?.toString();
          if (matchId != null) {
            _trackingStoppedController.add(matchId);
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  Future<bool> areActivitiesEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('areActivitiesEnabled');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> startLiveActivity(Map<String, dynamic> data) async {
    try {
      final result = await _channel.invokeMethod<Map>('startLiveActivity', data);
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return {};
    } on PlatformException catch (e) {
      throw Exception('Failed to start Live Activity: ${e.message}');
    }
  }

  @override
  Future<bool> updateLiveActivity(Map<String, dynamic> data) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateLiveActivity', data);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> stopLiveActivity({String? matchId, String? activityId}) async {
    try {
      final result = await _channel.invokeMethod<bool>('stopLiveActivity', {
        if (matchId != null) 'matchId': matchId,
        if (activityId != null) 'activityId': activityId,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> getActiveActivities() async {
    try {
      final result = await _channel.invokeListMethod<String>('getActiveActivities');
      return result ?? [];
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<Map<String, dynamic>> get onPushTokenRotatedStream =>
      _pushTokenRotatedController.stream;

  @override
  Stream<String> get onTrackingStoppedStream =>
      _trackingStoppedController.stream;
}
