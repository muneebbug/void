import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:void_app/core/utils/logger.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}

class FileSettingsRepository implements SettingsRepository {
  AppSettings? _cached;

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'void_settings.json'));
    return file;
  }

  @override
  Future<AppSettings> loadSettings() async {
    if (_cached != null) return _cached!;

    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _cached = AppSettings.fromJson(json);
        return _cached!;
      }
    } catch (e) {
      AppLogger.warning('Could not load settings file, using defaults: $e');
    }

    _cached = const AppSettings();
    return _cached!;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _cached = settings;
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (e) {
      AppLogger.error('Failed to save settings file: $e');
    }
  }
}
