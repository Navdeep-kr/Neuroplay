import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/exceptions/app_exception.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/domain/auth_user.dart';
import 'package:neuroplay/features/profile/data/profile_repository.dart';

/// State notifier managing active authentication actions and error states.
class AuthController extends StateNotifier<AsyncValue<AuthUser>> {
  AuthController({
    required IAuthRepository authRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _ref = ref,
        super(AsyncValue.data(authRepository.currentUser));

  final IAuthRepository _authRepository;
  final Ref _ref;

  /// Sign in with existing email and password credentials.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
      _invalidateUserCaches();
      return true;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncValue.error('Authentication failure: $e', st);
      return false;
    }
  }

  /// Create a new account with email, password, and full name.
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUpWithPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AsyncValue.data(user);
      _invalidateUserCaches();
      return true;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncValue.error('Registration failure: $e', st);
      return false;
    }
  }

  /// Initiate password reset email flow.
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = AsyncValue.data(_authRepository.currentUser);
      return true;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncValue.error('Reset request failure: $e', st);
      return false;
    }
  }

  /// Enter local guest mode.
  void enterGuestMode() {
    _authRepository.enterGuestMode();
    state = AsyncValue.data(_authRepository.currentUser);
    _invalidateUserCaches();
  }

  /// Sign out and clear all user-specific in-memory state.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
    } finally {
      state = AsyncValue.data(_authRepository.currentUser);
      _invalidateUserCaches();
    }
  }

  /// Permanently delete user account via trusted server-side cascade.
  Future<bool> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.deleteAccount();
      state = AsyncValue.data(_authRepository.currentUser);
      _invalidateUserCaches();
      return true;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncValue.error('Could not delete account: $e', st);
      return false;
    }
  }

  /// Clears in-memory Riverpod caches to ensure no user data bleeds across sessions.
  void _invalidateUserCaches() {
    _ref
      ..invalidate(userProfileProvider)
      ..invalidate(userPreferencesProvider);
  }
}

/// Provider for the auth controller.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});
