import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/websocket/websocket_service.dart';

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
    await _storage.setThemeMode(modeStr);
    emit(mode);
  }
}

// Locale Cubit
class LocaleCubit extends Cubit<Locale> {
  final LocalStorageService _storage;
  final WebSocketService _webSocketService;

  LocaleCubit(this._storage, this._webSocketService)
    : super(Locale(_storage.getLanguage()));

  Future<void> setLocale(Locale locale) async {
    await _storage.setLanguage(locale.languageCode);
    _webSocketService.switchLanguageChannel(locale.languageCode);
    emit(locale);
  }
}
