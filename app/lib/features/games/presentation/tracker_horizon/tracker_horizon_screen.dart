import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/audio/sound_synthesizer.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_feedback_effects.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

class _MovingSphere {
  _MovingSphere({
    required this.id,
    required this.isTarget,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });

  final int id;
  final bool isTarget;
  double x;
  double y;
  double vx;
  double vy;
  bool isSelected = false;
}

enum _MotPhase { highlight, moving, select }

/// Tracker Horizon (Multiple Object Tracking).
class TrackerHorizonScreen extends ConsumerStatefulWidget {
  const TrackerHorizonScreen({super.key});

  @override
  ConsumerState<TrackerHorizonScreen> createState() =>
      _TrackerHorizonScreenState();
}

class _TrackerHorizonScreenState extends ConsumerState<TrackerHorizonScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalRounds = 5;
  static const Color _facultyColor = Color(0xFFD97706);

  final Random _rng = Random();
  final List<_MovingSphere> _spheres = [];

  late AnimationController _animController;
  Timer? _phaseTimer;

  int _round = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  _MotPhase _phase = _MotPhase.highlight;
  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    _startRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  @override
  void dispose() {
    _animController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    if (_round > _totalRounds) {
      _finishGame();
      return;
    }

    _animController.stop();
    _phaseTimer?.cancel();
    _spheres.clear();

    for (var i = 0; i < 8; i++) {
      final isTarget = i < 3;
      final angle = _rng.nextDouble() * 2 * pi;
      const speed = 0.004;

      _spheres.add(
        _MovingSphere(
          id: i,
          isTarget: isTarget,
          x: 0.15 + _rng.nextDouble() * 0.7,
          y: 0.15 + _rng.nextDouble() * 0.7,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
        ),
      );
    }

    setState(() => _phase = _MotPhase.highlight);
    SoundSynthesizer.playClick();

    _phaseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _phase = _MotPhase.moving);
      _animController.repeat();

      _phaseTimer = Timer(const Duration(milliseconds: 5000), () {
        if (!mounted) return;
        _animController.stop();
        setState(() => _phase = _MotPhase.select);
      });
    });
  }

  void _onTick() {
    if (_phase != _MotPhase.moving) return;

    setState(() {
      for (final s in _spheres) {
        s.x += s.vx;
        s.y += s.vy;

        if (s.x < 0.08 || s.x > 0.92) s.vx = -s.vx;
        if (s.y < 0.08 || s.y > 0.92) s.vy = -s.vy;
      }
    });
  }

  void _onSphereTap(_MovingSphere sphere) {
    if (_phase != _MotPhase.select || sphere.isSelected) return;

    setState(() => sphere.isSelected = true);

    if (sphere.isTarget) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      setState(() {
        _correctHits++;
        _score += 120 + (_comboStreak * 20);
      });
    } else {
      _comboStreak = 0;
      SoundSynthesizer.playError();
      setState(() {
        _shakeTrigger++;
        _score = max(0, _score - 40);
      });
    }

    final selectedCount = _spheres.where((s) => s.isSelected).length;
    final targetsFound =
        _spheres.where((s) => s.isSelected && s.isTarget).length;

    if (targetsFound == 3 || selectedCount >= 4) {
      if (targetsFound == 3) SoundSynthesizer.playFanfare();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _round++);
        _startRound();
      });
    }
  }

  void _finishGame() {
    _animController.stop();
    _phaseTimer?.cancel();
    const totalTargets = _totalRounds * 3;
    final accuracy = (_correctHits / totalTargets).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'mot-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'tracker-horizon',
      gameVersion: '1.0.0',
      engineVersion: '1.0.0',
      scoringRulesVersion: '1.0.0',
      seed: 42,
      difficulty: GameDifficulty.hard,
      completionPhase: GamePhase.completed,
      finalScore: _score,
      scoreBreakdown: ScoreBreakdown(
        rawScore: _score,
        finalScore: _score,
        speedBonus: 100,
        streakBonus: _comboStreak * 15,
      ),
      totalActiveDuration: const Duration(seconds: 40),
      totalActions: totalTargets,
      metrics: {
        'accuracy': accuracy,
        'correctHits': _correctHits,
      },
      completedAt: DateTime.now().toUtc(),
    );

    setState(() => _finalResult = result);
    _recordResult(result);
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
        title: 'Tracker Horizon',
        category: 'Attention',
        icon: Icons.track_changes_rounded,
        instructions:
            'Watch the 3 highlighted amber target spheres before they begin moving.\n\n'
            'Track all 3 targets simultaneously as they bounce across the arena.\n'
            'When all spheres halt, tap the 3 original target spheres.',
        tips: const [
          'Diffuse your focal point to take in the full arena as a unified constellation.',
          'Do not fixate on one sphere; expand your peripheral attention.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _round = 1;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _startRound();
        },
      ),
    );
  }

  void _handlePause() {
    _animController.stop();
    _phaseTimer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _startRound();
        },
        onRestart: () {
          Navigator.of(context).pop();
          setState(() {
            _round = 1;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _startRound();
        },
        onQuit: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.games);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_finalResult != null) {
      return Scaffold(
        body: SafeArea(
          child: GameCompletionView(
            result: _finalResult!,
            gameTitle: 'Tracker Horizon',
            onPlayAgain: () {
              setState(() {
                _round = 1;
                _score = 0;
                _comboStreak = 0;
                _correctHits = 0;
              });
              _startRound();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    String phaseText;
    Color phaseBg;
    Color phaseFg;

    switch (_phase) {
      case _MotPhase.highlight:
        phaseText = 'MEMORIZE 3 AMBER TARGETS';
        phaseBg = const Color(0xFFFEF3C7);
        phaseFg = const Color(0xFF92400E);
      case _MotPhase.moving:
        phaseText = 'TRACK TARGET MOVEMENTS...';
        phaseBg = const Color(0xFFEFF6FF);
        phaseFg = const Color(0xFF1E40AF);
      case _MotPhase.select:
        phaseText = 'TAP THE 3 ORIGINAL TARGETS';
        phaseBg = const Color(0xFFECFDF5);
        phaseFg = const Color(0xFF065F46);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  GameHeader(
                    title: 'Tracker Horizon',
                    facultyColor: _facultyColor,
                    currentRound: min(_round, _totalRounds),
                    totalRounds: _totalRounds,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Phase Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: phaseBg,
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: phaseFg.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      phaseText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: phaseFg,
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Tracking Physics Canvas
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 440,
                            maxHeight: 440,
                          ),
                          child: ShakeWidget(
                            shakeTrigger: _shakeTrigger,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: AppRadii.rXxl,
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadii.rXxl,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = constraints.maxWidth;
                                    final h = constraints.maxHeight;

                                    return Stack(
                                      children: _spheres.map((s) {
                                        final isHighlighted =
                                            _phase == _MotPhase.highlight &&
                                                s.isTarget;
                                        final isSelected = s.isSelected;

                                        Color sphereColor;
                                        if (isHighlighted) {
                                          sphereColor = _facultyColor;
                                        } else if (isSelected) {
                                          sphereColor = s.isTarget
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444);
                                        } else {
                                          sphereColor = const Color(0xFF94A3B8);
                                        }

                                        return Positioned(
                                          left: (s.x * w) - 20,
                                          top: (s.y * h) - 20,
                                          child: GestureDetector(
                                            onTap: () => _onSphereTap(s),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: sphereColor,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: isHighlighted ||
                                                          isSelected
                                                      ? 3
                                                      : 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: sphereColor
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: isHighlighted
                                                  ? const Center(
                                                      child: Icon(
                                                        Icons.star_rounded,
                                                        color: Colors.white,
                                                        size: 22,
                                                      ),
                                                    )
                                                  : isSelected
                                                      ? Center(
                                                          child: Icon(
                                                            s.isTarget
                                                                ? Icons
                                                                    .check_rounded
                                                                : Icons
                                                                    .close_rounded,
                                                            color: Colors.white,
                                                            size: 22,
                                                          ),
                                                        )
                                                      : null,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
