import '../../../../core/network/api_result.dart';
import '../entities/match_details_entity.dart';

abstract class MatchDetailsRepository {
  Future<ApiResult<List<MatchEventEntity>>> getEvents(
    String matchId, {
    required String lang,
  });
  Future<ApiResult<MatchEventsPayload>> getEventsPayload(
    String matchId, {
    required String lang,
  });
  Future<ApiResult<List<MatchStatItemEntity>>> getStats(
    String matchId, {
    required String lang,
  });
  Future<ApiResult<List<MatchInfoSectionEntity>>> getDetails(
    String matchId, {
    required String lang,
    int? utcOffset,
  });
  Future<ApiResult<List<MatchNewsItemEntity>>> getNews(
    String matchId, {
    required String lang,
  });
  Future<ApiResult<MatchLineupEntity?>> getLineups(
    String matchId, {
    required String lang,
  });
}
