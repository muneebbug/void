import 'package:flutter/material.dart';

enum ItemViewMode { grid, list, table }

class AppSettings {
  final ThemeMode themeMode;
  final ItemViewMode defaultViewMode;
  final int? gridColumns; // null means Auto
  final bool autoSaveEnabled;
  final String? tmdbApiKey;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.defaultViewMode = ItemViewMode.grid,
    this.gridColumns,
    this.autoSaveEnabled = true,
    this.tmdbApiKey,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    ItemViewMode? defaultViewMode,
    int? gridColumns,
    bool clearGridColumns = false,
    bool? autoSaveEnabled,
    String? tmdbApiKey,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      gridColumns: clearGridColumns ? null : (gridColumns ?? this.gridColumns),
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'defaultViewMode': defaultViewMode.name,
        'gridColumns': gridColumns,
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
        gridColumns: json['gridColumns'] as int?,
        autoSaveEnabled: json['autoSaveEnabled'] as bool? ?? true,
        tmdbApiKey: json['tmdbApiKey'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.themeMode == themeMode &&
          other.defaultViewMode == defaultViewMode &&
          other.gridColumns == gridColumns &&
          other.autoSaveEnabled == autoSaveEnabled &&
          other.tmdbApiKey == tmdbApiKey);

  @override
  int get hashCode => Object.hash(
        themeMode,
        defaultViewMode,
        gridColumns,
        autoSaveEnabled,
        tmdbApiKey,
      );
}
