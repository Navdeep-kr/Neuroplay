import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_state_views.dart';
import 'package:neuroplay/features/progress/domain/progress_models.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/streak_calculator.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';

/// Cognitive Progress, Game History, Activity Calendar, and XP Showcase.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedGameId = 'memory-matrix';
  bool _showTrendTable = false;
  bool _showAccuracyTable = false;
  bool _showRtTable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                // Non-Clinical & Non-IQ Disclaimer Banner
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
                        Icons.info_outline_rounded,
                        size: 18,
                        color: isDark ? AppColors.mint400 : AppColors.mint500,
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'NEUROPLAY performance charts describe specific task proficiency and are not clinical cognitive assessments, medical diagnoses, or IQ measurements.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.navy700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Top Segmented Tab Navigation
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor:
                      isDark ? AppColors.darkTextSecondary : AppColors.navy500,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.insights_rounded, size: 20),
                      text: 'Overview & Faculty',
                    ),
                    Tab(
                      icon: Icon(Icons.sports_esports_outlined, size: 20),
                      text: 'Game Performance',
                    ),
                    Tab(
                      icon: Icon(Icons.emoji_events_outlined, size: 20),
                      text: 'XP & Achievements',
                    ),
                  ],
                  onTap: (index) => setState(() {}),
                ),
                AppSpacing.gapH24,

                // Active Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    switch (_tabController.index) {
                      case 0:
                        return _buildOverviewTab(context);
                      case 1:
                        return _buildGameHistoryTab(context);
                      case 2:
                        return _buildAchievementsTab(context);
                      default:
                        return _buildOverviewTab(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: OVERVIEW & FACULTY
  // =========================================================================

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final domainScoresAsync = ref.watch(domainScoresProvider);
    final weeklyTrendAsync = ref.watch(weeklyTrendProvider);
    final streakAsync = ref.watch(userStreakProvider);
    final activityAsync = ref.watch(monthlyActivityProvider(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak Card with Explicit Rules
        streakAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (streak) => _StreakStatusCard(streak: streak),
        ),
        AppSpacing.gapH24,

        // 7-Day Performance Trend Chart
        weeklyTrendAsync.when(
          loading: () => const AppLoadingView(message: 'Calculating trend...'),
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
                      _showTrendTable
                          ? Icons.bar_chart_rounded
                          : Icons.table_chart_outlined,
                    ),
                    tooltip: _showTrendTable
                        ? 'Switch to Bar Chart'
                        : 'Switch to Accessible Table',
                    onPressed: () => setState(
                      () => _showTrendTable = !_showTrendTable,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              AppCard(
                padding: AppSpacing.pXl,
                child: _showTrendTable
                    ? _AccessibleTrendTable(points: trendPoints)
                    : _AccessibleTrendBarChart(points: trendPoints),
              ),
            ],
          ),
        ),
        AppSpacing.gapH32,

        // Monthly Activity Calendar
        Text(
          'Daily Activity Calendar',
          style: theme.textTheme.headlineSmall,
        ),
        AppSpacing.gapH4,
        Text(
          'Training volume and daily completed routines for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
          style: theme.textTheme.bodySmall,
        ),
        AppSpacing.gapH16,
        activityAsync.when(
          loading: () => const AppLoadingView(message: 'Loading calendar...'),
          error: (_, __) => const SizedBox.shrink(),
          data: (records) => _MonthlyActivityGrid(records: records),
        ),
        AppSpacing.gapH32,

        // Cognitive Faculty Breakdown
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DomainScoreRow(score: ds),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: GAME-SPECIFIC HISTORY & CHARTS
  // =========================================================================

  Widget _buildGameHistoryTab(BuildContext context) {
    final theme = Theme.of(context);
    final games = WorkoutGenerator.catalog;
    final personalBestAsync =
        ref.watch(gamePersonalBestProvider(_selectedGameId));
    final sessionsAsync = ref.watch(gameSessionsProvider(_selectedGameId));

    final selectedGame = games.firstWhere(
      (g) => g.id == _selectedGameId,
      orElse: () => games.first,
    );
    final supportsReactionTime = _selectedGameId == 'reflex-forge' ||
        _selectedGameId == 'focus-reactor' ||
        _selectedGameId == 'number-pulse';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game Selector Chips
        Text(
          'Select Exercise',
          style: theme.textTheme.headlineSmall,
        ),
        AppSpacing.gapH8,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: games.map((g) {
              final isSelected = g.id == _selectedGameId;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(g.title),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedGameId = g.id);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        AppSpacing.gapH24,

        // Personal Bests Banner
        personalBestAsync.when(
          loading: () =>
              const AppLoadingView(message: 'Loading personal bests...'),
          error: (_, __) => const SizedBox.shrink(),
          data: (pb) => _PersonalBestCard(
            personalBest: pb,
            supportsReactionTime: supportsReactionTime,
          ),
        ),
        AppSpacing.gapH24,

        // Accuracy History Chart
        sessionsAsync.when(
          loading: () =>
              const AppLoadingView(message: 'Loading session data...'),
          error: (e, _) => AppErrorView(
            title: 'History Error',
            message: 'Could not load sessions: $e',
          ),
          data: (sessions) {
            final validSessions = sessions.where((s) => !s.isPractice).toList();

            if (validSessions.isEmpty) {
              return AppCard(
                padding: AppSpacing.pXl,
                child: Column(
                  children: [
                    const Icon(
                      Icons.history_toggle_off_rounded,
                      size: 40,
                      color: AppColors.navy400,
                    ),
                    AppSpacing.gapH12,
                    Text(
                      'No Standard Sessions Recorded Yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      'Play a standard mode session of ${selectedGame.title} to view longitudinal accuracy and latency charts.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Accuracy Chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accuracy History (%)',
                            style: theme.textTheme.titleLarge,
                          ),
                          AppSpacing.gapH4,
                          Text(
                            'Session accuracy trajectory across recent plays',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showAccuracyTable
                            ? Icons.show_chart_rounded
                            : Icons.table_chart_outlined,
                      ),
                      tooltip: _showAccuracyTable
                          ? 'Switch to Chart'
                          : 'Switch to Accessible Table',
                      onPressed: () => setState(
                        () => _showAccuracyTable = !_showAccuracyTable,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH12,
                AppCard(
                  padding: AppSpacing.pXl,
                  child: _showAccuracyTable
                      ? _AccessibleAccuracyTable(sessions: validSessions)
                      : _AccessibleAccuracyChart(sessions: validSessions),
                ),
                AppSpacing.gapH24,

                // 2. Response Time Chart (if applicable)
                if (supportsReactionTime) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Median Response Latency (ms)',
                              style: theme.textTheme.titleLarge,
                            ),
                            AppSpacing.gapH4,
                            Text(
                              'Lower latency reflects faster cognitive stimulus processing',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showRtTable
                              ? Icons.bar_chart_rounded
                              : Icons.table_chart_outlined,
                        ),
                        tooltip: _showRtTable
                            ? 'Switch to Chart'
                            : 'Switch to Accessible Table',
                        onPressed: () => setState(
                          () => _showRtTable = !_showRtTable,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH12,
                  AppCard(
                    padding: AppSpacing.pXl,
                    child: _showRtTable
                        ? _AccessibleRtTable(sessions: validSessions)
                        : _AccessibleRtChart(sessions: validSessions),
                  ),
                  AppSpacing.gapH24,
                ],

                // 3. Recent Sessions List
                Text(
                  'Recent Session Log',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.gapH4,
                Text(
                  'Distinguishing verified cloud data from local demo observations',
                  style: theme.textTheme.bodySmall,
                ),
                AppSpacing.gapH12,
                ...sessions.take(10).map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SessionHistoryTile(session: s),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: XP & ACHIEVEMENTS
  // =========================================================================

  Widget _buildAchievementsTab(BuildContext context) {
    final theme = Theme.of(context);
    final xpStateAsync = ref.watch(userXpStateProvider);
    final achievementsAsync = ref.watch(achievementsListProvider);
    final workoutsAsync = ref.watch(workoutSummariesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level & XP Progression Card
        xpStateAsync.when(
          loading: () => const AppLoadingView(message: 'Calculating XP...'),
          error: (_, __) => const SizedBox.shrink(),
          data: (xpState) => _XpProgressionCard(xpState: xpState),
        ),
        AppSpacing.gapH24,

        // Achievements Showcase
        Text(
          'Achievements Showcase',
          style: theme.textTheme.headlineSmall,
        ),
        AppSpacing.gapH4,
        Text(
          'Earn durable cognitive milestones by training consistently and mastering accuracy.',
          style: theme.textTheme.bodySmall,
        ),
        AppSpacing.gapH16,
        achievementsAsync.when(
          loading: () =>
              const AppLoadingView(message: 'Loading achievements...'),
          error: (_, __) => const SizedBox.shrink(),
          data: (items) => Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AchievementCard(item: item),
                  ),
                )
                .toList(),
          ),
        ),
        AppSpacing.gapH32,

        // Workout Completion Summaries
        Text(
          'Recent Workout Routines',
          style: theme.textTheme.headlineSmall,
        ),
        AppSpacing.gapH4,
        Text(
          'History of completed multi-game playlists',
          style: theme.textTheme.bodySmall,
        ),
        AppSpacing.gapH12,
        workoutsAsync.when(
          loading: () => const AppLoadingView(),
          error: (_, __) => const SizedBox.shrink(),
          data: (workouts) {
            if (workouts.isEmpty) {
              return AppCard(
                child: Center(
                  child: Text(
                    "No completed routines yet. Start today's workout to build your history.",
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            }
            return Column(
              children: workouts
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _WorkoutSummaryTile(workout: w),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// =========================================================================
// HELPER WIDGETS & ACCESSIBLE CHARTS
// =========================================================================

/// Streak card with honest rules modal
class _StreakStatusCard extends StatelessWidget {
  const _StreakStatusCard({required this.streak});

  final UserStreak streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveStreak = StreakCalculator.effectiveStreakAt(
      streak: streak,
      now: DateTime.now(),
    );

    return AppCard(
      padding: AppSpacing.pXl,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: AppSpacing.pSm,
                      decoration: BoxDecoration(
                        color: tokens.mintContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.mint500,
                        size: 28,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$effectiveStreak-Day Streak',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.gapH2,
                          Text(
                            streak.isActiveToday
                                ? 'Maintained today • Complete tomorrow to extend'
                                : 'Train today to maintain active continuity',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: streak.isActiveToday
                                  ? AppColors.success
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.navy700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Explicit Streak Rules',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Transparent Streak Rules'),
                      content: const SingleChildScrollView(
                        child: Text(
                          '1. Complete at least one training session or workout each calendar day to maintain your streak.\n\n'
                          '2. Multiple sessions on the same calendar day count toward your practice volume, but do not artificially increment your streak count.\n\n'
                          '3. If a full calendar day passes without training, the streak resets to zero upon the next session.\n\n'
                          '4. NEUROPLAY does not use deceptive streak freezes or punitive notifications.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Understood'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpacing.gapH16,
          const Divider(),
          AppSpacing.gapH8,
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Longest Streak',
                  value: '${streak.longestStreak} days',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Sessions Done',
                  value: '${streak.totalSessionsCompleted}',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Workouts Done',
                  value: '${streak.totalWorkoutsCompleted}',
                ),
              ),
            ],
          ),
        ],
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
        Text(value, style: theme.textTheme.titleMedium),
        AppSpacing.gapH2,
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Personal bests highlight card
class _PersonalBestCard extends StatelessWidget {
  const _PersonalBestCard({
    required this.personalBest,
    required this.supportsReactionTime,
  });

  final GamePersonalBest personalBest;
  final bool supportsReactionTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return AppCard(
      padding: AppSpacing.pXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Bests — ${personalBest.gameTitle}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppBadge(
                label: '${personalBest.totalSessions} Sessions',
                variant: AppBadgeVariant.mint,
              ),
            ],
          ),
          AppSpacing.gapH16,
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _MetricBox(
                icon: Icons.star_rounded,
                label: 'High Score',
                value: '${personalBest.highestScore}',
                color: theme.colorScheme.primary,
              ),
              _MetricBox(
                icon: Icons.track_changes_rounded,
                label: 'Best Accuracy',
                value: '${(personalBest.highestAccuracy * 100).round()}%',
                color: tokens.mintContainer,
              ),
              if (supportsReactionTime &&
                  personalBest.fastestMedianRtMs != null)
                _MetricBox(
                  icon: Icons.bolt_rounded,
                  label: 'Fastest Median RT',
                  value: '${personalBest.fastestMedianRtMs} ms',
                  color: AppColors.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        AppSpacing.gapW8,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Monthly Activity Heat-Grid
class _MonthlyActivityGrid extends StatelessWidget {
  const _MonthlyActivityGrid({required this.records});

  final List<ActivityDayRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    final summary = records
        .map(
          (r) =>
              'Day ${r.date.day}: ${r.sessionsCount} sessions, ${r.xpEarned} XP',
        )
        .join('; ');

    return Semantics(
      label: 'Monthly training activity calendar. $summary',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: records.map((r) {
                final hasWorkout = r.workoutCompleted;
                final hasSession = r.sessionsCount > 0;
                final isToday = r.date.day == DateTime.now().day &&
                    r.date.month == DateTime.now().month;

                Color bg;
                if (hasWorkout) {
                  bg = isDark ? AppColors.mint400 : AppColors.mint500;
                } else if (hasSession) {
                  bg = tokens.mintContainer;
                } else {
                  bg = isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9);
                }

                return Tooltip(
                  message:
                      '${DateFormat('MMM d').format(r.date)}: ${r.sessionsCount} sessions, ${r.xpEarned} XP${hasWorkout ? ' (Routine Completed)' : ''}',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppRadii.rSm,
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${r.date.day}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: hasWorkout
                              ? (isDark ? AppColors.navy900 : Colors.white)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.navy700),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.gapH12,
            Row(
              children: [
                _LegendItem(
                  color: isDark ? AppColors.mint400 : AppColors.mint500,
                  label: 'Routine Done',
                ),
                AppSpacing.gapW16,
                _LegendItem(
                  color: tokens.mintContainer,
                  label: 'Session Done',
                ),
                AppSpacing.gapW16,
                _LegendItem(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  label: 'Rest Day',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadii.rSm,
            ),
          ),
          AppSpacing.gapW4,
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}

/// Accessible Accuracy Chart
class _AccessibleAccuracyChart extends StatelessWidget {
  const _AccessibleAccuracyChart({required this.sessions});

  final List<GameSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recent = sessions.take(8).toList().reversed.toList();
    final summary = recent
        .asMap()
        .entries
        .map(
          (e) => 'Session ${e.key + 1}: ${(e.value.accuracy * 100).round()}%',
        )
        .join(', ');

    return Semantics(
      label: 'Session accuracy history chart. $summary',
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: recent.asMap().entries.map((entry) {
            final s = entry.value;
            final pct = (s.accuracy * 100).round();
            final heightFactor = s.accuracy.clamp(0.1, 1.0);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.navy700,
                      ),
                    ),
                    AppSpacing.gapH6,
                    Container(
                      height: 100 * heightFactor,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppRadii.rSm,
                      ),
                    ),
                    AppSpacing.gapH6,
                    Text(
                      '#${entry.key + 1}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Tabular alternative for Accuracy
class _AccessibleAccuracyTable extends StatelessWidget {
  const _AccessibleAccuracyTable({required this.sessions});

  final List<GameSessionRecord> sessions;

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
              child: Text('#', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Accuracy', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Score', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Date', style: theme.textTheme.labelMedium),
            ),
          ],
        ),
        ...sessions.take(8).map(
              (s) => TableRow(
                children: [
                  Padding(
                    padding: AppSpacing.pSm,
                    child: Text(
                      '${sessions.indexOf(s) + 1}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.pSm,
                    child: Text(
                      '${(s.accuracy * 100).round()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.pSm,
                    child:
                        Text('${s.score}', style: theme.textTheme.bodyMedium),
                  ),
                  Padding(
                    padding: AppSpacing.pSm,
                    child: Text(
                      DateFormat('MMM d').format(s.createdAt),
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

/// Accessible Reaction Time Chart
class _AccessibleRtChart extends StatelessWidget {
  const _AccessibleRtChart({required this.sessions});

  final List<GameSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    final recentWithRt = sessions
        .where((s) => s.medianReactionTimeMs != null)
        .take(8)
        .toList()
        .reversed
        .toList();

    if (recentWithRt.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No reaction time data logged yet.')),
      );
    }

    final summary = recentWithRt
        .asMap()
        .entries
        .map((e) => 'Session ${e.key + 1}: ${e.value.medianReactionTimeMs} ms')
        .join(', ');

    return Semantics(
      label: 'Median response latency chart. $summary',
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: recentWithRt.asMap().entries.map((entry) {
            final s = entry.value;
            final rt = s.medianReactionTimeMs!;
            final heightFactor = (rt / 1000).clamp(0.15, 1.0);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${rt}ms',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.navy700,
                      ),
                    ),
                    AppSpacing.gapH6,
                    Container(
                      height: 100 * heightFactor,
                      decoration: BoxDecoration(
                        color: tokens.mintContainer,
                        borderRadius: AppRadii.rSm,
                        border: Border.all(color: tokens.cardBorder),
                      ),
                    ),
                    AppSpacing.gapH6,
                    Text(
                      '#${entry.key + 1}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Accessible Reaction Time Table
class _AccessibleRtTable extends StatelessWidget {
  const _AccessibleRtTable({required this.sessions});

  final List<GameSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withRt =
        sessions.where((s) => s.medianReactionTimeMs != null).take(8).toList();

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
              child: Text('#', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Median RT', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Errors', style: theme.textTheme.labelMedium),
            ),
            Padding(
              padding: AppSpacing.pSm,
              child: Text('Date', style: theme.textTheme.labelMedium),
            ),
          ],
        ),
        ...withRt.map(
          (s) => TableRow(
            children: [
              Padding(
                padding: AppSpacing.pSm,
                child: Text(
                  '${withRt.indexOf(s) + 1}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: AppSpacing.pSm,
                child: Text(
                  '${s.medianReactionTimeMs} ms',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.pSm,
                child:
                    Text('${s.errorCount}', style: theme.textTheme.bodyMedium),
              ),
              Padding(
                padding: AppSpacing.pSm,
                child: Text(
                  DateFormat('MMM d').format(s.createdAt),
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

/// Session History Tile with Cloud vs Demo Badge
class _SessionHistoryTile extends StatelessWidget {
  const _SessionHistoryTile({required this.session});

  final GameSessionRecord session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSpacing.pMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  session.isPractice
                      ? Icons.fitness_center_rounded
                      : Icons.military_tech_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: ${session.score} • ${(session.accuracy * 100).round()}% Accuracy',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapH2,
                      Text(
                        '${DateFormat('MMM d, h:mm a').format(session.createdAt)} • ${session.durationSeconds}s duration',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapW8,
          AppBadge(
            label: session.isVerifiedCloud ? 'Verified Cloud' : 'Local / Demo',
            variant: session.isVerifiedCloud
                ? AppBadgeVariant.mint
                : AppBadgeVariant.outline,
          ),
        ],
      ),
    );
  }
}

/// XP Progression Card
class _XpProgressionCard extends StatelessWidget {
  const _XpProgressionCard({required this.xpState});

  final UserXpState xpState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: AppSpacing.pXl,
      child: Column(
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
                      'Level ${xpState.currentLevel} • ${xpState.levelTitle}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapH2,
                    Text(
                      '${xpState.totalXp} Total XP Earned',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW8,
              AppBadge(
                label: 'Tier ${xpState.currentLevel}',
                variant: AppBadgeVariant.mint,
              ),
            ],
          ),
          AppSpacing.gapH16,
          ClipRRect(
            borderRadius: AppRadii.rFull,
            child: LinearProgressIndicator(
              value: xpState.progressPercent,
              minHeight: 10,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          AppSpacing.gapH8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${xpState.xpForCurrentLevel} XP in level',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${xpState.xpToNextLevel} XP to Level ${xpState.currentLevel + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.mint400 : AppColors.mint500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual Achievement Item Card
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final AchievementItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: AppSpacing.pMd,
      child: Row(
        children: [
          Container(
            padding: AppSpacing.pSm,
            decoration: BoxDecoration(
              color: item.isUnlocked
                  ? context.tokens.mintContainer
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isUnlocked
                  ? Icons.military_tech_rounded
                  : Icons.lock_outline_rounded,
              color: item.isUnlocked
                  ? (isDark ? AppColors.mint400 : AppColors.mint500)
                  : AppColors.navy400,
              size: 24,
            ),
          ),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AppSpacing.gapW8,
                    AppBadge(
                      label: '+${item.xpReward} XP',
                      variant: item.isUnlocked
                          ? AppBadgeVariant.mint
                          : AppBadgeVariant.outline,
                    ),
                  ],
                ),
                AppSpacing.gapH2,
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall,
                ),
                if (item.isUnlocked && item.unlockedAt != null) ...[
                  AppSpacing.gapH4,
                  Text(
                    'Unlocked ${DateFormat('MMM d, yyyy').format(item.unlockedAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Workout Summary Tile
class _WorkoutSummaryTile extends StatelessWidget {
  const _WorkoutSummaryTile({required this.workout});

  final WorkoutSummaryRecord workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSpacing.pMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapH2,
                      Text(
                        '${DateFormat('EEEE, MMM d').format(workout.date)} • ${workout.durationMinutes} min',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapW8,
          AppBadge(
            label: workout.isCompleted ? 'COMPLETED' : 'PARTIAL',
            variant: workout.isCompleted
                ? AppBadgeVariant.mint
                : AppBadgeVariant.outline,
          ),
        ],
      ),
    );
  }
}

/// 7-Day Trend Bar Chart
class _AccessibleTrendBarChart extends StatelessWidget {
  const _AccessibleTrendBarChart({required this.points});

  final List<DailyScorePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    final semanticSummary =
        points.map((p) => '${p.dayLabel}: score ${p.scoreIndex}').join(', ');

    return Semantics(
      label: 'Weekly performance chart. $semanticSummary',
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: points.map((p) {
            final heightFactor = (p.scoreIndex / 100).clamp(0.1, 1.0);
            final isCurrent = p.dayLabel == 'Sun';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
    );
  }
}

/// Accessible table view alternative for trend chart
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
