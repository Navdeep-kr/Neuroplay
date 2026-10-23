import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/domain/auth_user.dart';

void main() {
  group('SupabaseAuthRepository Unit Tests', () {
    late SupabaseAuthRepository repo;

    setUp(() {
      // Initialize without client to test offline/guest capability
      repo = SupabaseAuthRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('starts with unauthenticated user', () {
      expect(repo.currentUser.status, equals(AuthStatus.unauthenticated));
      expect(repo.currentUser.isAuthenticated, isFalse);
    });

    test('enterGuestMode updates user and emits to stream', () async {
      unawaited(
        expectLater(
          repo.authStateChanges,
          emits(
            predicate<AuthUser>((u) => u.isGuest && u.displayName == 'Alex'),
          ),
        ),
      );

      repo.enterGuestMode();

      expect(repo.currentUser.isGuest, isTrue);
      expect(repo.currentUser.status, equals(AuthStatus.guest));
    });

    test(
        'signInWithPassword in offline mode succeeds and sets authenticated state',
        () async {
      final user = await repo.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(user.isAuthenticated, isTrue);
      expect(user.email, equals('test@example.com'));
      expect(repo.currentUser.isAuthenticated, isTrue);
    });

    test('signUpWithPassword creates user with full name', () async {
      final user = await repo.signUpWithPassword(
        email: 'alex@example.com',
        password: 'securepassword',
        fullName: 'Alex Rivera',
      );

      expect(user.isAuthenticated, isTrue);
      expect(user.displayName, equals('Alex Rivera'));
      expect(user.email, equals('alex@example.com'));
    });

    test('signOut clears authenticated user back to unauthenticated', () async {
      await repo.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(repo.currentUser.isAuthenticated, isTrue);

      await repo.signOut();
      expect(repo.currentUser.isAuthenticated, isFalse);
      expect(repo.currentUser.status, equals(AuthStatus.unauthenticated));
    });

    test('deleteAccount clears session without crashing', () async {
      await repo.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      await repo.deleteAccount();
      expect(repo.currentUser.isAuthenticated, isFalse);
      expect(repo.currentUser.status, equals(AuthStatus.unauthenticated));
    });
  });
}
