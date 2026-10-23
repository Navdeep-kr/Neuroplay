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

/// Progress and cognitive analytics screen.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _showTableView = false;

  @override
  Widget build(BuildContext context) {
    final domainScoresAsync = ref.watch(domainScoresProvider);
    final weeklyTrendAsync = ref.watch(weeklyTrendProvider);
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
                  'Cognitive Progress',
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.gapH4,
                Text(
                  'Track longitudinal performance across memory, attention, and executive function.',
                  style: theme.textTheme.bodyMedium,
                ),
                AppSpacing.gapH16,

                // Prototype / Mock Data Notice
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
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: isDark ? AppColors.mint400 : AppColors.mint700,
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'Preview Metrics — Typed demo dataset simulating Phase 4 statistical aggregation.',
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

                // Weekly Trend Visual Placeholder
                weeklyTrendAsync.when(
                  loading: () =>
                      const AppLoadingView(message: 'Calculating trend...'),
                  error: (err, stack) => AppErrorView(
                    title: 'Chart Error',
                    message: 'Could not compute trend data.',
                    onRetry: () => ref.refresh(weeklyTrendProvider),
                  ),
                  data: (trendPoints) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '7-Day Training Trend',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                AppSpacing.gapH4,
                                Text(
                                  'Overall cognitive index score per day (0-100 scale)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _showTableView
                                  ? Icons.bar_chart_rounded
                                  : Icons.table_chart_outlined,
                            ),
                            tooltip: _showTableView
                                ? 'Switch to Bar Chart'
                                : 'Switch to Accessible Table',
                            onPressed: () => setState(
                              () => _showTableView = !_showTableView,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,
                      AppCard(
                        padding: AppSpacing.pXl,
                        child: _showTableView
                            ? _AccessibleTrendTable(points: trendPoints)
                            : _AccessibleTrendBarChart(points: trendPoints),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH32,

                // Domain Performance Breakdown
                Text(
                  'Cognitive Faculty Breakdown',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH4,
                Text(
                  'Performance percentiles compared to baseline peer cohort',
                  style: theme.textTheme.bodySmall,
                ),
                AppSpacing.gapH16,

                domainScoresAsync.when(
                  loading: () => const AppLoadingView(),
                  error: (err, stack) => AppErrorView(
                    title: 'Scores unavailable',
                    message: 'Could not load domain breakdown.',
                    onRetry: () => ref.refresh(domainScoresProvider),
                  ),
                  data: (domainScores) => Column(
                    children: domainScores
                        .map(
                          (ds) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _DomainScoreRow(score: ds),
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

/// Accessible chart visualization using native semantic elements.
class _AccessibleTrendBarChart extends StatelessWidget {
  const _AccessibleTrendBarChart({required this.points});

  final List<DailyScorePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    // Generate semantic description for screen readers
    final semanticSummary =
        points.map((p) => '${p.dayLabel}: score ${p.scoreIndex}').join(', ');

    return Semantics(
      label: 'Weekly performance chart. $semanticSummary',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: points.map((p) {
                final heightFactor = (p.scoreIndex / 100).clamp(0.1, 1.0);
                final isCurrent = p.dayLabel == 'Sun';

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${p.scoreIndex}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.navy700),
                          ),
                        ),
                        AppSpacing.gapH8,
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 120 * heightFactor,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : tokens.mintContainer,
                            borderRadius: AppRadii.rSm,
                            border: Border.all(
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : tokens.cardBorder,
                            ),
                          ),
                        ),
                        AppSpacing.gapH8,
                        Text(
                          p.dayLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCurrent ? theme.colorScheme.primary : null,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible table view alternative for chart data.
class _AccessibleTrendTable extends StatelessWidget {
  const _AccessibleTrendTable({required this.points});

  final List<DailyScorePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: context.tokens.cardBorder)),
          ),
          children: [
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Day', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Score Index', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Status', style: theme.textTheme.labelMedium),
            ),
          ],
        ),
        ...points.map(
          (p) => TableRow(
            children: [
              Padding(
                padding: AppSpacing.pSm,
                child: Text(p.dayLabel, style: theme.textTheme.bodyMedium),
              ),
              Padding(
                padding: AppSpacing.pSm,
                child: Text(
                  '${p.scoreIndex} / 100',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: AppSpacing.pSm,
                child: Text(
                  p.isCompletedDay ? 'Completed' : 'Scheduled',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DomainScoreRow extends StatelessWidget {
  const _DomainScoreRow({required this.score});

  final DomainScore score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    score.domain.icon,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacing.gapW12,
                  Text(
                    score.domain.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBadge(
                    label: '${score.percentileRank}th percentile',
                  ),
                  AppSpacing.gapW8,
                  Text(
                    '${score.scoreIndex}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.gapH12,
          ClipRRect(
            borderRadius: AppRadii.rFull,
            child: LinearProgressIndicator(
              value: score.scoreIndex / 100,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          AppSpacing.gapH8,
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              Text(
                score.domain.description,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                score.trendPercentage >= 0
                    ? '+${score.trendPercentage}% trend'
                    : '${score.trendPercentage}% trend',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: score.trendPercentage >= 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
