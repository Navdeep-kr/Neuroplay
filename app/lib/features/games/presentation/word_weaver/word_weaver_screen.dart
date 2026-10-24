import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Highly visual and colorful playable screen for Word Weaver semantic association.
class WordWeaverScreen extends ConsumerStatefulWidget {
  const WordWeaverScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  ConsumerState<WordWeaverScreen> createState() => _WordWeaverScreenState();
}

class _WordWeaverScreenState extends ConsumerState<WordWeaverScreen> {
  final WordWeaverDefinition _definition = WordWeaverDefinition();
  late GameSession _session;
  StreamSubscription<GameState>? _stateSubscription;

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
      id: 'ww-${DateTime.now().millisecondsSinceEpoch}',
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
        icon: Icons.auto_stories_rounded,
        instructions: 'Observe the Anchor Word and its designated domain.\n\n'
            'Identify which of the 4 options shares the same semantic category or concept.',
        tips: const [
          'Filter out distractors by checking if they belong to unrelated domains.',
          'Respond swiftly to earn higher speed and streak bonuses.',
          'Use keyboard keys 1, 2, 3, 4 for instantaneous response.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          setState(() => _showCountdown = true);
        },
      ),
    );
  }

  void _handleChoice(String optionWord) {
    if (_session.isFinished) return;
    final engine = _session.engine as WordWeaverGameEngine;
    if (engine.trialState.isAnswered) return;

    final isCorrect =
        optionWord == engine.trialState.question.correctAssociatedWord;
    if (isCorrect) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
    } else {
      _comboStreak = 0;
      _shakeTrigger++;
      SoundSynthesizer.playError();
    }

    _session.dispatch(
      SelectWordAssociationAction(
        timestamp: _session.activeDuration,
        selectedWord: optionWord,
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
            isPractice: (_session.config as WordWeaverConfig).isPractice,
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
                isPractice: (_session.config as WordWeaverConfig).isPractice,
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

    final engine = _session.engine as WordWeaverGameEngine;
    final config = _session.config as WordWeaverConfig;
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
          body: Stack(
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

                      // Anchor Word Card with error shake
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: ShakeWidget(
                              shakeTrigger: _shakeTrigger,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAnchorCard(theme, trial),
                                  AppSpacing.gapH32,
                                  _buildChoicesGrid(theme, trial),
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
    );
  }

  Widget _buildAnchorCard(ThemeData theme, WordWeaverTrialState trial) =>
      AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                ),
                borderRadius: AppRadii.rFull,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                trial.question.category.displayName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
            ),
            AppSpacing.gapH16,
            Text(
              trial.question.anchorWord,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH8,
            const Text(
              'Select the associated term from the same domain',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildChoicesGrid(ThemeData theme, WordWeaverTrialState trial) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trial.question.options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (context, index) {
          final word = trial.question.options[index];
          return Semantics(
            label: 'Option ${index + 1}: $word',
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: AppRadii.rXl,
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppRadii.rXl,
                child: InkWell(
                  borderRadius: AppRadii.rXl,
                  onTap: () => _handleChoice(word),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              word,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
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
