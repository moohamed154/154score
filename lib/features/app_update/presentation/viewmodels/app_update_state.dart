import 'package:equatable/equatable.dart';
import '../../domain/entities/app_update_entity.dart';

enum AppUpdateStatus {
  initial,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  downloadFailed,
  installFailed,
}

enum AppUpdateErrorType {
  noInternet,
  timeout,
  serverError,
  insufficientStorage,
  permissionDenied,
  corruptedFile,
  unknown,
}

class AppUpdateState extends Equatable {
  final AppUpdateStatus status;
  final AppUpdateEntity? updateInfo;
  final bool isCompulsory;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final String? localApkPath;
  final AppUpdateErrorType? errorType;
  final String? errorMessage;
  final String currentAppVersion;
  final int currentBuildNumber;

  const AppUpdateState({
    this.status = AppUpdateStatus.initial,
    this.updateInfo,
    this.isCompulsory = false,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.localApkPath,
    this.errorType,
    this.errorMessage,
    this.currentAppVersion = '',
    this.currentBuildNumber = 0,
  });

  bool get isChecking => status == AppUpdateStatus.checking;
  bool get isDownloading => status == AppUpdateStatus.downloading;
  bool get isReadyToInstall => status == AppUpdateStatus.readyToInstall;
  bool get hasError =>
      status == AppUpdateStatus.downloadFailed ||
      status == AppUpdateStatus.installFailed;
  bool get isAvailable =>
      status == AppUpdateStatus.available ||
      status == AppUpdateStatus.downloading ||
      status == AppUpdateStatus.readyToInstall ||
      status == AppUpdateStatus.downloadFailed ||
      status == AppUpdateStatus.installFailed;
  bool get hasUpdate => updateInfo != null && isAvailable;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateEntity? updateInfo,
    bool? isCompulsory,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? localApkPath,
    AppUpdateErrorType? errorType,
    String? errorMessage,
    String? currentAppVersion,
    int? currentBuildNumber,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      isCompulsory: isCompulsory ?? this.isCompulsory,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      localApkPath: localApkPath ?? this.localApkPath,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
      currentAppVersion: currentAppVersion ?? this.currentAppVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
    );
  }

  @override
  List<Object?> get props => [
    status,
    updateInfo,
    isCompulsory,
    progress,
    receivedBytes,
    totalBytes,
    localApkPath,
    errorType,
    errorMessage,
    currentAppVersion,
    currentBuildNumber,
  ];
}
