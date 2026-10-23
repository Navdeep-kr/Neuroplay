import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_state_views.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Screen displaying structured cognitive goals and consistency challenges.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

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
                  'Cognitive Challenges',
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.gapH4,
                Text(
                  'Structured habit milestones to reinforce neural plasticity and adherence.',
                  style: theme.textTheme.bodyMedium,
                ),
                AppSpacing.gapH16,

                // Prototype / Demo notice
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF1E293B) : AppColors.slate100,
                    borderRadius: AppRadii.rMd,
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: isDark ? AppColors.mint400 : AppColors.mint700,
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'Preview Challenges — Real-time event triggers and streak tracking activate in Phase 2.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.navy700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                challengesAsync.when(
                  loading: () => const AppLoadingView(
                    message: 'Loading active challenges...',
                  ),
                  error: (err, stack) => AppErrorView(
                    title: 'Failed to load challenges',
                    message: 'Could not load your cognitive challenges.',
                    onRetry: () => ref.refresh(activeChallengesProvider),
                  ),
                  data: (challenges) => Column(
                    children: challenges
                        .map(
                          (challenge) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: _ChallengeCard(challenge: challenge),
                          ),
                        )
                        .toList(),
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

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final CognitiveChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: AppSpacing.pXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppBadge(
                    label: challenge.domain.label,
                    icon: challenge.domain.icon,
                  ),
                  if (challenge.isCompleted)
                    const AppBadge(
                      label: 'COMPLETED',
                      variant: AppBadgeVariant.success,
                      icon: Icons.check_circle_rounded,
                    )
                  else
                    AppBadge(
                      label: '${challenge.daysRemaining}d left',
                      variant: AppBadgeVariant.outline,
                    ),
                ],
              ),
              Text(
                '${challenge.currentProgress} / ${challenge.targetProgress} ${challenge.unit}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          Text(
            challenge.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapH6,
          Text(
            challenge.description,
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.gapH16,
          ClipRRect(
            borderRadius: AppRadii.rFull,
            child: LinearProgressIndicator(
              value: challenge.progressRatio,
              minHeight: 10,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                challenge.isCompleted
                    ? AppColors.success
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
