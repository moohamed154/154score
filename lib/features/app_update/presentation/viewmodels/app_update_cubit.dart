import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/app_update_repository.dart';
import 'app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final AppUpdateRepository _appUpdateRepository;
  final Dio _dio;
  CancelToken? _cancelToken;

  AppUpdateCubit({
    required AppUpdateRepository appUpdateRepository,
    required Dio dio,
  })  : _appUpdateRepository = appUpdateRepository,
        _dio = dio,
        super(const AppUpdateState());

  /// Checks server for app update without any BuildContext dependency
  Future<void> checkForUpdate() async {
    emit(state.copyWith(status: AppUpdateStatus.checking));

    try {
      String currentVersion = '1.0.1';
      int currentBuildNumber = 2;
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        if (packageInfo.version.isNotEmpty) {
          currentVersion = packageInfo.version;
          currentBuildNumber =
              int.tryParse(packageInfo.buildNumber) ?? currentBuildNumber;
        }
      } catch (e) {
        // Fallback gracefully if native plugin is not loaded yet
        debugPrint('[AppUpdateCubit] PackageInfo fallback: $e');
      }

      final result = await _appUpdateRepository.getAppUpdate();

      result.fold(
        onSuccess: (entity) {
          final hasUpdate = entity.hasUpdate(
            currentVersion: currentVersion,
            currentBuildNumber: currentBuildNumber,
          );
          final isCompulsory = entity.isCompulsory(
            currentVersion: currentVersion,
            currentBuildNumber: currentBuildNumber,
          );

          debugPrint(
            '[AppUpdateCubit] Check finished: current=$currentVersion+$currentBuildNumber, '
            'serverLatest=${entity.latestVersion}+${entity.latestBuildNumber}, '
            'hasUpdate=$hasUpdate, isCompulsory=$isCompulsory',
          );

          if (hasUpdate) {
            emit(state.copyWith(
              status: AppUpdateStatus.available,
              updateInfo: entity,
              isCompulsory: isCompulsory,
              currentAppVersion: currentVersion,
              currentBuildNumber: currentBuildNumber,
            ));
          } else {
            emit(state.copyWith(
              status: AppUpdateStatus.upToDate,
              updateInfo: entity,
              currentAppVersion: currentVersion,
              currentBuildNumber: currentBuildNumber,
            ));
          }
        },
        onFailure: (failure) {
          debugPrint('[AppUpdateCubit] API failure: ${failure.message}');
          emit(state.copyWith(
            status: AppUpdateStatus.initial,
            errorMessage: failure.message,
            currentAppVersion: currentVersion,
            currentBuildNumber: currentBuildNumber,
          ));
        },
      );
    } catch (e) {
      debugPrint('[AppUpdateCubit] Unexpected check error: $e');
      emit(state.copyWith(
        status: AppUpdateStatus.initial,
        errorMessage: 'فشل فحص التحديثات: $e',
      ));
    }
  }

  /// Downloads the APK and tracks byte-level progress
  Future<void> startDownload() async {
    final info = state.updateInfo;
    if (info == null) return;

    final downloadUrl = info.downloadUrlAndroid.isNotEmpty
        ? info.downloadUrlAndroid
        : info.downloadUrlIos;

    if (downloadUrl.isEmpty) {
      emit(state.copyWith(
        status: AppUpdateStatus.downloadFailed,
        errorType: AppUpdateErrorType.serverError,
        errorMessage: 'رابط التحديث غير متوفر في السيرفر حالياً.',
      ));
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    emit(state.copyWith(
      status: AppUpdateStatus.downloading,
      progress: 0.0,
      receivedBytes: 0,
      totalBytes: info.fileSizeBytes,
      errorMessage: null,
      errorType: null,
    ));

    try {
      final dir = await getTemporaryDirectory();
      final sanitizedVersion =
          info.latestVersion.replaceAll(RegExp(r'[^\w.-]'), '_');
      final savePath = '${dir.path}/154score_v$sanitizedVersion.apk';
      final file = File(savePath);

      // Clean up previous corrupted or partial download
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      int expectedTotal = info.fileSizeBytes;

      await _dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) expectedTotal = total;
          final currentTotal = expectedTotal > 0 ? expectedTotal : total;
          final progress = currentTotal > 0
              ? (received / currentTotal).clamp(0.0, 1.0)
              : 0.0;

          emit(state.copyWith(
            status: AppUpdateStatus.downloading,
            progress: progress,
            receivedBytes: received,
            totalBytes: currentTotal,
          ));
        },
      );

      // Validate integrity of downloaded file
      if (await file.exists()) {
        final fileSize = await file.length();
        if (expectedTotal > 0 && fileSize < (expectedTotal * 0.95)) {
          try {
            await file.delete();
          } catch (_) {}
          emit(state.copyWith(
            status: AppUpdateStatus.downloadFailed,
            errorType: AppUpdateErrorType.corruptedFile,
            errorMessage:
                'الملف المحمل غير مكتمل أو تالف. يرجى إعادة المحاولة.',
          ));
          return;
        }

        emit(state.copyWith(
          status: AppUpdateStatus.readyToInstall,
          progress: 1.0,
          localApkPath: savePath,
        ));

        // Auto trigger install prompt
        await installApk(savePath);
      } else {
        emit(state.copyWith(
          status: AppUpdateStatus.downloadFailed,
          errorType: AppUpdateErrorType.corruptedFile,
          errorMessage: 'تعذر العثور على الملف بعد اكتمال التنزيل.',
        ));
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      final (errorType, message) = _mapDioError(e);
      emit(state.copyWith(
        status: AppUpdateStatus.downloadFailed,
        errorType: errorType,
        errorMessage: message,
      ));
    } on FileSystemException catch (e) {
      emit(state.copyWith(
        status: AppUpdateStatus.downloadFailed,
        errorType: AppUpdateErrorType.insufficientStorage,
        errorMessage: 'مساحة التخزين غير كافية أو تعذر الكتابة: ${e.message}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AppUpdateStatus.downloadFailed,
        errorType: AppUpdateErrorType.unknown,
        errorMessage: 'حدث خطأ غير متوقع أثناء التحميل: $e',
      ));
    }
  }

  /// Triggers the Android Package Installer for the APK
  Future<void> installApk([String? path]) async {
    final filePath = path ?? state.localApkPath;
    if (filePath == null) return;

    final file = File(filePath);
    if (!await file.exists()) {
      emit(state.copyWith(
        status: AppUpdateStatus.available,
        localApkPath: null,
      ));
      return;
    }

    try {
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        emit(state.copyWith(
          status: AppUpdateStatus.installFailed,
          errorMessage: result.message.isNotEmpty
              ? result.message
              : 'يرجى تفعيل خيار السماح بتثبيت التطبيقات من هذا المصدر في الإعدادات.',
        ));
      } else {
        // Keep in readyToInstall state so user can re-trigger if they dismissed the prompt
        emit(state.copyWith(
          status: AppUpdateStatus.readyToInstall,
          localApkPath: filePath,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AppUpdateStatus.installFailed,
        errorMessage: 'تعذر تشغيل معالج التثبيت: $e',
      ));
    }
  }

  /// Cancel running download
  void cancelDownload() {
    _cancelToken?.cancel();
    emit(state.copyWith(
      status: AppUpdateStatus.available,
      progress: 0.0,
      receivedBytes: 0,
    ));
  }

  (AppUpdateErrorType, String) _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return (
          AppUpdateErrorType.timeout,
          'انتهت مهلة الاتصال بالخادم. يرجى التحقق من سرعة اتصالك.'
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return (
          AppUpdateErrorType.serverError,
          'خطأ من الخادم ($code). رابط ملف التحديث غير متاح حالياً.'
        );
      case DioExceptionType.connectionError:
        return (
          AppUpdateErrorType.noInternet,
          'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة وإعادة المحاولة.'
        );
      default:
        return (
          AppUpdateErrorType.unknown,
          'فشل تنزيل ملف التحديث. يرجى إعادة المحاولة لاحقاً.'
        );
    }
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}
