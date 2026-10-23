import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/features/profile/presentation/controllers/profile_controller.dart';

/// Onboarding screen introducing new users to the cognitive training structure.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  bool _dailyReminder = true;
  String _targetFocus = 'Memory';

  final _focusAreas = const [
    (
      'Memory',
      Icons.psychology_outlined,
      'Recall, pattern retention & working memory'
    ),
    (
      'Attention',
      Icons.filter_center_focus_rounded,
      'Selective focus & distractor suppression'
    ),
    ('Speed', Icons.bolt_rounded, 'Processing speed & visual reaction time'),
    (
      'Flexibility',
      Icons.swap_horiz_rounded,
      'Task switching & cognitive set shifting'
    ),
  ];

  Future<void> _completeOnboarding() async {
    await ref.read(profileControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pLg,
            child: MaxWidthContainer(
              maxWidth: 580,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / 2,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.slate200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 6,
                          borderRadius: AppRadii.rFull,
                        ),
                      ),
                      AppSpacing.gapW16,
                      Text(
                        'Step ${_currentStep + 1} of 2',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  AppSpacing.gapH32,

                  if (_currentStep == 0) ...[
                    // Step 1: Scientific Welcome & Primary Goal
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.mintContainer,
                        borderRadius: AppRadii.rLg,
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        size: 32,
                        color: tokens.onMintContainer,
                      ),
                    ),
                    AppSpacing.gapH16,
                    Text(
                      'Personalize Your Training',
                      style: theme.textTheme.headlineMedium,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'NEUROPLAY adapts daily routines based on your baseline goals. Which cognitive faculty would you like to prioritize first?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    AppSpacing.gapH24,

                    ..._focusAreas.map(
                      (area) {
                        final isSelected = _targetFocus == area.$1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppCard(
                            onTap: () => setState(() => _targetFocus = area.$1),
                            borderColor:
                                isSelected ? theme.colorScheme.primary : null,
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary.withAlpha(15)
                                : null,
                            child: Row(
                              children: [
                                Icon(
                                  area.$2,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.navy600),
                                  size: 28,
                                ),
                                AppSpacing.gapW16,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        area.$1,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      AppSpacing.gapH2,
                                      Text(
                                        area.$3,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : tokens.cardBorder,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    AppSpacing.gapH24,
                    AppButton(
                      label: 'Next Step',
                      icon: Icons.arrow_forward_rounded,
                      isFullWidth: true,
                      onPressed: () => setState(() => _currentStep = 1),
                    ),
                  ] else ...[
                    // Step 2: Habit Consistency & Audio Setup
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.mintContainer,
                        borderRadius: AppRadii.rLg,
                      ),
                      child: Icon(
                        Icons.alarm_rounded,
                        size: 32,
                        color: tokens.onMintContainer,
                      ),
                    ),
                    AppSpacing.gapH16,
                    Text(
                      'Consistency is Key',
                      style: theme.textTheme.headlineMedium,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Neuroplasticity research shows 10-15 minutes of regular daily workouts yields significantly higher retention than irregular marathon sessions.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    AppSpacing.gapH24,

                    AppCard(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _dailyReminder,
                        onChanged: (val) =>
                            setState(() => _dailyReminder = val),
                        title: Text(
                          'Daily Training Reminders',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Receive a gentle notification at 9:00 AM to keep your brain active.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    AppSpacing.gapH16,

                    AppCard(
                      backgroundColor: tokens.subtleBackground,
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          AppSpacing.gapW16,
                          Expanded(
                            child: Text(
                              'All exercise scores are evaluated using normative peer cohort percentiles with strict data privacy.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.gapH32,
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Back',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => setState(() => _currentStep = 0),
                          ),
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: 'Enter Dashboard',
                            icon: Icons.check_rounded,
                            onPressed: _completeOnboarding,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
