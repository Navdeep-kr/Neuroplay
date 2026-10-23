import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
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
          _session.start();
        },
      ),
    );
  }

  void _handleDirection(LabyrinthDirection direction) {
    if (_session.isFinished) return;
    _session.dispatch(
      MoveLabyrinthAction(
        timestamp: _session.activeDuration,
        direction: direction,
      ),
    );
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
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Round info badges
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
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

                          // The Labyrinth Grid
                          _buildMazeGrid(round, isDark),

                          AppSpacing.gapH16,

                          // Directional Controls (D-Pad)
                          _buildDPadControls(isDark),
                        ],
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

  Widget _buildMazeGrid(LogicLabyrinthRoundState round, bool isDark) {
    final size = round.gridSize;

    return Semantics(
      label:
          'Labyrinth Grid size $size by $size. Player at (${round.playerPos.x}, ${round.playerPos.y})',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 380),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
          borderRadius: AppRadii.rLg,
          border: Border.all(
            color: isDark ? AppColors.navy700 : AppColors.slate200,
            width: 2,
          ),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: size * size,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final x = index % size;
              final y = index ~/ size;
              final coord = GridCoordinate(x, y);

              final isPlayer = coord == round.playerPos;
              final isStart = coord == round.start;
              final isTarget = coord == round.target;
              final isWall = round.walls.contains(coord);
              final isCheckpoint = coord == round.checkpoint;
              final isVisited = round.visitedPath.contains(coord);

              Color cellColor;
              Widget? iconWidget;

              if (isWall) {
                cellColor = isDark ? AppColors.navy800 : AppColors.navy700;
                iconWidget = Icon(
                  Icons.block_rounded,
                  size: 14,
                  color: isDark ? AppColors.navy600 : AppColors.navy500,
                );
              } else if (isPlayer) {
                cellColor = AppColors.mint500.withValues(alpha: 0.25);
                iconWidget = Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mint500,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.navigation_rounded,
                    size: 16,
                    color: AppColors.navy900,
                  ),
                );
              } else if (isTarget) {
                cellColor = isDark ? AppColors.navy800 : AppColors.slate100;
                iconWidget = Icon(
                  Icons.sports_score_rounded,
                  size: 20,
                  color: round.needsCheckpoint
                      ? AppColors.navy400
                      : AppColors.mint500,
                );
              } else if (isCheckpoint) {
                cellColor = isDark ? AppColors.navy800 : AppColors.slate100;
                iconWidget = Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: round.checkpointCollected
                      ? AppColors.navy400
                      : const Color(0xFFF59E0B),
                );
              } else if (isStart) {
                cellColor = isDark ? AppColors.navy800 : AppColors.slate100;
                iconWidget = const Icon(
                  Icons.flag_rounded,
                  size: 16,
                  color: AppColors.mint500,
                );
              } else if (isVisited) {
                cellColor = isDark
                    ? AppColors.navy800.withValues(alpha: 0.6)
                    : AppColors.mint50.withValues(alpha: 0.5);
                iconWidget = Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.navy600 : AppColors.mint200,
                  ),
                );
              } else {
                cellColor = isDark ? AppColors.navy800 : AppColors.slate100;
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: iconWidget,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDPadControls(bool isDark) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
            tooltip: 'Move Up (W or Arrow Up)',
            onPressed: () => _handleDirection(LabyrinthDirection.up),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 28),
                tooltip: 'Move Left (A or Arrow Left)',
                onPressed: () => _handleDirection(LabyrinthDirection.left),
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton.outlined(
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                tooltip: 'Reset to maze start (R)',
                onPressed: _handleReset,
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton.filledTonal(
                icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 28),
                tooltip: 'Move Right (D or Arrow Right)',
                onPressed: () => _handleDirection(LabyrinthDirection.right),
              ),
            ],
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            tooltip: 'Move Down (S or Arrow Down)',
            onPressed: () => _handleDirection(LabyrinthDirection.down),
          ),
        ],
      );
}
