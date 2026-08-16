import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/domain/schema.dart';
import 'field_validator.dart';
import 'validation_result.dart';

class Validator {
  /// Validates an Item and all its dynamic field values against its schema
  static ValidationResult validateItem(Item item, Schema schema) {
    final List<FieldError> errors = [];

    // Validate title
    if (item.title.trim().isEmpty) {
      errors.add(
        const FieldError(
          fieldKey: 'title',
          code: 'REQUIRED',
          message: 'Title is required',
        ),
      );
    } else if (item.title.length > 2000) {
      errors.add(
        const FieldError(
          fieldKey: 'title',
          code: 'MAX_LENGTH',
          message: 'Title cannot exceed 2000 characters',
        ),
      );
    }

    // Validate each schema field
    for (final field in schema.fields) {
      final value = item.data[field.key];
      final fieldErrors = FieldValidator.validate(field, value);
      errors.addAll(fieldErrors);
    }

    if (errors.isEmpty) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid(errors);
  }

  /// Validates a Collection
  static ValidationResult validateCollection(Collection collection) {
    final List<FieldError> errors = [];
    if (collection.name.trim().isEmpty) {
      errors.add(
        const FieldError(
          fieldKey: 'name',
          code: 'REQUIRED',
          message: 'Collection name is required',
        ),
      );
    } else if (collection.name.length > 255) {
      errors.add(
        const FieldError(
          fieldKey: 'name',
          code: 'MAX_LENGTH',
          message: 'Collection name cannot exceed 255 characters',
        ),
      );
    }

    if (errors.isEmpty) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid(errors);
  }

  /// Validates a Schema and its field definitions
  static ValidationResult validateSchema(Schema schema) {
    final List<FieldError> errors = [];
    if (schema.name.trim().isEmpty) {
      errors.add(
        const FieldError(
          fieldKey: 'name',
          code: 'REQUIRED',
          message: 'Schema name is required',
        ),
      );
    }

    final Set<String> fieldKeys = {};
    for (final field in schema.fields) {
      if (field.key.trim().isEmpty) {
        errors.add(
          FieldError(
            fieldKey: field.id,
            code: 'KEY_REQUIRED',
            message: 'Field key is required',
          ),
        );
      } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(field.key)) {
        errors.add(
          FieldError(
            fieldKey: field.key,
            code: 'INVALID_KEY_FORMAT',
            message:
                'Field key "${field.key}" must contain only alphanumeric characters and underscores',
          ),
        );
      } else if (fieldKeys.contains(field.key)) {
        errors.add(
          FieldError(
            fieldKey: field.key,
            code: 'DUPLICATE_KEY',
            message: 'Duplicate field key: "${field.key}"',
          ),
        );
      }
      fieldKeys.add(field.key);

      if (field.label.trim().isEmpty) {
        errors.add(
          FieldError(
            fieldKey: field.key,
            code: 'LABEL_REQUIRED',
            message: 'Field label is required for "${field.key}"',
          ),
        );
      }
    }

    if (errors.isEmpty) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid(errors);
  }
}
