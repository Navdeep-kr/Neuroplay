import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/exceptions/app_exception.dart';
import 'package:neuroplay/core/network/supabase_client.dart';
import 'package:neuroplay/core/utils/logger.dart';
import 'package:neuroplay/features/auth/domain/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Interface defining identity and authentication capabilities.
abstract interface class IAuthRepository {
  /// Stream emitting user state transitions.
  Stream<AuthUser> get authStateChanges;

  /// Current user snapshot.
  AuthUser get currentUser;

  /// Sign in using registered email and password credentials.
  Future<AuthUser> signInWithPassword({
    required String email,
    required String password,
  });

  /// Register a new account with email, password, and optional full name.
  Future<AuthUser> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  });

  /// Send password recovery reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email);

  /// Activates an offline/local guest session without cloud persistence.
  void enterGuestMode();

  /// Terminate the active session, clearing cloud and local cached credentials.
  Future<void> signOut();

  /// Permanently delete the user account via trusted server-side Edge Function.
  Future<void> deleteAccount();
}

/// Production Supabase-backed implementation of [IAuthRepository].
class SupabaseAuthRepository implements IAuthRepository {
  SupabaseAuthRepository({sb.SupabaseClient? client})
      : _client = client ?? SupabaseConfig.clientOrNull {
    _initAuthSubscription();
  }

  final sb.SupabaseClient? _client;
  final StreamController<AuthUser> _authController =
      StreamController<AuthUser>.broadcast();
  StreamSubscription<sb.AuthState>? _sub;

  AuthUser _currentUser = AuthUser.unauthenticated();

  void _initAuthSubscription() {
    if (_client != null) {
      final initialUser = _client.auth.currentUser;
      if (initialUser != null) {
        _currentUser = AuthUser.fromSupabase(initialUser);
      }

      _sub = _client.auth.onAuthStateChange.listen(
        (data) {
          final session = data.session;
          if (session != null) {
            _currentUser = AuthUser.fromSupabase(session.user);
          } else if (!_currentUser.isGuest) {
            _currentUser = AuthUser.unauthenticated();
          }
          _authController.add(_currentUser);
        },
        onError: (Object err, StackTrace st) {
          AppLogger.error(
            'Supabase auth state stream error: $err',
            tag: 'AuthRepository',
            error: err,
            stackTrace: st,
          );
        },
      );
    }
  }

  @override
  Stream<AuthUser> get authStateChanges => _authController.stream;

  @override
  AuthUser get currentUser => _currentUser;

  @override
  void enterGuestMode() {
    _currentUser = AuthUser.guest();
    _authController.add(_currentUser);
    AppLogger.info('Entered local guest mode.', tag: 'AuthRepository');
  }

  @override
  Future<AuthUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      // Local preview simulation if environment is unconfigured
      AppLogger.warning(
        'Supabase client not configured. Simulating successful local sign-in.',
      );
      _currentUser = AuthUser(
        id: 'simulated-user-id',
        status: AuthStatus.authenticated,
        email: email,
        displayName: email.split('@').first,
        isEmailConfirmed: true,
      );
      _authController.add(_currentUser);
      return _currentUser;
    }

    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException(
          'Sign-in failed: No user returned by server.',
        );
      }

      _currentUser = AuthUser.fromSupabase(user);
      _authController.add(_currentUser);
      return _currentUser;
    } on sb.AuthException catch (e) {
      AppLogger.warning('Sign-in auth exception: ${e.message}');
      throw AuthException(e.message, e);
    } catch (e, st) {
      AppLogger.error(
        'Unexpected sign-in failure',
        error: e,
        stackTrace: st,
      );
      throw AuthException('An unexpected error occurred during sign-in.', e);
    }
  }

  @override
  Future<AuthUser> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (_client == null) {
      AppLogger.warning(
        'Supabase client not configured. Simulating successful local sign-up.',
      );
      _currentUser = AuthUser(
        id: 'simulated-user-id',
        status: AuthStatus.authenticated,
        email: email,
        displayName: fullName ?? email.split('@').first,
      );
      _authController.add(_currentUser);
      return _currentUser;
    }

    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName.trim()} : null,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Registration failed: No user created.');
      }

      _currentUser = AuthUser.fromSupabase(user);
      _authController.add(_currentUser);
      return _currentUser;
    } on sb.AuthException catch (e) {
      AppLogger.warning('Sign-up auth exception: ${e.message}');
      throw AuthException(e.message, e);
    } catch (e, st) {
      AppLogger.error(
        'Unexpected sign-up failure',
        error: e,
        stackTrace: st,
      );
      throw AuthException(
        'An unexpected error occurred during registration.',
        e,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (_client == null) {
      AppLogger.info('Simulated password reset email sent to $email');
      return;
    }

    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'https://neuroplay.app/reset-password',
      );
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, e);
    } catch (e) {
      throw AuthException('Could not initiate password recovery: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_client != null) {
        await _client.auth.signOut();
      }
    } finally {
      _currentUser = AuthUser.unauthenticated();
      _authController.add(_currentUser);
      AppLogger.info('User signed out successfully.');
    }
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser.isGuest || !_currentUser.isAuthenticated) {
      // Nothing on cloud to delete for a guest
      await signOut();
      return;
    }

    if (_client == null) {
      AppLogger.warning('Simulating server-side account deletion.');
      await signOut();
      return;
    }

    try {
      // Invoke the server-side trusted Edge Function using caller's JWT
      final response = await _client.functions.invoke(
        'delete-account',
      );

      if (response.status != 200) {
        final dynamic data = response.data;
        final errorMsg = data is Map
            ? (data['error']?.toString() ?? 'Account deletion failed.')
            : 'Account deletion failed with status ${response.status}.';
        throw AuthException(errorMsg);
      }

      AppLogger.info('Account deleted on server successfully.');
      await signOut();
    } on sb.FunctionException catch (e) {
      AppLogger.error('FunctionException during delete-account: $e');
      throw AuthException('Server error during account erasure: $e', e);
    } on Object catch (e, st) {
      AppLogger.error('Error deleting account', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Unable to delete account at this time.', e);
    }
  }

  void dispose() {
    _sub?.cancel();
    _authController.close();
  }
}

/// Riverpod provider for the authentication repository.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final repo = SupabaseAuthRepository(client: client);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Stream provider listening to auth state transitions.
final authStateStreamProvider = StreamProvider<AuthUser>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Current active user provider.
final currentUserProvider = Provider<AuthUser>((ref) {
  final asyncUser = ref.watch(authStateStreamProvider);
  return asyncUser.value ?? ref.watch(authRepositoryProvider).currentUser;
});
