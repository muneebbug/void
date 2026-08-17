import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  bool _isLoaded = false;

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final loaded = await repo.loadSettings();
    if (!_isLoaded) {
      _isLoaded = true;
      state = loaded;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _isLoaded = true;
    state = state.copyWith(themeMode: mode);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }

  Future<void> setViewMode(ItemViewMode mode) async {
    _isLoaded = true;
    state = state.copyWith(defaultViewMode: mode);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }

  Future<void> setGridColumns(int? columns) async {
    _isLoaded = true;
    if (columns == null) {
      state = state.copyWith(clearGridColumns: true);
    } else {
      state = state.copyWith(gridColumns: columns.clamp(3, 12));
    }
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }

  Future<void> setTmdbApiKey(String? key) async {
    _isLoaded = true;
    state = state.copyWith(tmdbApiKey: key);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
