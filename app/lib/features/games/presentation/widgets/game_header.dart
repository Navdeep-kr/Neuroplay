import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';

/// Standard top HUD header for in-game sessions.
///
/// Features animated score rollup, live combo streak multiplier indicators,
/// and smooth round progress tracks.
class GameHeader extends StatelessWidget {
  const GameHeader({
    required this.title,
    required this.currentRound,
    required this.totalRounds,
    required this.score,
    required this.onPause,
    super.key,
    this.isPractice = false,
    this.comboStreak = 0,
  });

  final String title;
  final int currentRound;
  final int totalRounds;
  final int score;
  final VoidCallback onPause;
  final bool isPractice;
  final int comboStreak;

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
            Row(
              children: [
                // Live Combo Multiplier badge
                if (comboStreak >= 2) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: comboStreak >= 4
                            ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                            : [AppColors.mint500, const Color(0xFF059669)],
                      ),
                      borderRadius: AppRadii.rFull,
                      boxShadow: [
                        BoxShadow(
                          color: (comboStreak >= 4
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.mint500)
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comboStreak >= 4
                              ? Icons.local_fire_department_rounded
                              : Icons.bolt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'x$comboStreak STREAK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapW8,
                ],

                // Animated Score Counter
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score.toDouble()),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadii.rFull,
                      border: Border.all(
                        color: comboStreak >= 2
                            ? AppColors.mint500.withValues(alpha: 0.6)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${animatedValue.round()} pts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint500,
                      ),
                    ),
                  ),
                ),
              ],
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
