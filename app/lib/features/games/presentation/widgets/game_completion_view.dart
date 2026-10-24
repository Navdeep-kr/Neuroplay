import 'package:flutter/material.dart';
import 'package:neuroplay/core/audio/sound_synthesizer.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_feedback_effects.dart';

/// Elite neuro-performance completion view rendered upon session termination.
class GameCompletionView extends StatefulWidget {
  const GameCompletionView({
    required this.result,
    required this.gameTitle,
    required this.onPlayAgain,
    required this.onBackToLibrary,
    super.key,
    this.onNextInWorkout,
    this.nextGameTitle,
    this.isWorkoutCompleted = false,
  });

  final GameResult result;
  final String gameTitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToLibrary;
  final VoidCallback? onNextInWorkout;
  final String? nextGameTitle;
  final bool isWorkoutCompleted;

  @override
  State<GameCompletionView> createState() => _GameCompletionViewState();
}

class _GameCompletionViewState extends State<GameCompletionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundSynthesizer.playFanfare();
    });
  }

  (String rankLetter, String rankTitle, Color rankColor) _getRankInfo(
    int score,
  ) {
    if (score >= 1200) {
      return ('S', 'NEURAL GRANDMASTER', const Color(0xFF38BDF8));
    } else if (score >= 800) {
      return ('A', 'SYNAPTIC ACE', const Color(0xFFF59E0B));
    } else if (score >= 500) {
      return ('B', 'COGNITIVE PRO', AppColors.mint500);
    } else {
      return ('C', 'FOCUS PIONEER', const Color(0xFF818CF8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = widget.result.scoreBreakdown;
    final isPractice = (widget.result.metrics['isPractice'] as bool?) ?? false;
    final (rankLetter, rankTitle, rankColor) =
        _getRankInfo(widget.result.finalScore);

    final viewContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Trophy / Rank Medal Header
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          rankColor.withValues(alpha: 0.25),
                          rankColor.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: rankColor.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        rankLetter,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: rankColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH12,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: AppRadii.rFull,
                  border: Border.all(
                    color: rankColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  rankTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rankColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              Text(
                widget.isWorkoutCompleted
                    ? 'Daily Workout Complete!'
                    : 'Exercise Complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppSpacing.gapH4,
              Text(
                widget.gameTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.navy500,
                ),
              ),
              if (widget.isWorkoutCompleted) ...[
                AppSpacing.gapH8,
                const AppBadge(
                  label: '🎉 All Routine Exercises Finished for Today',
                  variant: AppBadgeVariant.mint,
                ),
              ] else if (isPractice) ...[
                AppSpacing.gapH8,
                const AppBadge(
                  label: 'Practice Mode — Results are not persisted',
                ),
              ],
              AppSpacing.gapH24,

              // Primary score highlight card with rolling odometer
              AppCard(
                child: Column(
                  children: [
                    Text(
                      'TOTAL COGNITIVE SCORE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.navy500,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapH4,
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: widget.result.finalScore.toDouble(),
                      ),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) => Text(
                        '${val.round()}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.mint500,
                        ),
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
                          value:
                              '${widget.result.metrics['accuracyPercent'] ?? 100}%',
                        ),
                        _StatColumn(
                          label: 'Active Time',
                          value:
                              '${widget.result.totalActiveDuration.inSeconds}s',
                        ),
                        _StatColumn(
                          label: 'Difficulty',
                          value: widget.result.difficulty.displayName,
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
                      'Performance Breakdown',
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

              // Workout progression banner or standard navigation
              if (widget.onNextInWorkout != null &&
                  !widget.isWorkoutCompleted) ...[
                AppButton(
                  label: widget.nextGameTitle != null
                      ? 'Continue: Next Exercise (${widget.nextGameTitle})'
                      : 'Continue to Next Exercise',
                  icon: Icons.arrow_forward_rounded,
                  isFullWidth: true,
                  onPressed: widget.onNextInWorkout,
                ),
                AppSpacing.gapH12,
              ],

              // Navigation Actions
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: widget.isWorkoutCompleted
                          ? 'Return Home'
                          : 'Play Again',
                      icon: widget.isWorkoutCompleted
                          ? Icons.home_rounded
                          : Icons.replay_rounded,
                      variant: widget.isWorkoutCompleted
                          ? AppButtonVariant.primary
                          : (widget.onNextInWorkout != null
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary),
                      onPressed: widget.isWorkoutCompleted
                          ? widget.onBackToLibrary
                          : widget.onPlayAgain,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: AppButton(
                      label: 'Library',
                      variant: AppButtonVariant.secondary,
                      onPressed: widget.onBackToLibrary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return ConfettiParticleOverlay(child: viewContent);
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
        AppSpacing.gapH4,
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.navy700,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isNegative ? AppColors.error : AppColors.navy800,
            ),
          ),
        ],
      ),
    );
  }
}
