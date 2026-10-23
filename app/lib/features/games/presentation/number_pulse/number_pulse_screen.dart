import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

/// Interactive playable screen for Number Pulse mental arithmetic and sequence reasoning.
class NumberPulseScreen extends ConsumerStatefulWidget {
  const NumberPulseScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  ConsumerState<NumberPulseScreen> createState() => _NumberPulseScreenState();
}

class _NumberPulseScreenState extends ConsumerState<NumberPulseScreen> {
  final NumberPulseDefinition _definition = NumberPulseDefinition();
  late GameSession _session;
  StreamSubscription<GameState>? _stateSubscription;
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _initSession(difficulty: widget.initialDifficulty, isPractice: false);

    if (!widget.startImmediately) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showTutorialDialog());
    } else {
      _session.start();
    }
  }

  void _initSession({
    required GameDifficulty difficulty,
    required bool isPractice,
  }) {
    _stateSubscription?.cancel();

    final config = _definition.createDefaultConfig(
      difficulty: difficulty,
      isPractice: isPractice,
      seed: widget.seed,
    );

    _session = GameSession(
      id: 'np-${DateTime.now().millisecondsSinceEpoch}',
      definition: _definition,
      config: config,
    );

    _finalResult = null;
    _stateSubscription = _session.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.isCompleted) {
          _finalResult = _session.finish(isOffline: true);
          _recordResult(_finalResult!);
        }
      });
    });
  }

  void _recordResult(GameResult result) {
    final workoutState = ref.read(workoutSessionProvider);
    if (workoutState != null) {
      ref.read(workoutSessionProvider.notifier).recordGameResult(result);
    } else {
      ref.read(trainingRepositoryProvider).recordGameSession(result);
    }
  }

  void _showTutorialDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameTutorialDialog(
        title: _definition.name,
        category: _definition.category,
        icon: Icons.numbers_rounded,
        instructions:
            'Identify the mathematical rule governing each numerical sequence.\n\n'
            'Calculate the missing number marked with "?" and select the correct option among 4 choices.',
        tips: const [
          'Look for common patterns: arithmetic steps, multiplication ratios, alternating steps, or additive Fibonacci sums.',
          'Respond swiftly to earn higher speed and streak bonuses.',
          'Use keyboard keys 1, 2, 3, 4 for rapid input.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          _session.start();
        },
      ),
    );
  }

  void _handleChoice(int optionValue) {
    if (_session.isFinished) return;
    final engine = _session.engine as NumberPulseGameEngine;
    if (engine.trialState.isAnswered) return;

    _session.dispatch(
      SelectNumberPulseAnswerAction(
        timestamp: _session.activeDuration,
        selectedAnswer: optionValue,
      ),
    );
    setState(() {});
  }

  void _handlePause() {
    if (_session.isFinished) return;
    _session.pause(reason: 'user_pause_menu');
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _session.resume();
          setState(() {});
        },
        onRestart: () {
          Navigator.of(context).pop();
          _initSession(
            difficulty: _session.config.difficulty,
            isPractice: (_session.config as NumberPulseConfig).isPractice,
          );
          _session.start();
          setState(() {});
        },
        onQuit: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.games);
        },
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_finalResult != null) {
      final workoutState = ref.watch(workoutSessionProvider);
      final hasNext = workoutState != null &&
          workoutState.nextGame != null &&
          !workoutState.isCompleted;
      final isWorkoutDone = workoutState?.isCompleted ?? false;

      return Scaffold(
        body: SafeArea(
          child: GameCompletionView(
            result: _finalResult!,
            gameTitle: _definition.name,
            onPlayAgain: () {
              _initSession(
                difficulty: _session.config.difficulty,
                isPractice: false,
              );
              _session.start();
              setState(() {});
            },
            onBackToLibrary: () {
              ref.read(workoutSessionProvider.notifier).endWorkout();
              context.go(AppRoutes.games);
            },
            onNextInWorkout: hasNext
                ? () {
                    final next = ref
                        .read(workoutSessionProvider.notifier)
                        .advanceToNextGame();
                    if (next != null && next.route.isNotEmpty) {
                      context.go(next.route);
                    } else {
                      context.go(AppRoutes.home);
                    }
                  }
                : null,
            nextGameTitle: workoutState?.nextGame?.title,
            isWorkoutCompleted: isWorkoutDone,
          ),
        ),
      );
    }

    final engine = _session.engine as NumberPulseGameEngine;
    final config = _session.config as NumberPulseConfig;
    final trial = engine.trialState;
    final q = trial.question;

    return CallbackShortcuts(
      bindings: {
        if (q.options.isNotEmpty)
          const SingleActivator(LogicalKeyboardKey.digit1): () =>
              _handleChoice(q.options[0]),
        if (q.options.length > 1)
          const SingleActivator(LogicalKeyboardKey.digit2): () =>
              _handleChoice(q.options[1]),
        if (q.options.length > 2)
          const SingleActivator(LogicalKeyboardKey.digit3): () =>
              _handleChoice(q.options[2]),
        if (q.options.length > 3)
          const SingleActivator(LogicalKeyboardKey.digit4): () =>
              _handleChoice(q.options[3]),
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                GameHeader(
                  title: _definition.name,
                  currentRound: _session.state.currentRound,
                  totalRounds: _session.state.totalRounds,
                  score: _session.state.score,
                  isPractice: config.isPractice,
                  onPause: _handlePause,
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Streak badge & Pattern type indicator
                            Wrap(
                              spacing: AppSpacing.sm,
                              alignment: WrapAlignment.center,
                              children: [
                                AppBadge(
                                  label: q.patternType.label,
                                  variant: AppBadgeVariant.mint,
                                ),
                                if (engine.currentStreak > 1)
                                  AppBadge(
                                    label: '${engine.currentStreak} In a Row',
                                    variant: AppBadgeVariant.success,
                                    icon: Icons.local_fire_department_rounded,
                                  ),
                              ],
                            ),

                            AppSpacing.gapH24,

                            // Sequence Display
                            _buildSequenceDisplay(q, isDark),

                            AppSpacing.gapH32,

                            // 4 Choice Options
                            _buildOptionsGrid(q, isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSequenceDisplay(NumberPulseQuestion q, bool isDark) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: List.generate(q.sequence.length, (i) {
                  final isMissing = i == q.missingIndex;
                  final valueText =
                      isMissing ? '?' : _numberFormat.format(q.sequence[i]);

                  return Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isMissing
                          ? AppColors.mint500.withValues(alpha: 0.15)
                          : (isDark ? AppColors.navy800 : AppColors.slate50),
                      borderRadius: AppRadii.rMd,
                      border: Border.all(
                        color: isMissing
                            ? AppColors.mint500
                            : (isDark ? AppColors.navy700 : AppColors.slate200),
                        width: isMissing ? 2.5 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      valueText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isMissing
                            ? AppColors.mint600
                            : (isDark ? Colors.white : AppColors.navy900),
                      ),
                    ),
                  );
                }),
              ),
              AppSpacing.gapH12,
              Text(
                'Determine the missing value in the sequence',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.navy400 : AppColors.navy600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildOptionsGrid(NumberPulseQuestion q, bool isDark) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: q.options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemBuilder: (context, index) {
          final option = q.options[index];
          final keyLabel = '${index + 1}';
          final formattedValue = _numberFormat.format(option);

          return Semantics(
            label: 'Option $keyLabel: $formattedValue',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleChoice(option),
                borderRadius: AppRadii.rLg,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.pureWhite,
                    borderRadius: AppRadii.rLg,
                    border: Border.all(
                      color: isDark ? AppColors.navy700 : AppColors.slate200,
                      width: 1.5,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? AppColors.navy800 : AppColors.slate100,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          keyLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? AppColors.navy400 : AppColors.navy600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          formattedValue,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.navy900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
