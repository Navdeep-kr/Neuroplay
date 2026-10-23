import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_state_views.dart';
import 'package:neuroplay/core/widgets/game_container_preview.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Main Home Dashboard screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(todayWorkoutProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final todayFormatted = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: workoutAsync.when(
          loading: () =>
              const AppLoadingView(message: "Preparing today's routine..."),
          error: (err, stack) => AppErrorView(
            title: 'Unable to load dashboard',
            message: 'An error occurred while loading your daily routine.',
            technicalDetails: err.toString(),
            onRetry: () => ref.refresh(todayWorkoutProvider),
          ),
          data: (workout) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: MaxWidthContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Demonstration Data Banner ---
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.navy600,
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Text(
                            'Demonstration MVP Mode — Sample routine and training indicators displayed.',
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

                  // --- Header Greeting & Streak ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      return Flex(
                        direction: isNarrow ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: isNarrow
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todayFormatted.toUpperCase(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  letterSpacing: 1,
                                ),
                              ),
                              AppSpacing.gapH4,
                              Text(
                                'Welcome, Alex',
                                style: theme.textTheme.displaySmall,
                              ),
                            ],
                          ),
                          if (isNarrow) AppSpacing.gapH12,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.mintContainer,
                              borderRadius: AppRadii.rFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: tokens.onMintContainer,
                                ),
                                AppSpacing.gapW4,
                                Text(
                                  '6 Day Streak',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: tokens.onMintContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  AppSpacing.gapH24,

                  // --- Prominent Hero: START TODAY'S WORKOUT ---
                  AppCard(
                    backgroundColor: isDark
                        ? const Color(0xFF132230)
                        : const Color(0xFFF0FDF4),
                    borderColor: isDark
                        ? const Color(0xFF1D3B47)
                        : const Color(0xFFBBF7D0),
                    padding: AppSpacing.pXl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppBadge(
                              label: "TODAY'S WORKOUT",
                              variant: AppBadgeVariant.mint,
                            ),
                            Text(
                              '•   ${workout.estimatedMinutes} min',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH12,
                        Text(
                          workout.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.gapH8,
                        Text(
                          workout.subtitle,
                          style: theme.textTheme.bodyLarge,
                        ),
                        AppSpacing.gapH16,

                        // Targeted cognitive domains pills
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: workout.domains
                              .map(
                                (d) => Chip(
                                  avatar: Icon(d.icon, size: 14),
                                  label: Text(d.label),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                        AppSpacing.gapH24,

                        // Clear, prominent CTA
                        AppButton(
                          label: "Start Today's Workout",
                          icon: Icons.play_arrow_rounded,
                          isFullWidth: true,
                          semanticLabel:
                              "Start Today's Workout, 8 minutes routine",
                          onPressed: () {
                            _showWorkoutModal(context, workout);
                          },
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH32,

                  // --- Quick Metric Indicators ---
                  Text(
                    'Training Pulse',
                    style: theme.textTheme.headlineSmall,
                  ),
                  AppSpacing.gapH16,
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 600 ? 3 : 1;
                      if (cols == 3) {
                        return Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Brain Index',
                                value: '82.4',
                                subtitle: '+4.2% this month',
                                icon: Icons.bolt_rounded,
                              ),
                            ),
                            AppSpacing.gapW16,
                            Expanded(
                              child: _MetricCard(
                                title: 'Consistency',
                                value: '5 / 7',
                                subtitle: 'Sessions this week',
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                            AppSpacing.gapW16,
                            Expanded(
                              child: _MetricCard(
                                title: 'Best Faculty',
                                value: 'Speed',
                                subtitle: '84th percentile rank',
                                icon: Icons.insights_rounded,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _MetricCard(
                            title: 'Brain Index',
                            value: '82.4',
                            subtitle: '+4.2% this month',
                            icon: Icons.bolt_rounded,
                          ),
                          AppSpacing.gapH12,
                          _MetricCard(
                            title: 'Consistency',
                            value: '5 / 7',
                            subtitle: 'Sessions this week',
                            icon: Icons.calendar_today_rounded,
                          ),
                          AppSpacing.gapH12,
                          _MetricCard(
                            title: 'Best Faculty',
                            value: 'Speed',
                            subtitle: '84th percentile rank',
                            icon: Icons.insights_rounded,
                          ),
                        ],
                      );
                    },
                  ),
                  AppSpacing.gapH32,

                  // --- Curated Modules in Routine ---
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        'Scheduled Modules',
                        style: theme.textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.games),
                        child: const Text('View All Games'),
                      ),
                    ],
                  ),
                  AppSpacing.gapH12,
                  ...workout.games.map(
                    (game) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        onTap: () => _openGamePreview(context, game),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tokens.subtleBackground,
                                borderRadius: AppRadii.rMd,
                                border: Border.all(color: tokens.cardBorder),
                              ),
                              child: Icon(
                                game.domain.icon,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            AppSpacing.gapW16,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.title,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  AppSpacing.gapH4,
                                  Text(
                                    '${game.domain.label} • ${game.durationMinutes} min • ${game.difficulty}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // --- Scientific Insight Card ---
                  AppCard(
                    backgroundColor: tokens.subtleBackground,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cognitive Science Note',
                                style: theme.textTheme.titleSmall,
                              ),
                              AppSpacing.gapH4,
                              Text(
                                'Short, consistent daily training (6-10 minutes) yields greater neural adaptation and retention compared to infrequent long sessions.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWorkoutModal(BuildContext context, DailyWorkout workout) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: AppRadii.rTopXl,
        ),
        padding: AppSpacing.pXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.tokens.cardBorder,
                  borderRadius: AppRadii.rFull,
                ),
              ),
            ),
            AppSpacing.gapH24,
            Text(
              "Start Today's Workout",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.gapH8,
            Text(
              '${workout.games.length} exercises • ~${workout.estimatedMinutes} minutes total duration',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.gapH16,
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: workout.games.length,
                separatorBuilder: (context, index) => AppSpacing.gapH12,
                itemBuilder: (context, index) {
                  final game = workout.games[index];
                  return AppCard(
                    padding: AppSpacing.pMd,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: context.tokens.subtleBackground,
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${game.domain.label} • ${game.durationMinutes} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'Play',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openGamePreview(context, game);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            AppSpacing.gapH24,
            AppButton(
              label: 'Launch Full Routine Preview',
              isFullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                _openGamePreview(context, workout.games.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openGamePreview(BuildContext context, CognitiveGame game) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: AppSpacing.pXl,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close game',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  GameContainerPreview(
                    title: game.title,
                    domain: game.domain.label,
                    instructions: game.instructions,
                    durationMinutes: game.durationMinutes,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium,
              ),
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.onMintContainer,
            ),
          ),
        ],
      ),
    );
  }
}
