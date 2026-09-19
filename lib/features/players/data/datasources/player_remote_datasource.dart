import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/player_profile_entity.dart';
import '../models/player_profile_dto.dart';

abstract class PlayerRemoteDataSource {
  Future<PlayerProfileEntity> getPlayerProfile(
    String id, {
    String? slug,
    required String lang,
  });
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final ApiClient _client;

  PlayerRemoteDataSourceImpl(this._client);

  @override
  Future<PlayerProfileEntity> getPlayerProfile(
    String id, {
    String? slug,
    required String lang,
  }) async {
    final endpoint = ApiEndpoints.playerProfile(id, slug);
    final response = await _client.get(
      endpoint,
      queryParameters: {'lang': lang},
    );

    if (response is Map<String, dynamic>) {
      return PlayerProfileDto.fromJson(
        response,
        fallbackId: id,
        fallbackName: slug,
        lang: lang,
      );
    } else if (response is Map) {
      return PlayerProfileDto.fromJson(
        Map<String, dynamic>.from(response),
        fallbackId: id,
        fallbackName: slug,
        lang: lang,
      );
    }

    throw Exception('Invalid player profile response');
  }
}
