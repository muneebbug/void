import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/core/serialization/field_value_serializer.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/schemas/domain/field_config.dart';

void main() {
  group('FieldValue Serializer Tests (12 types)', () {
    test('roundtrips text field value', () {
      const val = FieldValue.text('The Matrix');
      final json = val.toJson();
      final restored = FieldValue.fromJson(json);
      expect(restored, equals(val));
    });

    test('roundtrips longText field value', () {
      const val = FieldValue.longText(
        'A comprehensive analysis of desktop UI architectures...',
      );
      final json = val.toJson();
      final restored = FieldValue.fromJson(json);
      expect(restored, equals(val));
    });

    test('roundtrips number field value', () {
      const val = FieldValue.number(1999.5);
      final json = val.toJson();
      final restored = FieldValue.fromJson(json);
      expect(restored, equals(val));
    });

    test('roundtrips boolean field value', () {
      const valTrue = FieldValue.boolean(true);
      const valFalse = FieldValue.boolean(false);
      expect(FieldValue.fromJson(valTrue.toJson()), equals(valTrue));
      expect(FieldValue.fromJson(valFalse.toJson()), equals(valFalse));
    });

    test('roundtrips rating field value', () {
      const val = FieldValue.rating(4.8);
      final json = val.toJson();
      final restored = FieldValue.fromJson(json);
      expect(restored, equals(val));
    });

    test('roundtrips date and dateTime field values', () {
      final dateVal = FieldValue.date(DateTime(2026, 8, 16));
      final dateTimeVal = FieldValue.dateTime(DateTime(2026, 8, 16, 15, 30, 0));

      expect(FieldValue.fromJson(dateVal.toJson()), equals(dateVal));
      expect(FieldValue.fromJson(dateTimeVal.toJson()), equals(dateTimeVal));
    });

    test('roundtrips select and multiSelect field values', () {
      const selectVal = FieldValue.select('Sci-Fi');
      const multiVal =
          FieldValue.multiSelect(['Action', 'Sci-Fi', 'Cyberpunk']);

      expect(FieldValue.fromJson(selectVal.toJson()), equals(selectVal));
      expect(FieldValue.fromJson(multiVal.toJson()), equals(multiVal));
    });

    test('roundtrips url, email, and image field values', () {
      const urlVal = FieldValue.url('https://void.app');
      const emailVal = FieldValue.email('dev@void.app');
      const imageVal = FieldValue.image('https://void.app/cover.jpg');

      expect(FieldValue.fromJson(urlVal.toJson()), equals(urlVal));
      expect(FieldValue.fromJson(emailVal.toJson()), equals(emailVal));
      expect(FieldValue.fromJson(imageVal.toJson()), equals(imageVal));
    });

    test('FieldValueSerializer map serialization and deserialization', () {
      final map = <String, FieldValue>{
        'director': const FieldValue.text('Lana Wachowski'),
        'year': const FieldValue.number(1999),
        'rating': const FieldValue.rating(5.0),
        'genres': const FieldValue.multiSelect(['Action', 'Sci-Fi']),
        'is_favorite': const FieldValue.boolean(true),
      };

      final serializedString = FieldValueSerializer.toJsonString(map);
      final deserializedMap =
          FieldValueSerializer.fromJsonString(serializedString);

      expect(deserializedMap.length, equals(5));
      expect(
        deserializedMap['director'],
        equals(const FieldValue.text('Lana Wachowski')),
      );
      expect(deserializedMap['year'], equals(const FieldValue.number(1999)));
      expect(
        deserializedMap['genres'],
        equals(const FieldValue.multiSelect(['Action', 'Sci-Fi'])),
      );
    });
  });

  group('FieldConfig Serializer Tests', () {
    test('roundtrips TextFieldConfig', () {
      const config = TextFieldConfig(
        minLength: 2,
        maxLength: 50,
        placeholder: 'Enter name',
      );
      final json = config.toJson();
      final restored = FieldConfig.fromJson(json);
      expect(restored, equals(config));
    });

    test('roundtrips NumberFieldConfig', () {
      const config = NumberFieldConfig(min: 0, max: 100, step: 0.5, unit: 'kg');
      final json = config.toJson();
      final restored = FieldConfig.fromJson(json);
      expect(restored, equals(config));
    });

    test('roundtrips RatingFieldConfig', () {
      const config = RatingFieldConfig(min: 1, max: 10, step: 0.5);
      final json = config.toJson();
      final restored = FieldConfig.fromJson(json);
      expect(restored, equals(config));
    });

    test('roundtrips SelectFieldConfig and MultiSelectFieldConfig', () {
      const sel = SelectFieldConfig(options: ['A', 'B', 'C']);
      const multi = MultiSelectFieldConfig(options: ['X', 'Y', 'Z']);

      expect(FieldConfig.fromJson(sel.toJson()), equals(sel));
      expect(FieldConfig.fromJson(multi.toJson()), equals(multi));
    });
  });
}
