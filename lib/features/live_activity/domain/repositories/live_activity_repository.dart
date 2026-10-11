import '../../../../core/network/api_result.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../entities/live_activity_entity.dart';

abstract class LiveActivityRepository {
  Future<bool> areActivitiesSupported();
  Future<List<String>> getActiveTrackedMatchIds();
  Future<ApiResult<LiveActivityEntity>> startTrackingMatch({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
  });
  Future<void> updateTrackingMatch({
    required MatchEntity match,
    String? liveScore1,
    String? liveScore2,
    String? liveMinute,
    String? liveStatus,
    String? liveStatusCode,
    String? livePeriod,
    String? penaltyScore1,
    String? penaltyScore2,
  });
  Future<ApiResult<bool>> stopTrackingMatch(String matchId);
  Stream<String> get onTrackingStoppedStream;
}
