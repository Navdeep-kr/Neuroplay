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
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

/// Playable screen for the Focus Reactor selective attention exercise.
class FocusReactorScreen extends ConsumerStatefulWidget {
  const FocusReactorScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  ConsumerState<FocusReactorScreen> createState() => _FocusReactorScreenState();
}

class _FocusReactorScreenState extends ConsumerState<FocusReactorScreen> {
  final FocusReactorDefinition _definition = FocusReactorDefinition();
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
      id: 'fr-${DateTime.now().millisecondsSinceEpoch}',
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
        icon: Icons.center_focus_strong_rounded,
        instructions:
            'A target item will be designated at the top of the screen.\n\n'
            'Scan the item array below:\n'
            '• If the target is present, tap its slot (or press keys 1–4).\n'
            '• If the target is ABSENT, tap "No Target Present" (or press Space).\n\n'
            'Avoid impulse taps: distractors share shapes or markers to test your vigilance!',
        tips: const [
          'Correctly identifying absence earns extra precision points.',
          'Items feature distinct geometric shapes and symbols for non-color clarity.',
          'Keyboard keys [1], [2], [3], [4] and [Space] provide the fastest input.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          _session.start();
        },
      ),
    );
  }

  void _handleSlotSelected(int slotIndex) {
    if (_session.isFinished) return;
    _session.dispatch(
      SelectFocusSlotAction(
        timestamp: _session.activeDuration,
        slotIndex: slotIndex,
      ),
    );
    setState(() {});
  }

  void _handleNoTargetSelected() {
    if (_session.isFinished) return;
    _session.dispatch(
      SelectNoTargetAction(timestamp: _session.activeDuration),
    );
    setState(() {});
  }

  void _handlePause() {
    _session.pause(reason: 'user_pause_menu');
    setState(() {});

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
            isPractice: (_session.config as FocusReactorConfig).isPractice,
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
                isPractice: (_session.config as FocusReactorConfig).isPractice,
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

    final engine = _session.engine as FocusReactorGameEngine;
    final config = _session.config as FocusReactorConfig;
    final trial = engine.trialState;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _handleSlotSelected(0),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _handleSlotSelected(1),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _handleSlotSelected(2),
        const SingleActivator(LogicalKeyboardKey.digit4): () =>
            _handleSlotSelected(3),
        const SingleActivator(LogicalKeyboardKey.space):
            _handleNoTargetSelected,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Top Header HUD
                  GameHeader(
                    title: _definition.name,
                    currentRound: _session.state.currentRound,
                    totalRounds: _session.state.totalRounds,
                    score: _session.state.score,
                    isPractice: config.isPractice,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Target Specification Header
                  _buildTargetSpecHeader(theme, trial.targetItem),
                  AppSpacing.gapH24,

                  // Displayed Item Grid
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: trial.displayedItems.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                trial.displayedItems.length <= 4 ? 2 : 3,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) => _buildSlotCard(
                            theme,
                            index: index,
                            item: trial.displayedItems[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Bottom Action Button: No Target Present
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AppButton(
                      label: 'Target Absent [Space]',
                      icon: Icons.not_interested_rounded,
                      variant: AppButtonVariant.secondary,
                      isFullWidth: true,
                      onPressed: _handleNoTargetSelected,
                    ),
                  ),
                  AppSpacing.gapH12,
                  Text(
                    'Tap target slot [1-4] or declare absence [Space]',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.navy500,
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

  Widget _buildTargetSpecHeader(ThemeData theme, FocusItem target) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.mint500.withValues(alpha: 0.12),
          borderRadius: AppRadii.rFull,
          border: Border.all(
            color: AppColors.mint500.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FocusItemIcon(item: target, size: 28),
            AppSpacing.gapW12,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SEEK TARGET',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: AppColors.mint500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  target.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSlotCard(
    ThemeData theme, {
    required int index,
    required FocusItem item,
  }) =>
      Semantics(
        label: 'Slot ${index + 1}: ${item.label}',
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadii.rLg,
          child: InkWell(
            borderRadius: AppRadii.rLg,
            onTap: () => _handleSlotSelected(index),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: AppBadge(
                      label: '${index + 1}',
                    ),
                  ),
                  _FocusItemIcon(item: item, size: 48),
                  AppSpacing.gapH4,
                  Text(
                    item.shape.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Accessible visual rendering of focus items.
class _FocusItemIcon extends StatelessWidget {
  const _FocusItemIcon({required this.item, required this.size});

  final FocusItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (item.shape) {
      case FocusShape.star:
        icon = Icons.star_rounded;
        break;
      case FocusShape.hexagon:
        icon = Icons.hexagon_rounded;
        break;
      case FocusShape.cross:
        icon = Icons.add_box_rounded;
        break;
      case FocusShape.pentagon:
        icon = Icons.shield_rounded;
        break;
      case FocusShape.diamond:
        icon = Icons.diamond_rounded;
        break;
      case FocusShape.circle:
        icon = Icons.circle;
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          size: size,
          color: AppColors.navy800,
        ),
        if (item.marker != FocusMarker.plain)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.mint500,
                shape: BoxShape.circle,
              ),
              child: Text(
                item.marker.symbol,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
