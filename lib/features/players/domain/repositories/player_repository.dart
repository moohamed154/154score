import '../../../../core/network/api_result.dart';
import '../entities/player_profile_entity.dart';

abstract class PlayerRepository {
  Future<ApiResult<PlayerProfileEntity>> getPlayerProfile(
    String id, {
    String? slug,
    required String lang,
  });
}
