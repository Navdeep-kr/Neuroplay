import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/app/providers.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_dialog.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neuroplay/features/profile/data/profile_repository.dart';
import 'package:neuroplay/features/profile/domain/profile_models.dart';
import 'package:neuroplay/features/profile/presentation/controllers/profile_controller.dart';

/// User profile and application preferences screen with guest and cloud account handling.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isReducedMotion = mediaQuery.disableAnimations;

    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final userPrefsAsync = ref.watch(userPreferencesProvider);
    final prefs = userPrefsAsync.valueOrNull ??
        UserPreferences.defaultPreferences(user.id);
    final themeMode = ref.watch(themeModeProvider);
    final accessPrefs = ref.watch(accessibilityPreferencesProvider);
    final authState = ref.watch(authControllerProvider);
    final isAuthLoading = authState.isLoading;

    final isGuest = user.isGuest || !user.isAuthenticated;
    final displayName = user.displayName ?? 'Guest Player';
    final email = user.email ?? 'Local In-Memory Session';
    final initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'GP';

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
                  'Manage account credentials, appearance, and sensory preferences.',
                  style: theme.textTheme.bodyMedium,
                ),
                AppSpacing.gapH24,

                // User Identity Card
                AppCard(
                  padding: AppSpacing.pXl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
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
                                initials,
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
                                      profileAsync.value?.displayName ??
                                          displayName,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    AppBadge(
                                      label: isGuest
                                          ? 'GUEST MODE'
                                          : 'VERIFIED ACCOUNT',
                                      variant: isGuest
                                          ? AppBadgeVariant.neutral
                                          : AppBadgeVariant.info,
                                    ),
                                  ],
                                ),
                                AppSpacing.gapH4,
                                Text(
                                  email,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                AppSpacing.gapH2,
                                Text(
                                  isGuest
                                      ? 'Progress saved in memory only'
                                      : 'Encrypted via Supabase Auth & PostgreSQL',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,
                      if (isGuest) ...[
                        Container(
                          padding: AppSpacing.pMd,
                          decoration: BoxDecoration(
                            color: tokens.subtleBackground,
                            borderRadius: AppRadii.rMd,
                            border: Border.all(color: tokens.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  AppSpacing.gapW8,
                                  Expanded(
                                    child: Text(
                                      'Playing Without Registration',
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapH6,
                              Text(
                                'You are currently in guest mode. Note: Automatic guest-to-cloud account migration is not supported. Create an account to retain your scores across sessions.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapH16,
                        AppButton(
                          label: 'Sign In or Register',
                          icon: Icons.login_rounded,
                          isFullWidth: true,
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ] else ...[
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppButton(
                              label: 'Sign Out',
                              icon: Icons.logout_rounded,
                              variant: AppButtonVariant.secondary,
                              isLoading: isAuthLoading,
                              onPressed: () async {
                                final confirm =
                                    await AppDialog.showConfirmation(
                                  context: context,
                                  title: 'Sign Out',
                                  message:
                                      'Are you sure you want to sign out of your account on this device?',
                                  confirmLabel: 'Sign Out',
                                );
                                if (confirm ?? false) {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signOut();
                                  if (context.mounted) {
                                    context.go(AppRoutes.home);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.card_membership_outlined),
                        title: Text(
                          'Membership & Entitlements',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Manage tier, restore purchases, or view feature matrix',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.subscription),
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
                        title: Text(
                          'Interface Theme',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Select light, dark, or follow device settings',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      AppSpacing.gapH12,
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selected) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateThemeMode(selected.first);
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Section 2: Sensory & Accessibility
                Text(
                  'Sensory & Feedback',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH12,
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: accessPrefs.soundEnabled,
                        onChanged: (val) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateSound(enabled: val);
                        },
                        title: Text(
                          'Auditory Feedback',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Calm acoustic chimes on stimulus response and completion',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: accessPrefs.hapticsEnabled,
                        onChanged: (val) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateHaptics(enabled: val);
                        },
                        title: Text(
                          'Tactile Vibrations',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Subtle haptic pulses on supported mobile devices',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: prefs.reducedMotion || isReducedMotion,
                        onChanged: (val) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateReducedMotion(enabled: val);
                        },
                        title: Text(
                          'Reduced Motion',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          isReducedMotion
                              ? 'Respecting system reduced motion setting'
                              : 'Minimize non-essential motion and screen transitions',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Section 3: Training & Preferences
                Text(
                  'Training Routine & Language',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH12,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Reminders Toggle
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: prefs.dailyReminderEnabled,
                        onChanged: (val) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateReminders(
                                enabled: val,
                                reminderTime: prefs.reminderTime,
                              );
                        },
                        title: Text(
                          'Daily Routine Reminder',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Non-intrusive reminder for your cognitive workout',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      if (prefs.dailyReminderEnabled) ...[
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Reminder Schedule',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'Scheduled time for your daily training prompt',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: OutlinedButton(
                            onPressed: () async {
                              final parts = prefs.reminderTime.split(':');
                              final initialTime = TimeOfDay(
                                hour: int.tryParse(parts.first) ?? 9,
                                minute: parts.length > 1
                                    ? int.tryParse(parts[1]) ?? 0
                                    : 0,
                              );
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
                              );
                              if (picked != null) {
                                final formatted =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .updateReminders(
                                      enabled: true,
                                      reminderTime: formatted,
                                    );
                              }
                            },
                            child: Text(prefs.reminderTime),
                          ),
                        ),
                      ],
                      const Divider(),

                      // Preferred Difficulty
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Target Difficulty Mode',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Auto dynamically scales based on rolling performance',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      AppSpacing.gapH8,
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'auto',
                            label: Text('Auto'),
                            icon: Icon(Icons.auto_awesome_rounded),
                          ),
                          ButtonSegment(
                            value: 'easy',
                            label: Text('Easy'),
                          ),
                          ButtonSegment(
                            value: 'medium',
                            label: Text('Med'),
                          ),
                          ButtonSegment(
                            value: 'hard',
                            label: Text('Hard'),
                          ),
                          ButtonSegment(
                            value: 'expert',
                            label: Text('Exp'),
                          ),
                        ],
                        selected: {prefs.preferredDifficulty},
                        onSelectionChanged: (selected) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateDifficulty(selected.first);
                        },
                      ),
                      const Divider(),

                      // Language
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Content Language',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Active locale for instructions and word challenges',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: DropdownButton<String>(
                          value: prefs.languageCode,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English (EN)'),
                            ),
                            DropdownMenuItem(
                              value: 'es',
                              child: Text('Español (ES)'),
                            ),
                            DropdownMenuItem(
                              value: 'fr',
                              child: Text('Français (FR)'),
                            ),
                            DropdownMenuItem(
                              value: 'de',
                              child: Text('Deutsch (DE)'),
                            ),
                            DropdownMenuItem(
                              value: 'ja',
                              child: Text('日本語 (JA)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(profileControllerProvider.notifier)
                                  .updateLanguage(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Section 4: Data & Privacy
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
                        isGuest
                          ? 'In guest mode, sessions are volatile and kept only in your local session cache.'
                          : 'Your cognitive training history is stored encrypted under Row-Level Security in PostgreSQL.',
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
                            onPressed: () => _showExportDialog(context, ref),
                          ),
                          if (!isGuest)
                            AppButton(
                              label: 'Delete Account',
                              icon: Icons.delete_outline_rounded,
                              variant: AppButtonVariant.danger,
                              isLoading: isAuthLoading,
                              onPressed: () async {
                                final confirm =
                                    await AppDialog.showConfirmation(
                                  context: context,
                                  title: 'Delete Account and Data',
                                  message:
                                      'Are you sure you want to permanently erase your NEUROPLAY profile and all associated cognitive records? This action executes a server-side cascade that cannot be reversed.',
                                  confirmLabel: 'Delete Permanently',
                                  isDestructive: true,
                                );
                                if (confirm ?? false) {
                                  final deleted = await ref
                                      .read(authControllerProvider.notifier)
                                      .deleteAccount();
                                  if (context.mounted && deleted) {
                                    context.go(AppRoutes.home);
                                  }
                                }
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

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _ExportDataDialog(ref: ref),
    );
  }
}

class _ExportDataDialog extends StatefulWidget {
  const _ExportDataDialog({required this.ref});

  final WidgetRef ref;

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  bool _isLoading = true;
  String? _jsonText;
  int _sessionCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  Future<void> _loadExport() async {
    try {
      final data = await widget.ref
          .read(profileControllerProvider.notifier)
          .exportUserData();
      final formatted = const JsonEncoder.withIndent('  ').convert(data);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _jsonText = formatted;
          _sessionCount = (data['game_sessions_count'] as num?)?.toInt() ?? 0;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not generate export archive: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Padding(
          padding: AppSpacing.pXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Data Archive',
                          style: theme.textTheme.headlineSmall,
                        ),
                        AppSpacing.gapH4,
                        Text(
                          'Portable JSON • Schema Version 1.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.navy700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    AppBadge(
                      label: '$_sessionCount Sessions Included',
                      variant: AppBadgeVariant.mint,
                    ),
                    AppSpacing.gapW8,
                    const AppBadge(
                      label: 'Zero Secrets Exported',
                      variant: AppBadgeVariant.outline,
                    ),
                  ],
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: Container(
                    padding: AppSpacing.pMd,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _jsonText ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy to Clipboard'),
                      onPressed: () async {
                        if (_jsonText != null) {
                          await Clipboard.setData(
                            ClipboardData(text: _jsonText!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Archive copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    AppSpacing.gapW12,
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
