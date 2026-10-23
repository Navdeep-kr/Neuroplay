import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('AuthController Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            SupabaseAuthRepository(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state matches current unauthenticated user', () {
      final state = container.read(authControllerProvider);
      expect(state.value?.isAuthenticated, isFalse);
    });

    test('enterGuestMode switches controller state to guest user', () {
      container.read(authControllerProvider.notifier).enterGuestMode();

      final state = container.read(authControllerProvider);
      expect(state.value?.isGuest, isTrue);
      expect(state.value?.displayName, equals('Alex'));
    });

    test('signIn updates state with authenticated user', () async {
      final success =
          await container.read(authControllerProvider.notifier).signIn(
                email: 'user@example.com',
                password: 'password123',
              );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.value?.isAuthenticated, isTrue);
      expect(state.value?.email, equals('user@example.com'));
    });

    test('signOut clears authenticated user state', () async {
      await container.read(authControllerProvider.notifier).signIn(
            email: 'user@example.com',
            password: 'password123',
          );
      expect(
        container.read(authControllerProvider).value?.isAuthenticated,
        isTrue,
      );

      await container.read(authControllerProvider.notifier).signOut();
      expect(
        container.read(authControllerProvider).value?.isAuthenticated,
        isFalse,
      );
    });

    test('deleteAccount triggers deletion flow and resets user state',
        () async {
      await container.read(authControllerProvider.notifier).signIn(
            email: 'user@example.com',
            password: 'password123',
          );

      final deleted =
          await container.read(authControllerProvider.notifier).deleteAccount();
      expect(deleted, isTrue);
      expect(
        container.read(authControllerProvider).value?.isAuthenticated,
        isFalse,
      );
    });
  });
}
