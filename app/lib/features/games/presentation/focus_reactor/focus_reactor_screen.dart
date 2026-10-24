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
          setState(() => _showCountdown = true);
        },
      ),
    );
  }

  void _handleSlotSelected(int slotIndex) {
    if (_session.isFinished) return;
    final engine = _session.engine as FocusReactorGameEngine;
    final trial = engine.trialState;

    final isCorrect =
        trial.isTargetPresent && trial.targetSlotIndex == slotIndex;
    if (isCorrect) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
    } else {
      _comboStreak = 0;
      _shakeTrigger++;
      SoundSynthesizer.playError();
    }

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
    final engine = _session.engine as FocusReactorGameEngine;
    final trial = engine.trialState;

    final isCorrect = !trial.isTargetPresent;
    if (isCorrect) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
    } else {
      _comboStreak = 0;
      _shakeTrigger++;
      SoundSynthesizer.playError();
    }

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
        const SingleActivator(LogicalKeyboardKey.space):
            _handleNoTargetSelected,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _handleSlotSelected(0),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _handleSlotSelected(1),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _handleSlotSelected(2),
        const SingleActivator(LogicalKeyboardKey.digit4): () =>
            _handleSlotSelected(3),
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
                      // Top Header HUD with live combo streak
                      GameHeader(
                        title: _definition.name,
                        currentRound: _session.state.currentRound,
                        totalRounds: _session.state.totalRounds,
                        score: _session.state.score,
                        comboStreak: _comboStreak,
                        isPractice: config.isPractice,
                        onPause: _handlePause,
                      ),
                      AppSpacing.gapH16,

                      // Target Specification Header with radar glow
                      _buildTargetSpecHeader(theme, trial.targetItem),
                      AppSpacing.gapH24,

                      // Displayed Item Grid with error shake
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: ShakeWidget(
                              shakeTrigger: _shakeTrigger,
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

  Widget _buildTargetSpecHeader(ThemeData theme, FocusItem target) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.mint500.withValues(alpha: 0.12),
          borderRadius: AppRadii.rFull,
          border: Border.all(
            color: AppColors.mint500.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.mint500.withValues(alpha: 0.2),
              blurRadius: 14,
            ),
          ],
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${target.shape.label} • ${target.marker.label}',
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
        label:
            'Slot ${index + 1}: ${item.shape.label} with ${item.marker.label}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadii.rLg,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Material(
            color: Colors.transparent,
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
                      child: AppBadge(label: '${index + 1}'),
                    ),
                    Expanded(
                      child: Center(
                        child: _FocusItemIcon(item: item, size: 44),
                      ),
                    ),
                    Text(
                      item.shape.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    Text(
                      item.marker.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.navy500,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Accessible visual rendering for focus target and distractor items.
class _FocusItemIcon extends StatelessWidget {
  const _FocusItemIcon({required this.item, required this.size});

  final FocusItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _getMarkerColor(item.marker);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FocusItemPainter(
          shape: item.shape,
          marker: item.marker,
          color: color,
        ),
      ),
    );
  }

  Color _getMarkerColor(FocusMarker marker) => switch (marker) {
        FocusMarker.dot => AppColors.mint500,
        FocusMarker.ring => const Color(0xFFF59E0B),
        FocusMarker.stripe => const Color(0xFF38BDF8),
        FocusMarker.plain => const Color(0xFF818CF8),
      };
}

class _FocusItemPainter extends CustomPainter {
  const _FocusItemPainter({
    required this.shape,
    required this.marker,
    required this.color,
  });

  final FocusShape shape;
  final FocusMarker marker;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    switch (shape) {
      case FocusShape.star:
        _drawStar(canvas, center, radius, basePaint, borderPaint);
      case FocusShape.hexagon:
        _drawHexagon(canvas, center, radius, basePaint, borderPaint);
      case FocusShape.cross:
        _drawCross(canvas, center, radius, basePaint, borderPaint);
      case FocusShape.pentagon:
        _drawPentagon(canvas, center, radius, basePaint, borderPaint);
      case FocusShape.diamond:
        _drawDiamond(canvas, center, radius, basePaint, borderPaint);
      case FocusShape.circle:
        _drawCircle(canvas, center, radius, basePaint, borderPaint);
    }

    _drawMarker(canvas, center, radius * 0.45);
  }

  void _drawCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    canvas
      ..drawCircle(center, radius, fill)
      ..drawCircle(center, radius, stroke);
  }

  void _drawDiamond(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);
  }

  void _drawHexagon(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 1.8,
      height: radius * 1.8,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas
      ..drawRRect(rrect, fill)
      ..drawRRect(rrect, stroke);
  }

  void _drawPentagon(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 1.8,
      height: radius * 1.8,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas
      ..drawRRect(rrect, fill)
      ..drawRRect(rrect, stroke);
  }

  void _drawCross(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final arm = radius * 0.4;
    final path = Path()
      ..moveTo(center.dx - arm, center.dy - radius)
      ..lineTo(center.dx + arm, center.dy - radius)
      ..lineTo(center.dx + arm, center.dy - arm)
      ..lineTo(center.dx + radius, center.dy - arm)
      ..lineTo(center.dx + radius, center.dy + arm)
      ..lineTo(center.dx + arm, center.dy + arm)
      ..lineTo(center.dx + arm, center.dy + radius)
      ..lineTo(center.dx - arm, center.dy + radius)
      ..lineTo(center.dx - arm, center.dy + arm)
      ..lineTo(center.dx - radius, center.dy + arm)
      ..lineTo(center.dx - radius, center.dy - arm)
      ..lineTo(center.dx - arm, center.dy - arm)
      ..close();
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.35)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.35, center.dy + radius * 0.35)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.35, center.dy + radius * 0.35)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.35, center.dy - radius * 0.35)
      ..close();
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);
  }

  void _drawMarker(Canvas canvas, Offset center, double markerRadius) {
    final markerPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    switch (marker) {
      case FocusMarker.dot:
        canvas.drawCircle(
          center,
          markerRadius * 0.7,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      case FocusMarker.ring:
        canvas.drawCircle(center, markerRadius, markerPaint);
      case FocusMarker.stripe:
        canvas
          ..drawLine(
            Offset(center.dx - markerRadius, center.dy - 3),
            Offset(center.dx + markerRadius, center.dy - 3),
            markerPaint,
          )
          ..drawLine(
            Offset(center.dx - markerRadius, center.dy + 3),
            Offset(center.dx + markerRadius, center.dy + 3),
            markerPaint,
          );
      case FocusMarker.plain:
        break;
    }
  }

  @override
  bool shouldRepaint(_FocusItemPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.marker != marker ||
      oldDelegate.color != color;
}
