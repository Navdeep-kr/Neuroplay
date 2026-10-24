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
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_countdown_overlay.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_feedback_effects.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

/// Interactive playable screen for the Logic Labyrinth path-planning exercise.
class LogicLabyrinthScreen extends ConsumerStatefulWidget {
  const LogicLabyrinthScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  ConsumerState<LogicLabyrinthScreen> createState() =>
      _LogicLabyrinthScreenState();
}

class _LogicLabyrinthScreenState extends ConsumerState<LogicLabyrinthScreen> {
  final LogicLabyrinthDefinition _definition = LogicLabyrinthDefinition();
  late GameSession _session;
  StreamSubscription<GameState>? _stateSubscription;

  GameResult? _finalResult;
  bool _showCountdown = false;
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
      id: 'll-${DateTime.now().millisecondsSinceEpoch}',
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
        icon: Icons.alt_route_rounded,
        instructions:
            'Navigate from the Start tile to the Target exit in as few moves as possible.\n\n'
            'Avoid solid walls and remember to pick up the Star Checkpoint if one is present before reaching the exit.',
        tips: const [
          'Study the shortest route before making your first move.',
          'Bumping into walls or taking excess steps will penalize your par bonus.',
          'Use the D-pad buttons or keyboard arrows / WASD to navigate.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          setState(() => _showCountdown = true);
        },
      ),
    );
  }

  void _handleDirection(LabyrinthDirection direction) {
    if (_session.isFinished) return;
    final engine = _session.engine as LogicLabyrinthGameEngine;
    final oldPos = engine.roundState.playerPos;
    final hadKey = engine.roundState.checkpointCollected;

    _session.dispatch(
      MoveLabyrinthAction(
        timestamp: _session.activeDuration,
        direction: direction,
      ),
    );

    final newPos = engine.roundState.playerPos;
    if (newPos == oldPos) {
      // Hit wall
      _shakeTrigger++;
      SoundSynthesizer.playError();
    } else {
      if (!hadKey && engine.roundState.checkpointCollected) {
        SoundSynthesizer.playSuccess(streak: 3);
      } else {
        SoundSynthesizer.playCountdown();
      }
    }

    setState(() {});
  }

  void _handleReset() {
    if (_session.isFinished) return;
    _session.dispatch(
      ResetCurrentMazeAction(timestamp: _session.activeDuration),
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
            isPractice: (_session.config as LogicLabyrinthConfig).isPractice,
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
                isPractice:
                    (_session.config as LogicLabyrinthConfig).isPractice,
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

    final engine = _session.engine as LogicLabyrinthGameEngine;
    final config = _session.config as LogicLabyrinthConfig;
    final round = engine.roundState;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _handleDirection(LabyrinthDirection.up),
        const SingleActivator(LogicalKeyboardKey.keyW): () =>
            _handleDirection(LabyrinthDirection.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _handleDirection(LabyrinthDirection.down),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            _handleDirection(LabyrinthDirection.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _handleDirection(LabyrinthDirection.left),
        const SingleActivator(LogicalKeyboardKey.keyA): () =>
            _handleDirection(LabyrinthDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _handleDirection(LabyrinthDirection.right),
        const SingleActivator(LogicalKeyboardKey.keyD): () =>
            _handleDirection(LabyrinthDirection.right),
        const SingleActivator(LogicalKeyboardKey.keyR): _handleReset,
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              SafeArea(
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
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Round info badges
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    AppBadge(
                                      label: 'Steps: ${round.stepCount}',
                                    ),
                                    AppBadge(
                                      label: 'Par: ${round.optimalPathLength}',
                                      variant: AppBadgeVariant.mint,
                                    ),
                                    if (round.checkpoint != null)
                                      AppBadge(
                                        label: round.checkpointCollected
                                            ? 'Key Collected'
                                            : 'Collect Key First',
                                        variant: round.checkpointCollected
                                            ? AppBadgeVariant.success
                                            : AppBadgeVariant.warning,
                                        icon: round.checkpointCollected
                                            ? Icons.check_circle_rounded
                                            : Icons.star_rounded,
                                      ),
                                  ],
                                ),
                              ),

                              // Maze Board with error shake
                              ShakeWidget(
                                shakeTrigger: _shakeTrigger,
                                child: _buildMazeBoard(context, round),
                              ),
                              AppSpacing.gapH16,

                              // Controls (D-pad & action buttons)
                              _buildControls(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Focus Countdown Overlay
              if (_showCountdown)
                Positioned.fill(
                  child: GameCountdownOverlay(
                    onComplete: () {
                      setState(() => _showCountdown = false);
                      _session.start();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMazeBoard(
    BuildContext context,
    LogicLabyrinthRoundState round,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.rLg,
        border: Border.all(
          color: AppColors.mint500.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint500.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellW = constraints.maxWidth / round.gridSize;
            final cellH = constraints.maxHeight / round.gridSize;

            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _MazePainter(
                round: round,
                isDark: isDark,
                cellWidth: cellW,
                cellHeight: cellH,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [
            // Up Button
            _buildDirectionButton(
              icon: Icons.keyboard_arrow_up_rounded,
              direction: LabyrinthDirection.up,
              tooltip: 'Move Up (W or Arrow Up)',
            ),
            AppSpacing.gapH4,
            // Left, Reset, Right Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDirectionButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  direction: LabyrinthDirection.left,
                  tooltip: 'Move Left (A or Arrow Left)',
                ),
                AppSpacing.gapW12,
                IconButton.filledTonal(
                  icon: const Icon(Icons.restart_alt_rounded),
                  tooltip: 'Reset to maze start (R)',
                  onPressed: _handleReset,
                ),
                AppSpacing.gapW12,
                _buildDirectionButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  direction: LabyrinthDirection.right,
                  tooltip: 'Move Right (D or Arrow Right)',
                ),
              ],
            ),
            AppSpacing.gapH4,
            // Down Button
            _buildDirectionButton(
              icon: Icons.keyboard_arrow_down_rounded,
              direction: LabyrinthDirection.down,
              tooltip: 'Move Down (S or Arrow Down)',
            ),
          ],
        ),
      );

  Widget _buildDirectionButton({
    required IconData icon,
    required LabyrinthDirection direction,
    required String tooltip,
  }) =>
      IconButton.filled(
        icon: Icon(icon, size: 28),
        tooltip: tooltip,
        onPressed: () => _handleDirection(direction),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.mint500,
          foregroundColor: AppColors.navy900,
          minimumSize: const Size(52, 52),
        ),
      );
}

class _MazePainter extends CustomPainter {
  const _MazePainter({
    required this.round,
    required this.isDark,
    required this.cellWidth,
    required this.cellHeight,
  });

  final LogicLabyrinthRoundState round;
  final bool isDark;
  final double cellWidth;
  final double cellHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = isDark ? const Color(0xFF243048) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final pathPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    // Draw grid cells
    for (var r = 0; r < round.gridSize; r++) {
      for (var c = 0; c < round.gridSize; c++) {
        final rect = Rect.fromLTWH(
          c * cellWidth,
          r * cellHeight,
          cellWidth,
          cellHeight,
        );
        final isWall = round.walls.contains(GridCoordinate(c, r));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(1),
            const Radius.circular(3),
          ),
          isWall ? wallPaint : pathPaint,
        );
      }
    }

    // Draw exit target
    final exitRect = Rect.fromLTWH(
      round.target.x * cellWidth,
      round.target.y * cellHeight,
      cellWidth,
      cellHeight,
    );
    final exitPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(exitRect.center, cellWidth * 0.38, exitPaint);

    // Draw checkpoint if present and not collected
    if (round.checkpoint != null && !round.checkpointCollected) {
      final cpRect = Rect.fromLTWH(
        round.checkpoint!.x * cellWidth,
        round.checkpoint!.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      final cpPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(cpRect.center, cellWidth * 0.28, cpPaint);
    }

    // Draw player with glowing orb
    final playerRect = Rect.fromLTWH(
      round.playerPos.x * cellWidth,
      round.playerPos.y * cellHeight,
      cellWidth,
      cellHeight,
    );
    final glowPaint = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(playerRect.center, cellWidth * 0.42, glowPaint);

    final playerPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(playerRect.center, cellWidth * 0.3, playerPaint);
  }

  @override
  bool shouldRepaint(_MazePainter oldDelegate) =>
      oldDelegate.round != round || oldDelegate.isDark != isDark;
}
