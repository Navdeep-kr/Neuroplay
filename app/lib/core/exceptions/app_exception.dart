/// Sealed exception hierarchy for expected application failures.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}

/// Authentication-related failures.
class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
}

/// Network or connectivity failures.
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Data validation failures.
class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause]);
}

/// Resource not found.
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.cause]);
}

/// Permission denied.
class ForbiddenException extends AppException {
  const ForbiddenException(super.message, [super.cause]);
}
