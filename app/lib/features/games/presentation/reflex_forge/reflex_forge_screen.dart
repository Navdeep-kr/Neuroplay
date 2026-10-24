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

/// Colorful, high-octane playable screen for Reflex Forge task-switching.
class ReflexForgeScreen extends ConsumerStatefulWidget {
  const ReflexForgeScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  ConsumerState<ReflexForgeScreen> createState() => _ReflexForgeScreenState();
}

class _ReflexForgeScreenState extends ConsumerState<ReflexForgeScreen> {
  final ReflexForgeDefinition _definition = ReflexForgeDefinition();
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
      id: 'rf-${DateTime.now().millisecondsSinceEpoch}',
      definition: _definition,
      config: config,
    );

    // Immediately start session so engine state is fully initialized
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
        icon: Icons.flash_on_rounded,
        instructions:
            'A target symbol is presented alongside an active sorting rule: '
            '"MATCH SHAPE" or "MATCH PATTERN".\n\n'
            'Select the matching option as quickly and accurately as possible.',
        tips: const [
          'Watch the ACTIVE RULE header closely — rules can shift dynamically!',
          'Use keyboard numbers 1, 2, 3 or tap directly on the screen.',
          'Consistently fast accurate answers trigger rapid combo streak multipliers.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          setState(() => _showCountdown = true);
        },
      ),
    );
  }

  void _handleOptionSelected(int index) {
    if (_session.isFinished) return;

    final engine = _session.engine as ReflexForgeGameEngine;
    final trial = engine.trialState;

    if (index >= 0 && index < trial.options.length) {
      final isMatch = index == trial.correctIndex;

      if (isMatch) {
        _comboStreak++;
        SoundSynthesizer.playSuccess(streak: _comboStreak);
      } else {
        _comboStreak = 0;
        _shakeTrigger++;
        SoundSynthesizer.playError();
      }
    }

    _session.dispatch(
      SelectReflexOptionAction(
        timestamp: _session.activeDuration,
        selectedIndex: index,
      ),
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
            isPractice: (_session.config as ReflexForgeConfig).isPractice,
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
                isPractice: (_session.config as ReflexForgeConfig).isPractice,
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

    final engine = _session.engine as ReflexForgeGameEngine;
    final config = _session.config as ReflexForgeConfig;
    final trial = engine.trialState;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _handleOptionSelected(0),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _handleOptionSelected(1),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _handleOptionSelected(2),
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
                      AppSpacing.gapH12,

                      // Active Rule Banner with electric lighting
                      _buildRuleHeader(theme, trial),
                      AppSpacing.gapH12,

                      // Target Stimulus Card with error shake
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: ShakeWidget(
                              shakeTrigger: _shakeTrigger,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStimulusCard(
                                    theme,
                                    trial.stimulus,
                                  ),
                                  AppSpacing.gapH12,
                                  Text(
                                    'Select the matching symbol based on the active rule:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  AppSpacing.gapH12,
                                  Row(
                                    children: [
                                      for (var i = 0;
                                          i < trial.options.length;
                                          i++) ...[
                                        if (i > 0) AppSpacing.gapW12,
                                        Expanded(
                                          child: _buildOptionButton(
                                            theme,
                                            index: i,
                                            symbol: trial.options[i],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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

  Widget _buildRuleHeader(ThemeData theme, ReflexForgeTrialState trial) {
    final isShapeRule = trial.rule == ReflexRule.matchShape;

    return Column(
      children: [
        if (trial.ruleShiftedThisRound)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: AppRadii.rFull,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '⚡ RULE SHIFTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isShapeRule
                  ? [const Color(0xFF10B981), const Color(0xFF047857)]
                  : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
            ),
            borderRadius: AppRadii.rFull,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isShapeRule
                        ? const Color(0xFF10B981)
                        : const Color(0xFF8B5CF6))
                    .withValues(alpha: 0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isShapeRule ? Icons.category_rounded : Icons.texture_rounded,
                size: 22,
                color: Colors.white,
              ),
              AppSpacing.gapW8,
              Text(
                'ACTIVE RULE: ${trial.rule.title.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStimulusCard(ThemeData theme, ReflexSymbol symbol) => AppCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                borderRadius: AppRadii.rFull,
                border: Border.all(color: const Color(0xFF06B6D4)),
              ),
              child: const Text(
                'TARGET',
                style: TextStyle(
                  color: Color(0xFF00F5FF),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            AppSpacing.gapH16,
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: _SymbolGraphic(symbol: symbol, size: 80),
              ),
            ),
            AppSpacing.gapH12,
            Text(
              symbol.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildOptionButton(
    ThemeData theme, {
    required int index,
    required ReflexSymbol symbol,
  }) =>
      Semantics(
        label: 'Option ${index + 1}: ${symbol.label}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadii.rXl,
            child: InkWell(
              borderRadius: AppRadii.rXl,
              onTap: () => _handleOptionSelected(index),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
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
                    ),
                    AppSpacing.gapH8,
                    _SymbolGraphic(symbol: symbol, size: 54),
                    AppSpacing.gapH8,
                    Text(
                      symbol.shape.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      symbol.pattern.label,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Accessible visual rendering of geometric shapes with pattern indicators.
class _SymbolGraphic extends StatelessWidget {
  const _SymbolGraphic({required this.symbol, required this.size});

  final ReflexSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _getSymbolColor(symbol.pattern);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SymbolPainter(
          shape: symbol.shape,
          pattern: symbol.pattern,
          color: color,
        ),
      ),
    );
  }

  Color _getSymbolColor(ReflexPattern pattern) => switch (pattern) {
        ReflexPattern.solid => const Color(0xFF10B981),
        ReflexPattern.striped => const Color(0xFF38BDF8),
        ReflexPattern.dotted => const Color(0xFFF59E0B),
        ReflexPattern.outline => const Color(0xFFA855F7),
      };
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter({
    required this.shape,
    required this.pattern,
    required this.color,
  });

  final ReflexShape shape;
  final ReflexPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    switch (shape) {
      case ReflexShape.circle:
        _drawCircle(canvas, center, radius, paint, strokePaint);
      case ReflexShape.square:
        _drawSquare(canvas, center, radius, paint, strokePaint);
      case ReflexShape.triangle:
        _drawTriangle(canvas, center, radius, paint, strokePaint);
      case ReflexShape.diamond:
        _drawDiamond(canvas, center, radius, paint, strokePaint);
    }
  }

  void _drawCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    if (pattern == ReflexPattern.solid) {
      canvas.drawCircle(center, radius, fill);
    } else {
      canvas.drawCircle(center, radius, stroke);
      _drawPattern(canvas, Rect.fromCircle(center: center, radius: radius));
    }
  }

  void _drawSquare(
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
    if (pattern == ReflexPattern.solid) {
      canvas.drawRRect(rrect, fill);
    } else {
      canvas.drawRRect(rrect, stroke);
      _drawPattern(canvas, rect);
    }
  }

  void _drawTriangle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy + radius)
      ..close();

    if (pattern == ReflexPattern.solid) {
      canvas.drawPath(path, fill);
    } else {
      canvas.drawPath(path, stroke);
      _drawPattern(
        canvas,
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2,
        ),
      );
    }
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

    if (pattern == ReflexPattern.solid) {
      canvas.drawPath(path, fill);
    } else {
      canvas.drawPath(path, stroke);
      _drawPattern(
        canvas,
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2,
        ),
      );
    }
  }

  void _drawPattern(Canvas canvas, Rect bounds) {
    final patternPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2;

    if (pattern == ReflexPattern.striped) {
      for (var x = bounds.left + 6; x < bounds.right; x += 10) {
        canvas.drawLine(
          Offset(x, bounds.top + 6),
          Offset(x, bounds.bottom - 6),
          patternPaint,
        );
      }
    } else if (pattern == ReflexPattern.dotted) {
      for (var x = bounds.left + 8; x < bounds.right; x += 12) {
        for (var y = bounds.top + 8; y < bounds.bottom; y += 12) {
          canvas.drawCircle(Offset(x, y), 2, patternPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SymbolPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.pattern != pattern ||
      oldDelegate.color != color;
}
