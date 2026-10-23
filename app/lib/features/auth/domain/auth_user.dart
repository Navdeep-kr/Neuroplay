import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Primary authentication state enum.
enum AuthStatus {
  /// User is not logged in and has not entered guest mode.
  unauthenticated,

  /// User is exploring the application without cloud sync credentials.
  guest,

  /// User is verified with an active Supabase Auth session.
  authenticated,
}

/// Represents the active user identity within NEUROPLAY.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.status,
    this.email,
    this.displayName,
    this.isEmailConfirmed = false,
  });

  /// Factory for an unauthenticated state.
  factory AuthUser.unauthenticated() => const AuthUser(
        id: '',
        status: AuthStatus.unauthenticated,
      );

  /// Factory for a local guest user.
  factory AuthUser.guest({String? id}) => AuthUser(
        id: id ?? 'guest-local-user',
        status: AuthStatus.guest,
        displayName: 'Alex',
      );

  /// Factory converting a Supabase Auth `User`.
  factory AuthUser.fromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    final fullName = meta['full_name'] as String?;
    final email = user.email;

    return AuthUser(
      id: user.id,
      status: AuthStatus.authenticated,
      email: email,
      displayName:
          fullName ?? (email != null ? email.split('@').first : 'User'),
      isEmailConfirmed: user.emailConfirmedAt != null,
    );
  }

  /// Unique user identifier (UUID in Supabase, or prefixed local ID in guest mode).
  final String id;

  /// Authentication lifecycle status.
  final AuthStatus status;

  /// Primary email address (null for guests).
  final String? email;

  /// User's preferred display name.
  final String? displayName;

  /// Confirmation status from Supabase Auth.
  final bool isEmailConfirmed;

  /// Whether the user is in local guest mode.
  bool get isGuest => status == AuthStatus.guest;

  /// Whether the user has a verified cloud session.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthUser copyWith({
    String? id,
    AuthStatus? status,
    String? email,
    String? displayName,
    bool? isEmailConfirmed,
  }) =>
      AuthUser(
        id: id ?? this.id,
        status: status ?? this.status,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        isEmailConfirmed: isEmailConfirmed ?? this.isEmailConfirmed,
      );

  @override
  List<Object?> get props => [
        id,
        status,
        email,
        displayName,
        isEmailConfirmed,
      ];
}
