import 'package:equatable/equatable.dart';

/// Represents a domain-level failure with a user-facing message.
class Failure extends Equatable {
  const Failure(this.message, [this.code]);

  /// User-safe error message.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure($code: $message)';
}
