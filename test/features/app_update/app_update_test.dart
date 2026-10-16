import 'package:flutter_test/flutter_test.dart';
import 'package:score154/features/app_update/data/models/app_update_dto.dart';
import 'package:score154/features/app_update/domain/entities/app_update_entity.dart';

void main() {
  group('AppUpdateEntity Version Comparison Tests', () {
    const updateEntity = AppUpdateEntity(
      latestVersion: '1.2.0',
      latestBuildNumber: 15,
      minSupportedVersion: '1.1.0',
      minSupportedBuildNumber: 10,
      forceUpdate: false,
      isActive: true,
      downloadUrlAndroid: 'https://example.com/app.apk',
      downloadUrlIos: 'https://apps.apple.com/app',
      releaseNotes: 'Features and fixes',
    );

    test('should detect newer version as update available', () {
      expect(
        updateEntity.hasUpdate(
          currentVersion: '1.1.5',
          currentBuildNumber: 12,
        ),
        isTrue,
      );
    });

    test(
        'should detect same version with higher build number as update available',
        () {
      expect(
        updateEntity.hasUpdate(
          currentVersion: '1.2.0',
          currentBuildNumber: 14,
        ),
        isTrue,
      );
    });

    test('should return false when app is on latest or newer version', () {
      expect(
        updateEntity.hasUpdate(
          currentVersion: '1.2.0',
          currentBuildNumber: 15,
        ),
        isFalse,
      );
      expect(
        updateEntity.hasUpdate(
          currentVersion: '1.2.1',
          currentBuildNumber: 16,
        ),
        isFalse,
      );
    });

    test('should return false for update if isActive is false', () {
      const inactive = AppUpdateEntity(
        latestVersion: '2.0.0',
        latestBuildNumber: 99,
        minSupportedVersion: '1.0.0',
        minSupportedBuildNumber: 1,
        forceUpdate: true,
        isActive: false,
        downloadUrlAndroid: '',
        downloadUrlIos: '',
        releaseNotes: '',
      );

      expect(
        inactive.hasUpdate(
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
        ),
        isFalse,
      );
      expect(
        inactive.isCompulsory(
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
        ),
        isFalse,
      );
    });

    test('should identify compulsory update when version < minSupportedVersion',
        () {
      expect(
        updateEntity.isCompulsory(
          currentVersion: '1.0.9',
          currentBuildNumber: 9,
        ),
        isTrue,
      );
    });

    test('should identify optional update when version >= minSupportedVersion',
        () {
      expect(
        updateEntity.isCompulsory(
          currentVersion: '1.1.0',
          currentBuildNumber: 10,
        ),
        isFalse,
      );
    });

    test('should identify compulsory update when forceUpdate is true', () {
      const forced = AppUpdateEntity(
        latestVersion: '1.2.0',
        latestBuildNumber: 15,
        minSupportedVersion: '1.0.0',
        minSupportedBuildNumber: 1,
        forceUpdate: true,
        isActive: true,
        downloadUrlAndroid: 'https://example.com/app.apk',
        downloadUrlIos: '',
        releaseNotes: '',
      );

      expect(
        forced.isCompulsory(
          currentVersion: '1.1.9',
          currentBuildNumber: 14,
        ),
        isTrue,
      );
    });
  });

  group('AppUpdateDto Parsing Tests', () {
    test('should parse correctly from server JSON payload', () {
      final json = {
        'success': true,
        'data': {
          'is_active': true,
          'force_update': true,
          'latest_version': '2.0.1',
          'latest_build_number': 35,
          'min_supported_version': '1.5.0',
          'min_supported_build_number': 20,
          'download_url_android': 'https://server.com/app-release.apk',
          'download_url_ios': 'https://apps.apple.com/app/154score',
          'release_notes': '• New live commentary\n• Faster websocket',
          'file_size_bytes': 42000000,
        }
      };

      final dto = AppUpdateDto.fromJson(json);

      expect(dto.isActive, isTrue);
      expect(dto.forceUpdate, isTrue);
      expect(dto.latestVersion, equals('2.0.1'));
      expect(dto.latestBuildNumber, equals(35));
      expect(dto.minSupportedVersion, equals('1.5.0'));
      expect(dto.minSupportedBuildNumber, equals(20));
      expect(
          dto.downloadUrlAndroid, equals('https://server.com/app-release.apk'));
      expect(dto.downloadUrlIos, equals('https://apps.apple.com/app/154score'));
      expect(dto.releaseNotes, contains('New live commentary'));
      expect(dto.fileSizeBytes, equals(42000000));
    });
  });
}
