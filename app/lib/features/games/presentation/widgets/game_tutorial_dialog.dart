import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';

/// Modal dialog presented before starting, explaining the rules and offering practice mode.
class GameTutorialDialog extends StatefulWidget {
  const GameTutorialDialog({
    required this.title,
    required this.category,
    required this.instructions,
    required this.icon,
    required this.onStart,
    super.key,
    this.tips = const [],
    this.initialDifficulty = GameDifficulty.medium,
  });

  final String title;
  final String category;
  final String instructions;
  final IconData icon;
  final List<String> tips;
  final GameDifficulty initialDifficulty;
  final void Function({
    required GameDifficulty difficulty,
    required bool isPractice,
  }) onStart;

  @override
  State<GameTutorialDialog> createState() => _GameTutorialDialogState();
}

class _GameTutorialDialogState extends State<GameTutorialDialog> {
  late GameDifficulty _selectedDifficulty;
  bool _isPractice = false;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon & title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.mint500.withValues(alpha: 0.15),
                      borderRadius: AppRadii.rLg,
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.mint500,
                      size: 26,
                    ),
                  ),
                  AppSpacing.gapW16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.category.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.mint500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH24,

              // Instructions
              Text(
                'How to Play',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                widget.instructions,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              if (widget.tips.isNotEmpty) ...[
                AppSpacing.gapH12,
                ...widget.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.mint500,
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.navy500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              AppSpacing.gapH16,

              // Mode toggle (Practice vs Standard)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadii.rLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Mode',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Untimed, introductory trials without score recording',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.navy500,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isPractice,
                      activeThumbColor: AppColors.mint500,
                      onChanged: (val) => setState(() => _isPractice = val),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // Difficulty selector (if not in practice mode)
              if (!_isPractice) ...[
                Text(
                  'Difficulty Tier',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapH8,
                SegmentedButton<GameDifficulty>(
                  segments: [
                    ButtonSegment(
                      value: GameDifficulty.easy,
                      label: Text(GameDifficulty.easy.displayName),
                    ),
                    ButtonSegment(
                      value: GameDifficulty.medium,
                      label: Text(GameDifficulty.medium.displayName),
                    ),
                    ButtonSegment(
                      value: GameDifficulty.hard,
                      label: Text(GameDifficulty.hard.displayName),
                    ),
                  ],
                  selected: {_selectedDifficulty},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      setState(() => _selectedDifficulty = selected.first);
                    }
                  },
                ),
                AppSpacing.gapH24,
              ] else
                AppSpacing.gapH12,

              // Start button
              AppButton(
                label: _isPractice ? 'Start Practice' : 'Begin Workout',
                icon: Icons.play_arrow_rounded,
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onStart(
                    difficulty: _selectedDifficulty,
                    isPractice: _isPractice,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
