import '../../domain/entities/app_update_entity.dart';

class AppUpdateDto extends AppUpdateEntity {
  const AppUpdateDto({
    required super.latestVersion,
    required super.latestBuildNumber,
    required super.minSupportedVersion,
    required super.minSupportedBuildNumber,
    required super.forceUpdate,
    required super.isActive,
    required super.downloadUrlAndroid,
    required super.downloadUrlIos,
    required super.releaseNotes,
    super.releaseNotesAr,
    super.releaseNotesEn,
    super.fileSizeBytes,
  });

  factory AppUpdateDto.fromJson(Map<String, dynamic> json) {
    // Safely extract nested data map whether it is Map<String, dynamic> or Map<dynamic, dynamic>
    final rawData = json['data'];
    final Map<dynamic, dynamic> map = (rawData is Map) ? rawData : json;

    final releaseNotesAr =
        (map['release_notes_ar'] ?? map['releaseNotesAr'] ?? '').toString();
    final releaseNotesEn =
        (map['release_notes_en'] ?? map['releaseNotesEn'] ?? '').toString();
    final generalNotes = (map['release_notes'] ??
            map['releaseNotes'] ??
            map['message'] ??
            (releaseNotesAr.isNotEmpty ? releaseNotesAr : releaseNotesEn))
        .toString();

    return AppUpdateDto(
      latestVersion:
          (map['latest_version'] ?? map['latestVersion'] ?? '1.0.0').toString(),
      latestBuildNumber: int.tryParse(
            (map['latest_build_number'] ??
                    map['latestBuildNumber'] ??
                    map['latest_build'] ??
                    1)
                .toString(),
          ) ??
          1,
      minSupportedVersion: (map['min_supported_version'] ??
              map['minSupportedVersion'] ??
              map['min_version'] ??
              '1.0.0')
          .toString(),
      minSupportedBuildNumber: int.tryParse(
            (map['min_supported_build_number'] ??
                    map['minSupportedBuildNumber'] ??
                    map['min_build'] ??
                    1)
                .toString(),
          ) ??
          1,
      forceUpdate: map['force_update'] == true ||
          map['forceUpdate'] == true ||
          map['is_force'] == true,
      isActive: map['is_active'] != false && map['isActive'] != false,
      downloadUrlAndroid: (map['download_url_android'] ??
              map['downloadUrlAndroid'] ??
              map['update_url_android'] ??
              map['download_url'] ??
              '')
          .toString(),
      downloadUrlIos: (map['download_url_ios'] ??
              map['downloadUrlIos'] ??
              map['update_url_ios'] ??
              '')
          .toString(),
      releaseNotes: generalNotes,
      releaseNotesAr: releaseNotesAr,
      releaseNotesEn: releaseNotesEn,
      fileSizeBytes: int.tryParse(
            (map['file_size_bytes'] ?? map['fileSizeBytes'] ?? 0).toString(),
          ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'latest_build_number': latestBuildNumber,
        'min_supported_version': minSupportedVersion,
        'min_supported_build_number': minSupportedBuildNumber,
        'force_update': forceUpdate,
        'is_active': isActive,
        'download_url_android': downloadUrlAndroid,
        'download_url_ios': downloadUrlIos,
        'release_notes': releaseNotes,
        'release_notes_ar': releaseNotesAr,
        'release_notes_en': releaseNotesEn,
        'file_size_bytes': fileSizeBytes,
      };
}
