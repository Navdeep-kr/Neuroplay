import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/profile/data/profile_repository.dart';
import 'package:neuroplay/features/profile/domain/profile_models.dart';

void main() {
  group('SupabaseProfileRepository Unit Tests', () {
    late SupabaseProfileRepository repo;

    setUp(() {
      repo = const SupabaseProfileRepository();
    });

    test('getProfile returns guest profile for guest user ID', () async {
      final profile = await repo.getProfile('guest-local-user');

      expect(profile.id, equals('guest-local-user'));
      expect(profile.email, equals('guest@neuroplay.local'));
      expect(profile.onboardingCompleted, isTrue);
    });

    test('getPreferences returns default preferences for guest user', () async {
      final prefs = await repo.getPreferences('guest-local-user');

      expect(prefs.userId, equals('guest-local-user'));
      expect(prefs.themeMode, equals('system'));
      expect(prefs.soundEnabled, isTrue);
      expect(prefs.hapticsEnabled, isTrue);
    });

    test('updatePreferences in offline mode returns modified model', () async {
      const prefs = UserPreferences(
        userId: 'guest-local-user',
        themeMode: 'dark',
        soundEnabled: false,
      );

      final updated = await repo.updatePreferences(prefs);
      expect(updated.themeMode, equals('dark'));
      expect(updated.soundEnabled, isFalse);
    });
  });
}
