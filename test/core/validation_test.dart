import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/core/validation/field_validator.dart';
import 'package:void_app/core/validation/validator.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/domain/field_config.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema.dart';
import 'package:void_app/features/schemas/domain/schema_field.dart';

void main() {
  group('FieldValidator Tests', () {
    final now = DateTime.now();

    test('TextFieldConfig validates minLength and maxLength', () {
      final field = SchemaField(
        id: 'f1',
        schemaId: 's1',
        key: 'username',
        label: 'Username',
        type: FieldType.text,
        config: const TextFieldConfig(minLength: 3, maxLength: 6),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(FieldValidator.validate(field, null), isEmpty);
      expect(
        FieldValidator.validate(field, const FieldValue.text('ab')),
        isNotEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.text('abc')),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.text('abcdef')),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.text('abcdefg')),
        isNotEmpty,
      );
    });

    test('NumberFieldConfig validates min and max bounds', () {
      final field = SchemaField(
        id: 'f2',
        schemaId: 's1',
        key: 'age',
        label: 'Age',
        type: FieldType.number,
        config: const NumberFieldConfig(min: 10, max: 50),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        FieldValidator.validate(field, const FieldValue.number(5)),
        isNotEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.number(10)),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.number(30)),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.number(50)),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.number(51)),
        isNotEmpty,
      );
    });

    test('RatingFieldConfig validates bounds', () {
      final field = SchemaField(
        id: 'f3',
        schemaId: 's1',
        key: 'score',
        label: 'Score',
        type: FieldType.rating,
        config: const RatingFieldConfig(min: 0, max: 5),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        FieldValidator.validate(field, const FieldValue.rating(-0.5)),
        isNotEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.rating(0.0)),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.rating(4.5)),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.rating(5.0)),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.rating(5.5)),
        isNotEmpty,
      );
    });

    test('SelectFieldConfig validates options membership', () {
      final field = SchemaField(
        id: 'f4',
        schemaId: 's1',
        key: 'genre',
        label: 'Genre',
        type: FieldType.select,
        config: const SelectFieldConfig(options: ['Sci-Fi', 'Drama', 'Action']),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        FieldValidator.validate(field, const FieldValue.select('Drama')),
        isEmpty,
      );
      expect(
        FieldValidator.validate(field, const FieldValue.select('Comedy')),
        isNotEmpty,
      );
    });

    test('MultiSelectFieldConfig validates allowed options', () {
      final field = SchemaField(
        id: 'f5',
        schemaId: 's1',
        key: 'skills',
        label: 'Skills',
        type: FieldType.multiSelect,
        config:
            const MultiSelectFieldConfig(options: ['Dart', 'Flutter', 'Rust']),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        FieldValidator.validate(
          field,
          const FieldValue.multiSelect(['Dart', 'Rust']),
        ),
        isEmpty,
      );
      expect(
        FieldValidator.validate(
          field,
          const FieldValue.multiSelect(['Dart', 'Python']),
        ),
        isNotEmpty,
      );
    });

    test('Url FieldType validates URL format', () {
      final field = SchemaField(
        id: 'f6',
        schemaId: 's1',
        key: 'website',
        label: 'Website',
        type: FieldType.url,
        config: const NoneFieldConfig(),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        FieldValidator.validate(
          field,
          const FieldValue.url('https://flutter.dev'),
        ),
        isEmpty,
      );
      expect(
        FieldValidator.validate(
          field,
          const FieldValue.url('not a valid url'),
        ),
        isNotEmpty,
      );
    });

    test('Email FieldType validates email syntax', () {
      final field = SchemaField(
        id: 'f7',
        schemaId: 's1',
        key: 'email',
        label: 'Email',
        type: FieldType.email,
        config: const NoneFieldConfig(),
        required: false,
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        FieldValidator.validate(
          field,
          const FieldValue.email('test@void.local'),
        ),
        isEmpty,
      );
      expect(
        FieldValidator.validate(
          field,
          const FieldValue.email('plainaddress'),
        ),
        isNotEmpty,
      );
    });
  });

  group('Validator Entity Tests', () {
    final now = DateTime.now();

    final testSchema = Schema(
      id: 'schema_1',
      name: 'Book',
      fields: [
        SchemaField(
          id: 'f1',
          schemaId: 'schema_1',
          key: 'author',
          label: 'Author',
          type: FieldType.text,
          required: true,
          config: const TextFieldConfig(minLength: 2),
          position: 0,
          createdAt: now,
          updatedAt: now,
        ),
        SchemaField(
          id: 'f2',
          schemaId: 'schema_1',
          key: 'pages',
          label: 'Pages',
          type: FieldType.number,
          required: false,
          config: const NumberFieldConfig(min: 1),
          position: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    test('validates valid item successfully', () {
      final item = Item(
        id: 'item_1',
        collectionId: 'col_1',
        schemaId: 'schema_1',
        title: 'Clean Code',
        data: {
          'author': const FieldValue.text('Robert C. Martin'),
          'pages': const FieldValue.number(464),
        },
        createdAt: now,
        updatedAt: now,
      );

      final result = Validator.validateItem(item, testSchema);
      expect(result.isValid, isTrue);
    });

    test('fails validation when required field is missing', () {
      final item = Item(
        id: 'item_1',
        collectionId: 'col_1',
        schemaId: 'schema_1',
        title: 'Untitled Book',
        data: {
          'pages': const FieldValue.number(200),
        },
        createdAt: now,
        updatedAt: now,
      );

      final result = Validator.validateItem(item, testSchema);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.fieldKey == 'author'), isTrue);
    });

    test('fails validation when field constraint is violated', () {
      final item = Item(
        id: 'item_1',
        collectionId: 'col_1',
        schemaId: 'schema_1',
        title: 'A Book',
        data: {
          'author': const FieldValue.text('A'), // minLength is 2
        },
        createdAt: now,
        updatedAt: now,
      );

      final result = Validator.validateItem(item, testSchema);
      expect(result.isValid, isFalse);
      final authorErr = result.errors.firstWhere((e) => e.fieldKey == 'author');
      expect(authorErr.message, contains('at least 2 characters'));
    });
  });
}
