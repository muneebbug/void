import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _shortDate = DateFormat('MMM d, y');
  static final DateFormat _dateTime = DateFormat('MMM d, y HH:mm');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _yearOnly = DateFormat('y');

  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return _shortDate.format(date);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dateTime.format(dateTime);
  }

  static String formatIso(DateTime? date) {
    if (date == null) return '';
    return _isoDate.format(date);
  }

  static String formatYear(DateTime? date) {
    if (date == null) return '';
    return _yearOnly.format(date);
  }

  static DateTime? parseIso(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
