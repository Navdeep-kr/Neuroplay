import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/app/providers.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/profile/data/profile_repository.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';

/// Controller coordinating profile preferences updates with UI theme and local storage.
class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController({
    required IProfileRepository profileRepository,
    required Ref ref,
  })  : _profileRepository = profileRepository,
        _ref = ref,
        super(const AsyncValue.data(null));

  final IProfileRepository _profileRepository;
  final Ref _ref;

  Future<void> updateThemeMode(ThemeMode mode) async {
    _ref.read(themeModeProvider.notifier).setThemeMode(mode);

    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      final modeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      try {
        final currentPrefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          currentPrefs.copyWith(themeMode: modeStr),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {
        // Preference save failures are non-fatal to current session
      }
    }
  }

  Future<void> updateSound({required bool enabled}) async {
    _ref
        .read(accessibilityPreferencesProvider.notifier)
        .setSound(enabled: enabled);

    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      try {
        final prefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          prefs.copyWith(soundEnabled: enabled),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {}
    }
  }

  Future<void> updateHaptics({required bool enabled}) async {
    _ref
        .read(accessibilityPreferencesProvider.notifier)
        .setHaptics(enabled: enabled);

    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      try {
        final prefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          prefs.copyWith(hapticsEnabled: enabled),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {}
    }
  }

  Future<void> updateDifficulty(String difficulty) async {
    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      try {
        final prefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          prefs.copyWith(preferredDifficulty: difficulty),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {}
    }
  }

  Future<void> updateReducedMotion({required bool enabled}) async {
    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      try {
        final prefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          prefs.copyWith(reducedMotion: enabled),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {}
    }
  }

  Future<void> updateLanguage(String languageCode) async {
    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      try {
        final prefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          prefs.copyWith(languageCode: languageCode),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {}
    }
  }

  Future<void> updateReminders({
    required bool enabled,
    String? reminderTime,
  }) async {
    _ref
        .read(accessibilityPreferencesProvider.notifier)
        .setReminders(enabled: enabled);

    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      try {
        final prefs = await _profileRepository.getPreferences(user.id);
        await _profileRepository.updatePreferences(
          prefs.copyWith(
            dailyReminderEnabled: enabled,
            reminderTime: reminderTime ?? prefs.reminderTime,
          ),
        );
        _ref.invalidate(userPreferencesProvider);
      } on Object catch (_) {}
    }
  }

  Future<Map<String, dynamic>> exportUserData() async {
    final trainingRepo = _ref.read(trainingRepositoryProvider);
    return trainingRepo.exportUserDataJson();
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(authRepositoryProvider).deleteAccount();
      state = const AsyncValue.data(null);
    } on Object catch (e, st) {
      state = AsyncValue.error('Could not delete account: $e', st);
      rethrow;
    }
  }

  Future<void> completeOnboarding() async {
    final user = _ref.read(currentUserProvider);
    if (user.isAuthenticated) {
      await _profileRepository.completeOnboarding(user.id);
      _ref.invalidate(userProfileProvider);
    }
  }

  Future<void> updateProfile({String? fullName, String? username}) async {
    final user = _ref.read(currentUserProvider);
    if (!user.isAuthenticated) return;

    state = const AsyncValue.loading();
    try {
      final currentProfile = await _profileRepository.getProfile(user.id);
      final updated = currentProfile.copyWith(
        fullName: fullName ?? currentProfile.fullName,
        username: username ?? currentProfile.username,
      );
      await _profileRepository.updateProfile(updated);
      _ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } on Object catch (e, st) {
      state = AsyncValue.error('Could not update profile: $e', st);
    }
  }
}

/// Provider for the profile controller.
final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileController(profileRepository: repo, ref: ref);
});
