class FieldError {
  final String fieldKey;
  final String code;
  final String message;

  const FieldError({
    required this.fieldKey,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'FieldError($fieldKey: [$code] $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldError &&
          other.fieldKey == fieldKey &&
          other.code == code &&
          other.message == message);

  @override
  int get hashCode => Object.hash(fieldKey, code, message);
}

sealed class ValidationResult {
  const ValidationResult();

  bool get isValid;
  bool get isInvalid => !isValid;
  List<FieldError> get errors;

  static const ValidationResult valid = _Valid();
  factory ValidationResult.invalid(List<FieldError> errors) = _Invalid;
}

final class _Valid extends ValidationResult {
  const _Valid();

  @override
  bool get isValid => true;

  @override
  List<FieldError> get errors => const [];
}

final class _Invalid extends ValidationResult {
  final List<FieldError> _errors;

  const _Invalid(this._errors);

  @override
  bool get isValid => false;

  @override
  List<FieldError> get errors => _errors;

  @override
  String toString() => 'ValidationResult.invalid(${_errors.join(', ')})';
}
