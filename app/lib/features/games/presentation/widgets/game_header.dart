import 'package:flutter/material.dart';
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
    this.facultyColor = const Color(0xFF2563EB),
  });

  final String title;
  final int currentRound;
  final int totalRounds;
  final int score;
  final VoidCallback onPause;
  final bool isPractice;
  final int comboStreak;
  final Color facultyColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        totalRounds > 0 ? (currentRound / totalRounds).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.rXl,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: facultyColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.pause_rounded),
                        iconSize: 22,
                        color: facultyColor,
                        tooltip: 'Pause game (Esc)',
                        onPressed: onPause,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Round $currentRound of $totalRounds',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
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
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Live Combo Multiplier badge
                  if (comboStreak >= 2) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: comboStreak >= 4
                              ? [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFEF4444),
                                ]
                              : [
                                  facultyColor,
                                  facultyColor.withValues(alpha: 0.8),
                                ],
                        ),
                        borderRadius: AppRadii.rFull,
                        boxShadow: [
                          BoxShadow(
                            color: (comboStreak >= 4
                                    ? const Color(0xFFF59E0B)
                                    : facultyColor)
                                .withValues(alpha: 0.3),
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
                          const SizedBox(width: 3),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF8FAFC), Colors.white],
                        ),
                        borderRadius: AppRadii.rFull,
                        border: Border.all(
                          color: comboStreak >= 2
                              ? facultyColor
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: comboStreak >= 2
                            ? [
                                BoxShadow(
                                  color: facultyColor.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 16,
                            color: facultyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${animatedValue.round()} pts',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: facultyColor,
                            ),
                          ),
                        ],
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
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(facultyColor),
            ),
          ),
        ],
      ),
    );
  }
}
