import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_button.dart';

/// Modal dialog presented when gameplay is suspended.
class GamePauseDialog extends StatelessWidget {
  const GamePauseDialog({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Paused',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                'Take a breath. Active session time is frozen.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
              AppSpacing.gapH24,
              AppButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                isFullWidth: true,
                onPressed: onResume,
              ),
              AppSpacing.gapH12,
              AppButton(
                label: 'Restart Session',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: onRestart,
              ),
              AppSpacing.gapH12,
              AppButton(
                label: 'Exit to Games Library',
                icon: Icons.arrow_back_rounded,
                variant: AppButtonVariant.subtle,
                isFullWidth: true,
                onPressed: onQuit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
