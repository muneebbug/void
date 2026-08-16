import 'dart:convert';
import 'package:void_app/core/utils/date_formatter.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema_field.dart';

class FieldValueSerializer {
  /// Converts a Map<String, FieldValue> to a JSON String for SQLite storage
  static String toJsonString(Map<String, FieldValue> data) {
    final rawMap = toRawMap(data);
    return jsonEncode(rawMap);
  }

  /// Converts a Map<String, FieldValue> to Map<String, dynamic>
  static Map<String, dynamic> toRawMap(Map<String, FieldValue> data) {
    final Map<String, dynamic> result = {};
    for (final entry in data.entries) {
      result[entry.key] = entry.value.toRawValue();
    }
    return result;
  }

  /// Parses a JSON string from SQLite into typed Map<String, FieldValue> given the SchemaFields
  static Map<String, FieldValue> fromJsonString(
    String jsonString, {
    List<SchemaField> schemaFields = const [],
  }) {
    if (jsonString.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return fromRawMap(decoded, schemaFields: schemaFields);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Parses a raw Map<String, dynamic> into Map<String, FieldValue>
  static Map<String, FieldValue> fromRawMap(
    Map<String, dynamic> rawMap, {
    List<SchemaField> schemaFields = const [],
  }) {
    final Map<String, FieldValue> result = {};
    final fieldTypeMap = {for (final f in schemaFields) f.key: f.type};

    for (final entry in rawMap.entries) {
      final key = entry.key;
      final rawValue = entry.value;
      final expectedType = fieldTypeMap[key];

      if (rawValue == null) {
        result[key] = const NullValue();
        continue;
      }

      if (expectedType != null) {
        result[key] = _parseTypedValue(rawValue, expectedType);
      } else {
        result[key] = _inferValue(rawValue);
      }
    }

    return result;
  }

  static FieldValue _parseTypedValue(dynamic raw, FieldType type) {
    if (raw == null) return const NullValue();

    switch (type) {
      case FieldType.text:
        return TextValue(raw.toString());
      case FieldType.longText:
        return LongTextValue(raw.toString());
      case FieldType.number:
        if (raw is num) return NumberValue(raw.toDouble());
        final parsed = double.tryParse(raw.toString()) ?? 0.0;
        return NumberValue(parsed);
      case FieldType.boolean:
        if (raw is bool) return BooleanValue(raw);
        if (raw is num) return BooleanValue(raw != 0);
        return BooleanValue(raw.toString().toLowerCase() == 'true');
      case FieldType.date:
        if (raw is DateTime) return DateValue(raw);
        return DateValue(DateFormatter.parseIso(raw.toString()));
      case FieldType.dateTime:
        if (raw is DateTime) return DateTimeValue(raw);
        return DateTimeValue(DateFormatter.parseIso(raw.toString()));
      case FieldType.rating:
        if (raw is num) return RatingValue(raw.toDouble());
        final parsed = double.tryParse(raw.toString()) ?? 0.0;
        return RatingValue(parsed);
      case FieldType.select:
        return SelectValue(raw.toString());
      case FieldType.multiSelect:
        if (raw is List) {
          return MultiSelectValue(raw.map((e) => e.toString()).toList());
        }
        return MultiSelectValue([raw.toString()]);
      case FieldType.url:
        return UrlValue(raw.toString());
      case FieldType.email:
        return EmailValue(raw.toString());
      case FieldType.image:
        return ImageValue(raw.toString());
    }
  }

  static FieldValue _inferValue(dynamic raw) {
    if (raw == null) return const NullValue();
    if (raw is bool) return BooleanValue(raw);
    if (raw is num) return NumberValue(raw.toDouble());
    if (raw is List) {
      return MultiSelectValue(raw.map((e) => e.toString()).toList());
    }
    final str = raw.toString();
    return TextValue(str);
  }
}
