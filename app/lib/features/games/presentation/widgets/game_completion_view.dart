import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';

/// Completion view rendered upon session termination.
class GameCompletionView extends StatelessWidget {
  const GameCompletionView({
    required this.result,
    required this.gameTitle,
    required this.onPlayAgain,
    required this.onBackToLibrary,
    super.key,
  });

  final GameResult result;
  final String gameTitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = result.scoreBreakdown;
    final isPractice = (result.metrics['isPractice'] as bool?) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.mint500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.mint500,
                  size: 36,
                ),
              ),
              AppSpacing.gapH16,
              Text(
                'Exercise Complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapH4,
              Text(
                gameTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.navy500,
                ),
              ),
              if (isPractice) ...[
                AppSpacing.gapH8,
                const AppBadge(
                  label: 'Practice Mode — Results are not persisted',
                ),
              ],
              AppSpacing.gapH24,

              // Primary score highlight card
              AppCard(
                child: Column(
                  children: [
                    Text(
                      'Final Score',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.navy500,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Text(
                      '${result.finalScore}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint500,
                      ),
                    ),
                    AppSpacing.gapH16,
                    const Divider(),
                    AppSpacing.gapH12,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          label: 'Accuracy',
                          value: '${result.metrics['accuracyPercent'] ?? 100}%',
                        ),
                        _StatColumn(
                          label: 'Active Time',
                          value: '${result.totalActiveDuration.inSeconds}s',
                        ),
                        _StatColumn(
                          label: 'Difficulty',
                          value: result.difficulty.displayName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // Transparent score breakdown card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score Breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapH12,
                    _BreakdownRow(
                      label: 'Base & Raw Score',
                      value: '+${breakdown.rawScore}',
                    ),
                    _BreakdownRow(
                      label: 'Accuracy Bonus',
                      value: '+${breakdown.accuracyBonus}',
                    ),
                    if (breakdown.speedBonus > 0)
                      _BreakdownRow(
                        label: 'Speed Bonus',
                        value: '+${breakdown.speedBonus}',
                      ),
                    if (breakdown.difficultyBonus > 0)
                      _BreakdownRow(
                        label: 'Difficulty Multiplier',
                        value: '+${breakdown.difficultyBonus}',
                      ),
                    if (breakdown.penalties > 0)
                      _BreakdownRow(
                        label: 'Error Penalties',
                        value: '-${breakdown.penalties}',
                        isNegative: true,
                      ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Verified Score',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${breakdown.finalScore} pts',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.mint500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,

              // Navigation Actions
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Play Again',
                      icon: Icons.replay_rounded,
                      onPressed: onPlayAgain,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: AppButton(
                      label: 'Library',
                      variant: AppButtonVariant.secondary,
                      onPressed: onBackToLibrary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.navy500,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  final String label;
  final String value;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isNegative ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
