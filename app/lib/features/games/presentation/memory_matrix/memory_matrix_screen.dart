import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/audio/sound_synthesizer.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_countdown_overlay.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_feedback_effects.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

/// Interactive playable screen for the Memory Matrix cognitive game.
class MemoryMatrixScreen extends ConsumerStatefulWidget {
  const MemoryMatrixScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  ConsumerState<MemoryMatrixScreen> createState() => _MemoryMatrixScreenState();
}

class _MemoryMatrixScreenState extends ConsumerState<MemoryMatrixScreen> {
  final MemoryMatrixDefinition _definition = MemoryMatrixDefinition();
  late GameSession _session;
  StreamSubscription<GameState>? _stateSubscription;
  Timer? _previewTimer;

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
    } else {
      _session.start();
      _schedulePreviewTimer();
    }
  }

  void _initSession({
    required GameDifficulty difficulty,
    required bool isPractice,
  }) {
    _previewTimer?.cancel();
    _stateSubscription?.cancel();

    final config = _definition.createDefaultConfig(
      difficulty: difficulty,
      isPractice: isPractice,
      seed: widget.seed,
    );

    _session = GameSession(
      id: 'mm-${DateTime.now().millisecondsSinceEpoch}',
      definition: _definition,
      config: config,
    );

    _comboStreak = 0;
    _finalResult = null;
    _stateSubscription = _session.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.isCompleted) {
          _previewTimer?.cancel();
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
        icon: Icons.grid_view_rounded,
        instructions:
            'A pattern of highlighted tiles will appear on the grid for a moment.\n\n'
            'Commit the pattern to memory, then reproduce the exact positions after the tiles clear.',
        tips: const [
          'Look for geometric clusters or lines rather than isolated points.',
          'Tiles are marked with distinct star symbols for easy recognition.',
          'Speed earns a small bonus, but accuracy avoids heavy penalties.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          setState(() => _showCountdown = true);
        },
      ),
    );
  }

  void _schedulePreviewTimer() {
    _previewTimer?.cancel();
    final config = _session.config as MemoryMatrixConfig;
    _previewTimer = Timer(config.previewDuration, () {
      if (!mounted || _session.isFinished) return;
      final engine = _session.engine as MemoryMatrixGameEngine;
      if (engine.roundState.isMemorizing) {
        _session
            .dispatch(BeginRecallAction(timestamp: _session.activeDuration));
        setState(() {});
      }
    });
  }

  void _onTileTapped(int index) {
    final engine = _session.engine as MemoryMatrixGameEngine;
    if (!engine.roundState.isRecalling) return;

    final isTarget = engine.roundState.targetIndices.contains(index);
    final alreadySelected =
        engine.roundState.selectedCorrectIndices.contains(index) ||
            engine.roundState.selectedMistakeIndices.contains(index);

    if (!alreadySelected) {
      if (isTarget) {
        _comboStreak++;
        SoundSynthesizer.playSuccess(streak: _comboStreak);
      } else {
        _comboStreak = 0;
        _shakeTrigger++;
        SoundSynthesizer.playError();
      }
    }

    final wasMemorizing = engine.roundState.isMemorizing;
    _session.dispatch(
      SelectTileAction(
        timestamp: _session.activeDuration,
        tileIndex: index,
      ),
    );

    // If new round started, re-schedule preview timer
    if (!wasMemorizing &&
        engine.roundState.isMemorizing &&
        !_session.isFinished) {
      _schedulePreviewTimer();
    }
    setState(() {});
  }

  void _handlePause() {
    _previewTimer?.cancel();
    _session.pause(reason: 'user_pause_menu');
    setState(() {});

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _session.resume();
          final engine = _session.engine as MemoryMatrixGameEngine;
          if (engine.roundState.isMemorizing) {
            _schedulePreviewTimer();
          }
          setState(() {});
        },
        onRestart: () {
          Navigator.of(context).pop();
          _initSession(
            difficulty: _session.config.difficulty,
            isPractice: (_session.config as MemoryMatrixConfig).isPractice,
          );
          _session.start();
          _schedulePreviewTimer();
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
    _previewTimer?.cancel();
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
                isPractice: (_session.config as MemoryMatrixConfig).isPractice,
              );
              _session.start();
              _schedulePreviewTimer();
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

    final engine = _session.engine as MemoryMatrixGameEngine;
    final config = _session.config as MemoryMatrixConfig;
    final roundState = engine.roundState;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
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
                      // Top HUD Header with live combo streak
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

                      // Phase Indicator Banner
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildPhaseBanner(theme, roundState),
                      ),
                      AppSpacing.gapH24,

                      // Main Interactive Grid with error shake physics
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 420,
                                maxHeight: 420,
                              ),
                              child: ShakeWidget(
                                shakeTrigger: _shakeTrigger,
                                child: _buildGrid(theme, config, roundState),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom skip button for preview
                      if (roundState.isMemorizing)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppButton(
                            label: 'Ready to Recall',
                            icon: Icons.check_circle_outline_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: () {
                              _previewTimer?.cancel();
                              _session.dispatch(
                                BeginRecallAction(
                                  timestamp: _session.activeDuration,
                                ),
                              );
                              setState(() {});
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Text(
                            'Select the illuminated squares (${roundState.selectedCorrectIndices.length}/${roundState.targetIndices.length})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.navy500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Cinematic Focus Countdown Overlay
              if (_showCountdown)
                Positioned.fill(
                  child: GameCountdownOverlay(
                    onComplete: () {
                      setState(() => _showCountdown = false);
                      _session.start();
                      _schedulePreviewTimer();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseBanner(ThemeData theme, MemoryMatrixRoundState roundState) {
    if (roundState.isMemorizing) {
      return Container(
        key: const ValueKey('memorize_banner'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.mint500.withValues(alpha: 0.15),
          borderRadius: AppRadii.rFull,
          border: Border.all(
            color: AppColors.mint500.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility_rounded,
              size: 18,
              color: AppColors.mint500,
            ),
            AppSpacing.gapW8,
            Text(
              'MEMORIZE PATTERN',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mint500,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        key: const ValueKey('recall_banner'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadii.rFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 18),
            AppSpacing.gapW8,
            Text(
              'RECALL TILES',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGrid(
    ThemeData theme,
    MemoryMatrixConfig config,
    MemoryMatrixRoundState roundState,
  ) {
    final size = config.gridSize;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: config.totalTiles,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final isTarget = roundState.targetIndices.contains(index);
        final isSelectedCorrect =
            roundState.selectedCorrectIndices.contains(index);
        final isSelectedMistake =
            roundState.selectedMistakeIndices.contains(index);

        final showHighlighted =
            (roundState.isMemorizing && isTarget) || isSelectedCorrect;

        final Color tileColor;
        final Widget? tileIcon;
        final List<BoxShadow>? tileGlow;

        if (showHighlighted) {
          tileColor = AppColors.mint500;
          tileGlow = [
            BoxShadow(
              color: AppColors.mint500.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ];
          tileIcon = const Icon(
            Icons.star_rounded,
            color: AppColors.navy900,
            size: 28,
          );
        } else if (isSelectedMistake) {
          tileColor = AppColors.error.withValues(alpha: 0.25);
          tileGlow = [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.35),
              blurRadius: 10,
            ),
          ];
          tileIcon = const Icon(
            Icons.close_rounded,
            color: AppColors.error,
            size: 24,
          );
        } else {
          tileColor = theme.colorScheme.surfaceContainerHighest;
          tileGlow = null;
          tileIcon = null;
        }

        final row = (index ~/ size) + 1;
        final col = (index % size) + 1;

        return Semantics(
          label: 'Grid tile row $row column $col'
              '${showHighlighted ? ', target tile' : ''}'
              '${isSelectedMistake ? ', mistake' : ''}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: AppRadii.rLg,
              boxShadow: tileGlow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadii.rLg,
              child: InkWell(
                borderRadius: AppRadii.rLg,
                onTap:
                    roundState.isRecalling ? () => _onTileTapped(index) : null,
                child: Center(child: tileIcon),
              ),
            ),
          ),
        );
      },
    );
  }
}
