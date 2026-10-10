import 'package:equatable/equatable.dart';

class AppUpdateEntity extends Equatable {
  final String latestVersion;
  final int latestBuildNumber;
  final String minSupportedVersion;
  final int minSupportedBuildNumber;
  final bool forceUpdate;
  final bool isActive;
  final String downloadUrlAndroid;
  final String downloadUrlIos;
  final String releaseNotes;
  final String releaseNotesAr;
  final String releaseNotesEn;
  final int fileSizeBytes;

  const AppUpdateEntity({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedVersion,
    required this.minSupportedBuildNumber,
    required this.forceUpdate,
    required this.isActive,
    required this.downloadUrlAndroid,
    required this.downloadUrlIos,
    required this.releaseNotes,
    this.releaseNotesAr = '',
    this.releaseNotesEn = '',
    this.fileSizeBytes = 0,
  });

  /// Get localized release notes based on current app language
  String localizedReleaseNotes(bool isArabic) {
    if (isArabic) {
      if (releaseNotesAr.trim().isNotEmpty) return releaseNotesAr;
      if (releaseNotes.trim().isNotEmpty) return releaseNotes;
      return releaseNotesEn;
    } else {
      if (releaseNotesEn.trim().isNotEmpty) return releaseNotesEn;
      if (releaseNotes.trim().isNotEmpty) return releaseNotes;
      return releaseNotesAr;
    }
  }

  /// Check if the server version is newer than current app version
  bool hasUpdate({
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    if (!isActive) return false;
    return _isNewer(
      currentVersion: currentVersion,
      currentBuild: currentBuildNumber,
      targetVersion: latestVersion,
      targetBuild: latestBuildNumber,
    );
  }

  /// Check if the update is compulsory (mandatory)
  bool isCompulsory({
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    if (!isActive) return false;
    if (forceUpdate) return true;

    // If current version is older than minimum supported version
    return _isNewer(
      currentVersion: currentVersion,
      currentBuild: currentBuildNumber,
      targetVersion: minSupportedVersion,
      targetBuild: minSupportedBuildNumber,
    );
  }

  /// Internal SemVer + Build Number comparison
  static bool _isNewer({
    required String currentVersion,
    required int currentBuild,
    required String targetVersion,
    required int targetBuild,
  }) {
    final curParts = _parseVersion(currentVersion);
    final targetParts = _parseVersion(targetVersion);

    for (int i = 0; i < 3; i++) {
      if (targetParts[i] > curParts[i]) return true;
      if (targetParts[i] < curParts[i]) return false;
    }

    return targetBuild > currentBuild;
  }

  static List<int> _parseVersion(String version) {
    try {
      final clean = version.split('+').first.trim();
      final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts;
    } catch (_) {
      return [0, 0, 0];
    }
  }

  @override
  List<Object?> get props => [
    latestVersion,
    latestBuildNumber,
    minSupportedVersion,
    minSupportedBuildNumber,
    forceUpdate,
    isActive,
    downloadUrlAndroid,
    downloadUrlIos,
    releaseNotes,
    releaseNotesAr,
    releaseNotesEn,
    fileSizeBytes,
  ];
}
