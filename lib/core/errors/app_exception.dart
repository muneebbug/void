class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() =>
      'AppException${code != null ? ' [$code]' : ''}: $message${details != null ? ' ($details)' : ''}';
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code = 'DATABASE_ERROR',
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code = 'NOT_FOUND',
    super.details,
  });
}

class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.code = 'CONFLICT',
    super.details,
  });
}

class SerializationException extends AppException {
  const SerializationException(
    super.message, {
    super.code = 'SERIALIZATION_ERROR',
    super.details,
  });
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}
