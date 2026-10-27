import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier for user-selected ThemeMode.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void setThemeMode(ThemeMode mode) => state = mode;

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }
}

/// Global provider for application ThemeMode.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Accessibility settings provider for sound and haptics.
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.dailyReminders = true,
  });

  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool dailyReminders;

  AccessibilityPreferences copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? dailyReminders,
  }) =>
      AccessibilityPreferences(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        dailyReminders: dailyReminders ?? this.dailyReminders,
      );
}

class AccessibilityPreferencesNotifier
    extends StateNotifier<AccessibilityPreferences> {
  AccessibilityPreferencesNotifier() : super(const AccessibilityPreferences());

  void setSound({required bool enabled}) =>
      state = state.copyWith(soundEnabled: enabled);
  void setHaptics({required bool enabled}) =>
      state = state.copyWith(hapticsEnabled: enabled);
  void setReminders({required bool enabled}) =>
      state = state.copyWith(dailyReminders: enabled);
}

final accessibilityPreferencesProvider = StateNotifierProvider<
    AccessibilityPreferencesNotifier, AccessibilityPreferences>(
  (ref) => AccessibilityPreferencesNotifier(),
);
