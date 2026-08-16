sealed class Failure {
  final String message;
  final String? code;

  const Failure(
    this.message, {
    this.code,
  });
}

final class ValidationFailure extends Failure {
  final List<String> errorCodes;
  const ValidationFailure(
    super.message, {
    super.code = 'VALIDATION_FAILURE',
    this.errorCodes = const [],
  });
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(
    super.message, {
    super.code = 'DATABASE_FAILURE',
  });
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(
    super.message, {
    super.code = 'NOT_FOUND',
  });
}

final class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code = 'NETWORK_FAILURE',
  });
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.code = 'UNEXPECTED_FAILURE',
  });
}
