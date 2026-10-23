import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/app/providers.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_dialog.dart';

/// User Profile and Application Settings screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final a11yPrefs = ref.watch(accessibilityPreferencesProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final isReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: MaxWidthContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Profile & Settings',
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.gapH4,
                Text(
                  'Manage account preferences, accessibility defaults, and application theme.',
                  style: theme.textTheme.bodyMedium,
                ),
                AppSpacing.gapH24,

                // User Identity Card
                AppCard(
                  padding: AppSpacing.pXl,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: tokens.mintContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'AR',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: tokens.onMintContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapW16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                Text(
                                  'Alex Rivera',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const AppBadge(
                                  label: 'PREVIEW USER',
                                ),
                              ],
                            ),
                            AppSpacing.gapH4,
                            Text(
                              'alex.rivera@example.com',
                              style: theme.textTheme.bodyMedium,
                            ),
                            AppSpacing.gapH2,
                            Text(
                              'Member since October 2026',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Section 1: Appearance & Theme
                Text(
                  'Appearance',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH12,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Theme Mode'),
                        subtitle: Text(
                          switch (themeMode) {
                            ThemeMode.system => 'Following device system theme',
                            ThemeMode.light => 'Light theme enabled',
                            ThemeMode.dark => 'Dark theme enabled',
                          },
                        ),
                      ),
                      AppSpacing.gapH12,
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined, size: 16),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined, size: 16),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(
                              Icons.settings_system_daydream,
                              size: 16,
                            ),
                            label: Text('System'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (set) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(set.first);
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Section 2: Accessibility & Interaction
                Text(
                  'Accessibility & Interaction',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH12,
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sound Feedback'),
                        subtitle: const Text(
                          'Subtle audio tones during exercise cues',
                        ),
                        value: a11yPrefs.soundEnabled,
                        onChanged: (v) => ref
                            .read(accessibilityPreferencesProvider.notifier)
                            .setSound(enabled: v),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Haptic Confirmation'),
                        subtitle: const Text(
                          'Tactile vibration pulse on mobile taps',
                        ),
                        value: a11yPrefs.hapticsEnabled,
                        onChanged: (v) => ref
                            .read(accessibilityPreferencesProvider.notifier)
                            .setHaptics(enabled: v),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily Routine Reminder'),
                        subtitle: const Text('Calm notification at 08:30 AM'),
                        value: a11yPrefs.dailyReminders,
                        onChanged: (v) => ref
                            .read(accessibilityPreferencesProvider.notifier)
                            .setReminders(enabled: v),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.text_fields_rounded),
                        title: const Text('System Text Scaling'),
                        subtitle: Text(
                          'Current scale factor: ${textScale.toStringAsFixed(2)}x',
                        ),
                        trailing: AppBadge(
                          label: textScale > 1.0 ? 'SCALED' : 'STANDARD',
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.motion_photos_off_outlined),
                        title: const Text('Reduced Motion Preference'),
                        subtitle: Text(
                          isReducedMotion
                              ? 'Enabled by OS settings (animations disabled)'
                              : 'Standard motion enabled',
                        ),
                        trailing: AppBadge(
                          label: isReducedMotion ? 'ACTIVE' : 'DEFAULT',
                          variant: isReducedMotion
                              ? AppBadgeVariant.mint
                              : AppBadgeVariant.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Section 3: Data & Privacy
                Text(
                  'Data & Privacy',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH12,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your cognitive training history is stored encrypted under Row-Level Security in PostgreSQL.',
                        style: theme.textTheme.bodySmall,
                      ),
                      AppSpacing.gapH16,
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            label: 'Export Data (JSON)',
                            icon: Icons.download_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: () {
                              AppDialog.showConfirmation(
                                context: context,
                                title: 'Export Training Archive',
                                message:
                                    'A structured JSON file containing all sessions, scores, and preferences will be compiled for your download.',
                                confirmLabel: 'Generate Export',
                              );
                            },
                          ),
                          AppButton(
                            label: 'Delete Account',
                            icon: Icons.delete_outline_rounded,
                            variant: AppButtonVariant.danger,
                            onPressed: () {
                              AppDialog.showConfirmation(
                                context: context,
                                title: 'Delete Account and Data',
                                message:
                                    'Are you sure you want to permanently erase your NEUROPLAY profile and all associated cognitive records? This action cannot be reversed.',
                                confirmLabel: 'Delete Permanently',
                                isDestructive: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH32,

                // About & Version Info
                Center(
                  child: Column(
                    children: [
                      Text(
                        'NEUROPLAY MVP • v0.1.0',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.navy500,
                        ),
                      ),
                      AppSpacing.gapH4,
                      Text(
                        'Flutter Web • Android • iOS',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
