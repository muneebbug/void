import 'package:void_app/core/utils/date_formatter.dart';

sealed class FieldValue {
  const FieldValue();

  const factory FieldValue.text(String value) = TextValue;
  const factory FieldValue.longText(String value) = LongTextValue;
  const factory FieldValue.number(double value) = NumberValue;
  const factory FieldValue.boolean(bool value) = BooleanValue;
  const factory FieldValue.date(DateTime? value) = DateValue;
  const factory FieldValue.dateTime(DateTime? value) = DateTimeValue;
  const factory FieldValue.rating(double value) = RatingValue;
  const factory FieldValue.select(String? value) = SelectValue;
  const factory FieldValue.multiSelect(List<String> value) = MultiSelectValue;
  const factory FieldValue.url(String value) = UrlValue;
  const factory FieldValue.email(String value) = EmailValue;
  const factory FieldValue.image(String value) = ImageValue;
  const factory FieldValue.nullValue() = NullValue;

  dynamic toRawValue();
  String toDisplayString();
  bool get isEmpty;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson();

  factory FieldValue.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final raw = json['value'];

    switch (type) {
      case 'text':
        return TextValue(raw?.toString() ?? '');
      case 'longText':
        return LongTextValue(raw?.toString() ?? '');
      case 'number':
        return NumberValue((raw as num?)?.toDouble() ?? 0.0);
      case 'boolean':
        return BooleanValue(raw == true);
      case 'date':
        return DateValue(
          raw != null ? DateTime.tryParse(raw.toString()) : null,
        );
      case 'dateTime':
        return DateTimeValue(
          raw != null ? DateTime.tryParse(raw.toString()) : null,
        );
      case 'rating':
        return RatingValue((raw as num?)?.toDouble() ?? 0.0);
      case 'select':
        return SelectValue(raw?.toString());
      case 'multiSelect':
        return MultiSelectValue(
          (raw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      case 'url':
        return UrlValue(raw?.toString() ?? '');
      case 'email':
        return EmailValue(raw?.toString() ?? '');
      case 'image':
        return ImageValue(raw?.toString() ?? '');
      default:
        return const NullValue();
    }
  }

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

final class TextValue extends FieldValue {
  final String value;
  const TextValue(this.value);

  @override
  String toRawValue() => value;

  @override
  String toDisplayString() => value;

  @override
  bool get isEmpty => value.trim().isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TextValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TextValue($value)';
}

final class LongTextValue extends FieldValue {
  final String value;
  const LongTextValue(this.value);

  @override
  String toRawValue() => value;

  @override
  String toDisplayString() => value;

  @override
  bool get isEmpty => value.trim().isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'longText', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LongTextValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'LongTextValue($value)';
}

final class NumberValue extends FieldValue {
  final double value;
  const NumberValue(this.value);

  @override
  double toRawValue() => value;

  @override
  String toDisplayString() {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  bool get isEmpty => false;

  @override
  Map<String, dynamic> toJson() => {'type': 'number', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NumberValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NumberValue($value)';
}

final class BooleanValue extends FieldValue {
  final bool value;
  const BooleanValue(this.value);

  @override
  bool toRawValue() => value;

  @override
  String toDisplayString() => value ? 'Yes' : 'No';

  @override
  bool get isEmpty => false;

  @override
  Map<String, dynamic> toJson() => {'type': 'boolean', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BooleanValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BooleanValue($value)';
}

final class DateValue extends FieldValue {
  final DateTime? value;
  const DateValue(this.value);

  @override
  String? toRawValue() => value != null ? DateFormatter.formatIso(value) : null;

  @override
  String toDisplayString() =>
      value != null ? DateFormatter.formatShortDate(value) : '';

  @override
  bool get isEmpty => value == null;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'date',
        'value': value != null ? DateFormatter.formatIso(value) : null,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DateValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DateValue($value)';
}

final class DateTimeValue extends FieldValue {
  final DateTime? value;
  const DateTimeValue(this.value);

  @override
  String? toRawValue() => value?.toIso8601String();

  @override
  String toDisplayString() =>
      value != null ? DateFormatter.formatDateTime(value) : '';

  @override
  bool get isEmpty => value == null;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dateTime',
        'value': value?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateTimeValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DateTimeValue($value)';
}

final class RatingValue extends FieldValue {
  final double value;
  const RatingValue(this.value);

  @override
  double toRawValue() => value;

  @override
  String toDisplayString() {
    final rounded = (value * 10).round() / 10.0;
    final formatted =
        rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toStringAsFixed(1);
    if (value > 5.0) {
      return '$formatted / 10';
    }
    return '$formatted / 5';
  }

  @override
  bool get isEmpty => false;

  @override
  Map<String, dynamic> toJson() => {'type': 'rating', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RatingValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RatingValue($value)';
}

final class SelectValue extends FieldValue {
  final String? value;
  const SelectValue(this.value);

  @override
  String? toRawValue() => value;

  @override
  String toDisplayString() => value ?? '';

  @override
  bool get isEmpty => value == null || value!.trim().isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'select', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SelectValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SelectValue($value)';
}

final class MultiSelectValue extends FieldValue {
  final List<String> value;
  const MultiSelectValue(this.value);

  @override
  List<String> toRawValue() => value;

  @override
  String toDisplayString() => value.join(', ');

  @override
  bool get isEmpty => value.isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'multiSelect', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MultiSelectValue &&
          other.value.length == value.length &&
          other.value.every(value.contains));

  @override
  int get hashCode => Object.hashAll(value);

  @override
  String toString() => 'MultiSelectValue($value)';
}

final class UrlValue extends FieldValue {
  final String value;
  const UrlValue(this.value);

  @override
  String toRawValue() => value;

  @override
  String toDisplayString() => value;

  @override
  bool get isEmpty => value.trim().isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'url', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UrlValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UrlValue($value)';
}

final class EmailValue extends FieldValue {
  final String value;
  const EmailValue(this.value);

  @override
  String toRawValue() => value;

  @override
  String toDisplayString() => value;

  @override
  bool get isEmpty => value.trim().isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'email', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EmailValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'EmailValue($value)';
}

final class ImageValue extends FieldValue {
  final String value;
  const ImageValue(this.value);

  @override
  String toRawValue() => value;

  @override
  String toDisplayString() => value;

  @override
  bool get isEmpty => value.trim().isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'image', 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ImageValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ImageValue($value)';
}

final class NullValue extends FieldValue {
  const NullValue();

  @override
  dynamic toRawValue() => null;

  @override
  String toDisplayString() => '';

  @override
  bool get isEmpty => true;

  @override
  Map<String, dynamic> toJson() => {'type': 'null', 'value': null};

  @override
  bool operator ==(Object other) => other is NullValue;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NullValue()';
}
