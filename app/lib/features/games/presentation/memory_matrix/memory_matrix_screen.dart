import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/audio/sound_synthesizer.dart';
import 'package:neuroplay/core/constants.dart';
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

/// Highly visual and colorful playable screen for Memory Matrix.
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

    // Immediately start session engine so state and targets are deterministic & initialized
    _session.start();

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
            'A vibrant pattern of illuminated tiles will appear on the grid for a moment.\n\n'
            'Commit their exact positions to memory, then tap all illuminated squares after they clear.',
        tips: const [
          'Look for geometric clusters, lines, or symmetries.',
          'Tiles are marked with glowing stars for instant clarity.',
          'Fast accurate responses build ascending musical combo streaks!',
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
          backgroundColor: const Color(0xFF090D16),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.3,
                colors: [
                  Color(0xFF0F2338),
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
                        // HUD Header with live combo streak
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

                        // Main Interactive Colorful Grid Arena
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                  maxHeight: 440,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: AppRadii.rXxl,
                                    border: Border.all(
                                      color: roundState.isMemorizing
                                          ? const Color(0xFF00F5FF)
                                          : const Color(0xFF06B6D4),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (roundState.isMemorizing
                                                ? const Color(0xFF00F5FF)
                                                : const Color(0xFF06B6D4))
                                            .withValues(alpha: 0.3),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ShakeWidget(
                                    shakeTrigger: _shakeTrigger,
                                    child:
                                        _buildGrid(theme, config, roundState),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom action controls
                        if (roundState.isMemorizing)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: AppButton(
                              label: 'Ready to Recall',
                              icon: Icons.check_circle_outline_rounded,
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Select the illuminated squares (${roundState.selectedCorrectIndices.length}/${roundState.targetIndices.length})',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                AppSpacing.gapH8,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0;
                                        i < roundState.targetIndices.length;
                                        i++)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i <
                                                  roundState
                                                      .selectedCorrectIndices
                                                      .length
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF334155),
                                          boxShadow: i <
                                                  roundState
                                                      .selectedCorrectIndices
                                                      .length
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF10B981)
                                                            .withValues(
                                                      alpha: 0.6,
                                                    ),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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
                        _schedulePreviewTimer();
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

  Widget _buildPhaseBanner(ThemeData theme, MemoryMatrixRoundState roundState) {
    if (roundState.isMemorizing) {
      return Container(
        key: const ValueKey('memorize_banner'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00F5FF), Color(0xFF06B6D4)],
          ),
          borderRadius: AppRadii.rFull,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_red_eye_rounded,
              size: 20,
              color: Color(0xFF090D16),
            ),
            SizedBox(width: 8),
            Text(
              'MEMORIZE PATTERN',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF090D16),
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        key: const ValueKey('recall_banner'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: AppRadii.rFull,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'RECALL TILES',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
                fontSize: 13,
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

        final Decoration decoration;
        final Widget? tileIcon;

        if (showHighlighted) {
          decoration = BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00F5FF), Color(0xFF10B981)],
            ),
            borderRadius: AppRadii.rLg,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          );
          tileIcon = const Icon(
            Icons.star_rounded,
            color: Color(0xFF0F172A),
            size: 32,
          );
        } else if (isSelectedMistake) {
          decoration = BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            ),
            borderRadius: AppRadii.rLg,
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                blurRadius: 14,
              ),
            ],
          );
          tileIcon = const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 28,
          );
        } else {
          decoration = BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: AppRadii.rLg,
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1.5,
            ),
          );
          tileIcon = null;
        }

        final row = (index ~/ size) + 1;
        final col = (index % size) + 1;

        return Semantics(
          label: 'Grid tile row $row column $col'
              '${showHighlighted ? ', target tile' : ''}'
              '${isSelectedMistake ? ', mistake' : ''}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            decoration: decoration,
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
