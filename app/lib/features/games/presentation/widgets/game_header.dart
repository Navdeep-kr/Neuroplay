import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';

/// Standard top header for in-game sessions.
class GameHeader extends StatelessWidget {
  const GameHeader({
    required this.title,
    required this.currentRound,
    required this.totalRounds,
    required this.score,
    required this.onPause,
    super.key,
    this.isPractice = false,
  });

  final String title;
  final int currentRound;
  final int totalRounds;
  final int score;
  final VoidCallback onPause;
  final bool isPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        totalRounds > 0 ? (currentRound / totalRounds).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.pause_circle_outline_rounded),
                  iconSize: 28,
                  tooltip: 'Pause game (Esc)',
                  onPressed: onPause,
                ),
                AppSpacing.gapW8,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Round $currentRound of $totalRounds',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.navy500,
                          ),
                        ),
                        if (isPractice) ...[
                          AppSpacing.gapW8,
                          const AppBadge(
                            label: 'Practice',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Score counter
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadii.rFull,
              ),
              child: Text(
                '$score pts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint500,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH8,
        ClipRRect(
          borderRadius: AppRadii.rFull,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mint500),
          ),
        ),
      ],
    );
  }
}
