import 'package:flutter/material.dart';

enum ItemViewMode { grid, list, table }

class AppSettings {
  final ThemeMode themeMode;
  final ItemViewMode defaultViewMode;
  final bool autoSaveEnabled;
  final String? tmdbApiKey;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.defaultViewMode = ItemViewMode.grid,
    this.autoSaveEnabled = true,
    this.tmdbApiKey,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    ItemViewMode? defaultViewMode,
    bool? autoSaveEnabled,
    String? tmdbApiKey,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'defaultViewMode': defaultViewMode.name,
        'autoSaveEnabled': autoSaveEnabled,
        'tmdbApiKey': tmdbApiKey,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values.firstWhere(
          (e) => e.name == json['themeMode'],
          orElse: () => ThemeMode.dark,
        ),
        defaultViewMode: ItemViewMode.values.firstWhere(
          (e) => e.name == json['defaultViewMode'],
          orElse: () => ItemViewMode.grid,
        ),
        autoSaveEnabled: json['autoSaveEnabled'] as bool? ?? true,
        tmdbApiKey: json['tmdbApiKey'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.themeMode == themeMode &&
          other.defaultViewMode == defaultViewMode &&
          other.autoSaveEnabled == autoSaveEnabled &&
          other.tmdbApiKey == tmdbApiKey);

  @override
  int get hashCode =>
      Object.hash(themeMode, defaultViewMode, autoSaveEnabled, tmdbApiKey);
}
