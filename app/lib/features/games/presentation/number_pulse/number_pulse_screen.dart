import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/core/audio/sound_synthesizer.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_countdown_overlay.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_feedback_effects.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

/// Highly visual and colorful playable screen for Number Pulse arithmetic reasoning.
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
  bool _showCountdown = false;
  int _comboStreak = 0;
  int _shakeTrigger = 0;

  @override
  void initState() {
    super.initState();
    _initSession(difficulty: widget.initialDifficulty, isPractice: false);

    if (!widget.startImmediately) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showTutorialDialog());
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

    // Immediately start session so trialState is initialized
    _session.start();

    _comboStreak = 0;
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
          setState(() => _showCountdown = true);
        },
      ),
    );
  }

  void _handleChoice(int optionValue) {
    if (_session.isFinished) return;
    final engine = _session.engine as NumberPulseGameEngine;
    if (engine.trialState.isAnswered) return;

    final isCorrect = optionValue == engine.trialState.question.correctAnswer;
    if (isCorrect) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
    } else {
      _comboStreak = 0;
      _shakeTrigger++;
      SoundSynthesizer.playError();
    }

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
                isPractice: (_session.config as NumberPulseConfig).isPractice,
              );
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        if (trial.question.options.isNotEmpty)
          const SingleActivator(LogicalKeyboardKey.digit1): () =>
              _handleChoice(trial.question.options[0]),
        if (trial.question.options.length > 1)
          const SingleActivator(LogicalKeyboardKey.digit2): () =>
              _handleChoice(trial.question.options[1]),
        if (trial.question.options.length > 2)
          const SingleActivator(LogicalKeyboardKey.digit3): () =>
              _handleChoice(trial.question.options[2]),
        if (trial.question.options.length > 3)
          const SingleActivator(LogicalKeyboardKey.digit4): () =>
              _handleChoice(trial.question.options[3]),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF090D16),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.3,
                colors: [
                  Color(0xFF230E38),
                  Color(0xFF090D16),
                ],
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        GameHeader(
                          title: _definition.name,
                          currentRound: _session.state.currentRound,
                          totalRounds: _session.state.totalRounds,
                          score: _session.state.score,
                          comboStreak: _comboStreak,
                          isPractice: config.isPractice,
                          onPause: _handlePause,
                        ),
                        AppSpacing.gapH24,

                        // Category Pattern Badge with gradient
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                            ),
                            borderRadius: AppRadii.rFull,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFA855F7)
                                    .withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Text(
                            'PATTERN: ${trial.question.patternType.label.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        AppSpacing.gapH12,

                        // Number sequence cards with error shake
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 540),
                              child: ShakeWidget(
                                shakeTrigger: _shakeTrigger,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildSequenceView(theme, trial),
                                    AppSpacing.gapH16,
                                    _buildChoiceGrid(theme, trial),
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

                // Focus Countdown Overlay
                if (_showCountdown)
                  Positioned.fill(
                    child: GameCountdownOverlay(
                      onComplete: () {
                        setState(() => _showCountdown = false);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSequenceView(ThemeData theme, NumberPulseTrialState trial) {
    final sequence = trial.question.sequence;
    final missingIndex = trial.question.missingIndex;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          const Text(
            'COMPLETE THE SEQUENCE',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          AppSpacing.gapH12,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < sequence.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  _buildSequenceTile(
                    theme,
                    value: sequence[i],
                    isMissing: i == missingIndex,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceTile(
    ThemeData theme, {
    required int? value,
    required bool isMissing,
  }) {
    if (isMissing) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00F5FF), Color(0xFFA855F7), Color(0xFFEC4899)],
          ),
          borderRadius: AppRadii.rXl,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.65),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: AppRadii.rXl,
        border: Border.all(
          color: const Color(0xFFA855F7).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          value != null ? _numberFormat.format(value) : '',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceGrid(ThemeData theme, NumberPulseTrialState trial) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trial.question.options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.2,
        ),
        itemBuilder: (context, index) {
          final option = trial.question.options[index];
          return Semantics(
            label: 'Option ${index + 1}: $option',
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: AppRadii.rXl,
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppRadii.rXl,
                child: InkWell(
                  borderRadius: AppRadii.rXl,
                  onTap: () => _handleChoice(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFA855F7)
                                    .withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _numberFormat.format(option),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
