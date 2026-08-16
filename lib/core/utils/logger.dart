import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'VOID', level: 800);
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'VOID',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'VOID',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
