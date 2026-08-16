import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(settingsRepositoryProvider);
    final loaded = await repo.loadSettings();
    state = loaded;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }

  Future<void> setViewMode(ItemViewMode mode) async {
    state = state.copyWith(defaultViewMode: mode);
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }

  Future<void> setTmdbApiKey(String? key) async {
    state = state.copyWith(tmdbApiKey: key);
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveSettings(state);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});
