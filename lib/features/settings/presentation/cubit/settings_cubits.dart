import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart' show Locale, ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../../../core/notifications/background_notification_task.dart';
import '../../domain/models/utc_offset_info.dart';

// Theme Cubit
class ThemeCubit extends Cubit<ThemeMode> {
  final LocalStorageService _storage;

  ThemeCubit(this._storage) : super(_loadInitialMode(_storage));

  static ThemeMode _loadInitialMode(LocalStorageService storage) {
    final modeStr = storage.getThemeMode();
    return switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    if (mode == state) return;
    emit(mode);
    unawaited(_storage.setThemeMode(modeStr));
  }
}

// Locale State
class LocaleState extends Equatable {
  final Locale locale;
  final bool isRefreshing;
  final bool showIndicator;
  final int requestToken;
  final String? errorMessage;

  const LocaleState({
    required this.locale,
    this.isRefreshing = false,
    this.showIndicator = false,
    this.requestToken = 0,
    this.errorMessage,
  });

  LocaleState copyWith({
    Locale? locale,
    bool? isRefreshing,
    bool? showIndicator,
    int? requestToken,
    String? errorMessage,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      showIndicator: showIndicator ?? this.showIndicator,
      requestToken: requestToken ?? this.requestToken,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        locale,
        isRefreshing,
        showIndicator,
        requestToken,
        errorMessage,
      ];
}

// Locale Cubit
class LocaleCubit extends Cubit<LocaleState> {
  final LocalStorageService _storage;
  final WebSocketService _webSocketService;
  Timer? _indicatorDebounceTimer;
  int _currentToken = 0;

  LocaleCubit(this._storage, this._webSocketService)
      : super(LocaleState(locale: Locale(_storage.getLanguage())));

  /// Switches locale immediately (0ms), switches WebSocket channels,
  /// persists language to storage asynchronously, and begins background refresh coordination.
  void setLocale(Locale newLocale) {
    if (state.locale == newLocale && !state.isRefreshing) return;

    _currentToken++;
    final token = _currentToken;
    final langCode = newLocale.languageCode;

    // 1. Persist asynchronously in background (do NOT await before emitting)
    unawaited(_storage.setLanguage(langCode));

    // 2. Persist language for background notification task
    unawaited(saveNotificationLang(langCode));

    // 3. Switch WebSocket channel seamlessly on existing connection
    _webSocketService.switchLanguageChannel(langCode);

    // 3. Cancel any existing indicator timer
    _indicatorDebounceTimer?.cancel();

    // 4. Emit new locale immediately (instant UI / RTL/LTR / static string update)
    emit(
      state.copyWith(
        locale: newLocale,
        isRefreshing: true,
        showIndicator: false,
        requestToken: token,
        errorMessage: null,
      ),
    );

    // 5. Start 300ms threshold timer: only show subtle indicator if refresh takes > 300ms
    _indicatorDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (state.requestToken == token && state.isRefreshing) {
        emit(state.copyWith(showIndicator: true));
      }
    });
  }

  /// Called when background data refreshes finish across the application.
  void notifyRefreshCompleted({int? token, String? error}) {
    if (token != null && token != _currentToken) return;

    _indicatorDebounceTimer?.cancel();
    emit(
      state.copyWith(
        isRefreshing: false,
        showIndicator: false,
        errorMessage: error,
      ),
    );
  }

  @override
  Future<void> close() {
    _indicatorDebounceTimer?.cancel();
    return super.close();
  }
}

// Timezone State
class TimezoneState extends Equatable {
  final int offset;
  final bool isAuto;
  final int deviceOffset;

  const TimezoneState({
    required this.offset,
    required this.isAuto,
    required this.deviceOffset,
  });

  UtcOffsetInfo get currentOffsetInfo => UtcOffsetInfo.findByOffset(offset);
  UtcOffsetInfo get deviceOffsetInfo =>
      UtcOffsetInfo.findByOffset(deviceOffset);

  TimezoneState copyWith({
    int? offset,
    bool? isAuto,
    int? deviceOffset,
  }) {
    return TimezoneState(
      offset: offset ?? this.offset,
      isAuto: isAuto ?? this.isAuto,
      deviceOffset: deviceOffset ?? this.deviceOffset,
    );
  }

  @override
  List<Object?> get props => [offset, isAuto, deviceOffset];
}

// Timezone Cubit
class TimezoneCubit extends Cubit<TimezoneState> {
  final LocalStorageService _storage;

  TimezoneCubit(this._storage)
      : super(
          TimezoneState(
            offset: _storage.getTimezoneOffset(),
            isAuto: _storage.isTimezoneAuto(),
            deviceOffset: _storage.getDeviceTimezoneOffset(),
          ),
        );

  Future<void> setTimezoneOffset(int offset) async {
    await _storage.setTimezoneOffset(offset);
    emit(state.copyWith(offset: offset, isAuto: false));
  }

  Future<void> setAutoTimezone() async {
    final devOffset = _storage.getDeviceTimezoneOffset();
    await _storage.setTimezoneAuto(true);
    emit(
      state.copyWith(
        offset: devOffset,
        isAuto: true,
        deviceOffset: devOffset,
      ),
    );
  }
}

// News Language Cubit ('app', 'ar', 'en')
class NewsLanguageCubit extends Cubit<String> {
  final LocalStorageService _storage;

  NewsLanguageCubit(this._storage) : super(_storage.getNewsLanguage());

  Future<void> setNewsLanguage(String lang) async {
    if (state == lang) return;
    await _storage.setNewsLanguage(lang);
    emit(lang);
  }
}

// Font Size State
class FontSizeState extends Equatable {
  final bool isAuto;
  final double appFontSizeScale;
  final double newsFontSizeScale;

  const FontSizeState({
    required this.isAuto,
    required this.appFontSizeScale,
    required this.newsFontSizeScale,
  });

  FontSizeState copyWith({
    bool? isAuto,
    double? appFontSizeScale,
    double? newsFontSizeScale,
  }) {
    return FontSizeState(
      isAuto: isAuto ?? this.isAuto,
      appFontSizeScale: appFontSizeScale ?? this.appFontSizeScale,
      newsFontSizeScale: newsFontSizeScale ?? this.newsFontSizeScale,
    );
  }

  @override
  List<Object?> get props => [isAuto, appFontSizeScale, newsFontSizeScale];
}

// Font Size Cubit
class FontSizeCubit extends Cubit<FontSizeState> {
  final LocalStorageService _storage;

  FontSizeCubit(this._storage)
      : super(
          FontSizeState(
            isAuto: _storage.isFontSizeAuto(),
            appFontSizeScale: _storage.getAppFontSizeScale(),
            newsFontSizeScale: _storage.getNewsFontSizeScale(),
          ),
        );

  Future<void> setAuto(bool isAuto) async {
    if (state.isAuto == isAuto) return;
    emit(state.copyWith(isAuto: isAuto));
    await _storage.setFontSizeAuto(isAuto);
  }

  Future<void> setAppFontSizeScale(double scale) async {
    final rounded = double.parse(scale.toStringAsFixed(2));
    if (state.appFontSizeScale == rounded && !state.isAuto) return;
    emit(state.copyWith(appFontSizeScale: rounded, isAuto: false));
    await _storage.setFontSizeAuto(false);
    await _storage.setAppFontSizeScale(rounded);
  }

  Future<void> setNewsFontSizeScale(double scale) async {
    final rounded = double.parse(scale.toStringAsFixed(2));
    if (state.newsFontSizeScale == rounded && !state.isAuto) return;
    emit(state.copyWith(newsFontSizeScale: rounded, isAuto: false));
    await _storage.setFontSizeAuto(false);
    await _storage.setNewsFontSizeScale(rounded);
  }
}

