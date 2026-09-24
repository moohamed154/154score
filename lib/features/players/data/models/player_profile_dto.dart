import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/player_profile_entity.dart';

class PlayerProfileDto {
  static PlayerProfileEntity fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
    String? fallbackName,
    String lang = 'ar',
  }) {
    // Top-level unwrapping if enclosed in 'data'
    final map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final id = (map['player_id'] ?? map['id'] ?? fallbackId ?? '').toString();
    final name = (map['name'] ?? map['title'] ?? fallbackName ?? '').toString();
    final nameAr = map['name_ar']?.toString();
    final nameEn = map['name_en']?.toString();
    final photo = UrlHelper.normalizeImageUrl(
      (map['photo'] ?? map['image'])?.toString(),
    );
    final cover = UrlHelper.normalizeImageUrl(
      (map['cover'] ?? map['image_cover'])?.toString(),
    );

    // Team
    PlayerTeamEntity? team;
    if (map['team'] is Map) {
      final t = map['team'] as Map;
      team = PlayerTeamEntity(
        id: (t['id'] ?? t['row_id'] ?? '').toString(),
        name: (t['name'] ?? t['title'] ?? '').toString(),
        fullName: (t['full_name'] ?? t['full_title'] ?? t['title'] ?? '')
            .toString(),
        logo: UrlHelper.normalizeImageUrl(
          (t['logo'] ?? t['image'])?.toString(),
        ),
        worldRanking: int.tryParse(t['world_ranking']?.toString() ?? '0') ?? 0,
      );
    } else if (map['team_name'] is Map) {
      final t = map['team_name'] as Map;
      team = PlayerTeamEntity(
        id: (t['row_id'] ?? t['id'] ?? '').toString(),
        name: (t['title'] ?? '').toString(),
        fullName: (t['full_title'] ?? t['title'] ?? '').toString(),
        logo: UrlHelper.normalizeImageUrl(
          (t['image'] ?? map['team_logo'])?.toString(),
        ),
        worldRanking: int.tryParse(t['world_ranking']?.toString() ?? '0') ?? 0,
      );
    } else if (map['team_logo'] != null) {
      team = PlayerTeamEntity(
        id: '',
        name: '',
        fullName: '',
        logo: UrlHelper.normalizeImageUrl(map['team_logo']?.toString()),
      );
    }

    // Country
    PlayerCountryEntity? country;
    if (map['country'] is Map) {
      final c = map['country'] as Map;
      country = PlayerCountryEntity(
        id: (c['id'] ?? '').toString(),
        name: (c['name'] ?? c['title'] ?? '').toString(),
        code: (c['code'] ?? '').toString(),
        flag: UrlHelper.normalizeImageUrl(
          (c['flag'] ?? c['image'])?.toString(),
        ),
      );
    } else if (map['country_flag'] != null) {
      country = PlayerCountryEntity(
        id: '',
        name: '',
        code: '',
        flag: UrlHelper.normalizeImageUrl(map['country_flag']?.toString()),
      );
    }

    // Physical & biographical traits
    final clubNumber = int.tryParse(map['club_number']?.toString() ?? '');
    final interNumber = int.tryParse(map['inter_number']?.toString() ?? '');
    final height = int.tryParse(map['height']?.toString() ?? '');
    final weight = int.tryParse(map['weight']?.toString() ?? '');
    final birthDay = map['birth_day']?.toString();
    final age = int.tryParse(map['age']?.toString() ?? '');
    final position = map['position']?.toString();
    final positionName = (map['position_name'] ?? '').toString();
    final foot = map['foot']?.toString();
    final footName = map['foot_name']?.toString();
    final city = map['city']?.toString();
    final retired = map['retired'] == true || map['retired'] == 1;
    final died = map['died'] == true || map['died'] == 1;
    final playerStatus =
        int.tryParse(map['player_status']?.toString() ?? '1') ?? 1;

    // Season / League Statistics
    final rawStats =
        (map['statistics'] ?? map['player_statistics']) as List? ?? [];
    final stats = <PlayerStatisticEntity>[];
    for (final s in rawStats) {
      if (s is Map) {
        final l = s['league'] is Map ? s['league'] as Map : {};
        final leagueEntity = PlayerLeagueEntity(
          id: (l['id'] ?? '').toString(),
          seasonId: l['season_id']?.toString() ?? l['url_id']?.toString(),
          name: (l['name'] ?? l['title'] ?? '').toString(),
          logo: UrlHelper.normalizeImageUrl(
            (l['logo'] ?? l['image'])?.toString(),
          ),
          logoLight: UrlHelper.normalizeImageUrl(
            (l['logo_light'] ?? l['image_light'])?.toString(),
          ),
          type: int.tryParse(l['type']?.toString() ?? ''),
          ranking: int.tryParse(l['ranking']?.toString() ?? ''),
          followed: l['followed'] == 1 || l['followed'] == true,
        );

        stats.add(
          PlayerStatisticEntity(
            league: leagueEntity,
            appearances: int.tryParse(s['appearances']?.toString() ?? '0') ?? 0,
            goals: int.tryParse(s['goals']?.toString() ?? '0') ?? 0,
            assists:
                int.tryParse(
                  (s['assists'] ?? s['assist'])?.toString() ?? '0',
                ) ??
                0,
            scorePenalty:
                int.tryParse(s['score_penalty']?.toString() ?? '0') ?? 0,
            missPenalty:
                int.tryParse(s['miss_penalty']?.toString() ?? '0') ?? 0,
            cancelGoal: int.tryParse(s['cancel_goal']?.toString() ?? '0') ?? 0,
            ownGoal: int.tryParse(s['own_goal']?.toString() ?? '0') ?? 0,
            yellowCards:
                int.tryParse(
                  (s['yellow_cards'] ?? s['yellow_card'])?.toString() ?? '0',
                ) ??
                0,
            redCards:
                int.tryParse(
                  (s['red_cards'] ?? s['red_card'])?.toString() ?? '0',
                ) ??
                0,
            cleanSheets:
                int.tryParse(s['clean_sheets']?.toString() ?? '0') ?? 0,
            manOfMatch:
                int.tryParse(
                  (s['man_of_match'] ?? s['man_match'])?.toString() ?? '0',
                ) ??
                0,
          ),
        );
      }
    }

    // Transfers
    final rawTransfers = map['transfers'] as List? ?? [];
    final transfers = <PlayerTransferEntity>[];
    for (final tr in rawTransfers) {
      if (tr is Map) {
        PlayerTeamEntity? destTeam;
        if (tr['team'] is Map) {
          final dt = tr['team'] as Map;
          destTeam = PlayerTeamEntity(
            id: (dt['id'] ?? dt['row_id'] ?? '').toString(),
            name: (dt['name'] ?? dt['title'] ?? '').toString(),
            fullName: (dt['full_name'] ?? dt['full_title'] ?? dt['title'] ?? '')
                .toString(),
            logo: UrlHelper.normalizeImageUrl(
              (dt['logo'] ?? dt['image'])?.toString(),
            ),
            worldRanking:
                int.tryParse(dt['world_ranking']?.toString() ?? '0') ?? 0,
          );
        } else if (tr['team_in'] is Map) {
          final dt = tr['team_in'] as Map;
          destTeam = PlayerTeamEntity(
            id: (dt['row_id'] ?? dt['id'] ?? '').toString(),
            name: (dt['title'] ?? '').toString(),
            fullName: (dt['full_title'] ?? dt['title'] ?? '').toString(),
            logo: UrlHelper.normalizeImageUrl(dt['image']?.toString()),
            worldRanking:
                int.tryParse(dt['world_ranking']?.toString() ?? '0') ?? 0,
          );
        }

        final type = (tr['type'] ?? tr['trans'] ?? '').toString();
        final rawFee = (tr['raw_fee'] ?? tr['value'] ?? '0').toString();
        final fee =
            (tr['fee'] ??
                    (rawFee != '0'
                        ? rawFee
                        : (lang == 'en' ? 'Free Transfer' : 'انتقال حر')))
                .toString();
        final season =
            (tr['season'] ?? tr['date_from']?.toString().split('-').first ?? '')
                .toString();

        transfers.add(
          PlayerTransferEntity(
            team: destTeam,
            type: type,
            fee: fee,
            rawFee: rawFee,
            important: tr['important'] == 1 || tr['important'] == true,
            active: tr['active'] == 1 || tr['active'] == true,
            dateFrom: tr['date_from']?.toString(),
            dateTo: tr['date_to']?.toString(),
            season: season,
          ),
        );
      }
    }

    // Metadata list
    final rawMeta = map['metadata'] as List? ?? [];
    final metadata = <Map<String, String>>[];
    for (final m in rawMeta) {
      if (m is Map) {
        final t = (m['title'] ?? '').toString().trim();
        final c = (m['content'] ?? '').toString().trim();
        if (t.isNotEmpty && c.isNotEmpty) {
          metadata.add({'title': t, 'content': c});
        }
      }
    }

    return PlayerProfileEntity(
      id: id,
      name: name,
      nameAr: nameAr,
      nameEn: nameEn,
      photo: photo,
      cover: cover,
      team: team,
      country: country,
      clubNumber: clubNumber,
      interNumber: interNumber,
      height: height,
      weight: weight,
      birthDay: birthDay,
      age: age,
      position: position,
      positionName: positionName,
      foot: foot,
      footName: footName,
      city: city,
      retired: retired,
      died: died,
      playerStatus: playerStatus,
      statistics: stats,
      transfers: transfers,
      metadata: metadata,
      url: map['url']?.toString(),
    );
  }
}
