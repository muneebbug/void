import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/schemas/domain/field_config.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema_field.dart';
import 'validation_result.dart';

class FieldValidator {
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  static final RegExp _urlRegex = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    caseSensitive: false,
  );

  /// Validates a single field value against its schema field definition
  static List<FieldError> validate(SchemaField field, FieldValue? value) {
    final List<FieldError> errors = [];
    final key = field.key;
    final label = field.label;

    // Check required
    if (field.required) {
      if (value == null || value.isEmpty || value is NullValue) {
        errors.add(
          FieldError(
            fieldKey: key,
            code: 'REQUIRED',
            message: '$label is required',
          ),
        );
        return errors;
      }
    }

    if (value == null || value is NullValue || value.isEmpty) {
      // Empty non-required fields are valid
      return errors;
    }

    // Type-specific and config-specific validation
    switch (field.type) {
      case FieldType.text:
      case FieldType.longText:
        if (value is TextValue || value is LongTextValue) {
          final str =
              value is TextValue ? value.value : (value as LongTextValue).value;
          final config = field.config;
          if (config is TextFieldConfig) {
            if (config.minLength != null && str.length < config.minLength!) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'MIN_LENGTH',
                  message:
                      '$label must be at least ${config.minLength} characters',
                ),
              );
            }
            if (config.maxLength != null && str.length > config.maxLength!) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'MAX_LENGTH',
                  message:
                      '$label cannot exceed ${config.maxLength} characters',
                ),
              );
            }
            if (config.pattern != null && config.pattern!.isNotEmpty) {
              final reg = RegExp(config.pattern!);
              if (!reg.hasMatch(str)) {
                errors.add(
                  FieldError(
                    fieldKey: key,
                    code: 'PATTERN_MISMATCH',
                    message: '$label does not match required format',
                  ),
                );
              }
            }
          }
        }
        break;

      case FieldType.number:
        if (value is NumberValue) {
          final numVal = value.value;
          final config = field.config;
          if (config is NumberFieldConfig) {
            if (config.min != null && numVal < config.min!) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'MIN_VALUE',
                  message: '$label must be at least ${config.min}',
                ),
              );
            }
            if (config.max != null && numVal > config.max!) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'MAX_VALUE',
                  message: '$label cannot exceed ${config.max}',
                ),
              );
            }
          }
        }
        break;

      case FieldType.rating:
        if (value is RatingValue) {
          final rating = value.value;
          final config = field.config;
          if (config is RatingFieldConfig) {
            if (rating < config.min) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'RATING_BELOW_MIN',
                  message: '$label rating cannot be below ${config.min}',
                ),
              );
            }
            if (rating > config.max) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'RATING_ABOVE_MAX',
                  message: '$label rating cannot exceed ${config.max}',
                ),
              );
            }
          }
        }
        break;

      case FieldType.select:
        if (value is SelectValue &&
            value.value != null &&
            value.value!.isNotEmpty) {
          final config = field.config;
          if (config is SelectFieldConfig && config.options.isNotEmpty) {
            if (!config.options.contains(value.value)) {
              errors.add(
                FieldError(
                  fieldKey: key,
                  code: 'INVALID_OPTION',
                  message:
                      '$label contains an invalid selection (${value.value})',
                ),
              );
            }
          }
        }
        break;

      case FieldType.multiSelect:
        if (value is MultiSelectValue) {
          final config = field.config;
          if (config is MultiSelectFieldConfig && config.options.isNotEmpty) {
            for (final opt in value.value) {
              if (!config.options.contains(opt)) {
                errors.add(
                  FieldError(
                    fieldKey: key,
                    code: 'INVALID_OPTION',
                    message: '$label contains invalid option: $opt',
                  ),
                );
              }
            }
          }
        }
        break;

      case FieldType.email:
        if (value is EmailValue && value.value.isNotEmpty) {
          if (!_emailRegex.hasMatch(value.value)) {
            errors.add(
              FieldError(
                fieldKey: key,
                code: 'INVALID_EMAIL',
                message: '$label must be a valid email address',
              ),
            );
          }
        }
        break;

      case FieldType.url:
        if (value is UrlValue && value.value.isNotEmpty) {
          final isUriValid = Uri.tryParse(value.value)?.hasScheme ?? false;
          if (!_urlRegex.hasMatch(value.value) && !isUriValid) {
            errors.add(
              FieldError(
                fieldKey: key,
                code: 'INVALID_URL',
                message: '$label must be a valid URL',
              ),
            );
          }
        }
        break;

      case FieldType.date:
      case FieldType.dateTime:
      case FieldType.boolean:
      case FieldType.image:
        // Already strongly typed through sealed FieldValue
        break;
    }

    return errors;
  }
}
