sealed class FieldConfig {
  const FieldConfig();

  Map<String, dynamic> toJson();

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'text':
        return TextFieldConfig.fromJson(json);
      case 'number':
        return NumberFieldConfig.fromJson(json);
      case 'rating':
        return RatingFieldConfig.fromJson(json);
      case 'select':
        return SelectFieldConfig.fromJson(json);
      case 'multiSelect':
        return MultiSelectFieldConfig.fromJson(json);
      case 'date':
        return DateFieldConfig.fromJson(json);
      default:
        return const NoneFieldConfig();
    }
  }

  const factory FieldConfig.text({
    int? minLength,
    int? maxLength,
    String? placeholder,
    String? pattern,
  }) = TextFieldConfig;

  const factory FieldConfig.number({
    double? min,
    double? max,
    double? step,
    String? unit,
  }) = NumberFieldConfig;

  const factory FieldConfig.rating({
    double min,
    double max,
    double step,
  }) = RatingFieldConfig;

  const factory FieldConfig.select({
    List<String> options,
  }) = SelectFieldConfig;

  const factory FieldConfig.multiSelect({
    List<String> options,
  }) = MultiSelectFieldConfig;

  const factory FieldConfig.date({
    DateTime? minDate,
    DateTime? maxDate,
  }) = DateFieldConfig;

  const factory FieldConfig.none() = NoneFieldConfig;
}

final class TextFieldConfig extends FieldConfig {
  final int? minLength;
  final int? maxLength;
  final String? placeholder;
  final String? pattern;

  const TextFieldConfig({
    this.minLength,
    this.maxLength,
    this.placeholder,
    this.pattern,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'minLength': minLength,
        'maxLength': maxLength,
        'placeholder': placeholder,
        'pattern': pattern,
      };

  factory TextFieldConfig.fromJson(Map<String, dynamic> json) =>
      TextFieldConfig(
        minLength: (json['minLength'] as num?)?.toInt(),
        maxLength: (json['maxLength'] as num?)?.toInt(),
        placeholder: json['placeholder'] as String?,
        pattern: json['pattern'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextFieldConfig &&
          other.minLength == minLength &&
          other.maxLength == maxLength &&
          other.placeholder == placeholder &&
          other.pattern == pattern);

  @override
  int get hashCode => Object.hash(minLength, maxLength, placeholder, pattern);
}

final class NumberFieldConfig extends FieldConfig {
  final double? min;
  final double? max;
  final double? step;
  final String? unit;

  const NumberFieldConfig({
    this.min,
    this.max,
    this.step,
    this.unit,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'number',
        'min': min,
        'max': max,
        'step': step,
        'unit': unit,
      };

  factory NumberFieldConfig.fromJson(Map<String, dynamic> json) =>
      NumberFieldConfig(
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
        step: (json['step'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NumberFieldConfig &&
          other.min == min &&
          other.max == max &&
          other.step == step &&
          other.unit == unit);

  @override
  int get hashCode => Object.hash(min, max, step, unit);
}

final class RatingFieldConfig extends FieldConfig {
  final double min;
  final double max;
  final double step;

  const RatingFieldConfig({
    this.min = 0.0,
    this.max = 5.0,
    this.step = 1.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rating',
        'min': min,
        'max': max,
        'step': step,
      };

  factory RatingFieldConfig.fromJson(Map<String, dynamic> json) =>
      RatingFieldConfig(
        min: (json['min'] as num?)?.toDouble() ?? 0.0,
        max: (json['max'] as num?)?.toDouble() ?? 5.0,
        step: (json['step'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingFieldConfig &&
          other.min == min &&
          other.max == max &&
          other.step == step);

  @override
  int get hashCode => Object.hash(min, max, step);
}

final class SelectFieldConfig extends FieldConfig {
  final List<String> options;

  const SelectFieldConfig({this.options = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'select',
        'options': options,
      };

  factory SelectFieldConfig.fromJson(Map<String, dynamic> json) =>
      SelectFieldConfig(
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectFieldConfig &&
          other.options.length == options.length &&
          other.options.every(options.contains));

  @override
  int get hashCode => Object.hashAll(options);
}

final class MultiSelectFieldConfig extends FieldConfig {
  final List<String> options;

  const MultiSelectFieldConfig({this.options = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'multiSelect',
        'options': options,
      };

  factory MultiSelectFieldConfig.fromJson(Map<String, dynamic> json) =>
      MultiSelectFieldConfig(
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MultiSelectFieldConfig &&
          other.options.length == options.length &&
          other.options.every(options.contains));

  @override
  int get hashCode => Object.hashAll(options);
}

final class DateFieldConfig extends FieldConfig {
  final DateTime? minDate;
  final DateTime? maxDate;

  const DateFieldConfig({this.minDate, this.maxDate});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'date',
        'minDate': minDate?.toIso8601String(),
        'maxDate': maxDate?.toIso8601String(),
      };

  factory DateFieldConfig.fromJson(Map<String, dynamic> json) =>
      DateFieldConfig(
        minDate: DateTime.tryParse(json['minDate']?.toString() ?? ''),
        maxDate: DateTime.tryParse(json['maxDate']?.toString() ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateFieldConfig &&
          other.minDate == minDate &&
          other.maxDate == maxDate);

  @override
  int get hashCode => Object.hash(minDate, maxDate);
}

final class NoneFieldConfig extends FieldConfig {
  const NoneFieldConfig();

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};

  @override
  bool operator ==(Object other) => other is NoneFieldConfig;

  @override
  int get hashCode => 0;
}
