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

class _OrigamiOption {
  const _OrigamiOption({required this.holes, required this.isCorrect});
  final List<Point<int>> holes;
  final bool isCorrect;
}

/// Origami Unfold (Mental Paper Folding & Spatial Rotation).
class OrigamiUnfoldScreen extends ConsumerStatefulWidget {
  const OrigamiUnfoldScreen({super.key});

  @override
  ConsumerState<OrigamiUnfoldScreen> createState() =>
      _OrigamiUnfoldScreenState();
}

class _OrigamiUnfoldScreenState extends ConsumerState<OrigamiUnfoldScreen> {
  static const int _totalRounds = 8;
  static const Color _facultyColor = Color(0xFF4F46E5);

  final Random _rng = Random();

  int _round = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;

  Point<int> _punchHole = const Point(1, 1);
  bool _foldIsVertical = true;
  List<_OrigamiOption> _options = [];
  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _nextRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  void _nextRound() {
    if (_round > _totalRounds) {
      _finishGame();
      return;
    }

    _foldIsVertical = _rng.nextBool();
    if (_foldIsVertical) {
      _punchHole = Point(_rng.nextInt(2), _rng.nextInt(4));
    } else {
      _punchHole = Point(_rng.nextInt(4), _rng.nextInt(2));
    }

    final correctHoles = <Point<int>>[_punchHole];
    if (_foldIsVertical) {
      correctHoles.add(Point(3 - _punchHole.x, _punchHole.y));
    } else {
      correctHoles.add(Point(_punchHole.x, 3 - _punchHole.y));
    }

    _options = [];
    _options.add(_OrigamiOption(holes: correctHoles, isCorrect: true));

    final dist1Holes = <Point<int>>[_punchHole];
    if (_foldIsVertical) {
      dist1Holes.add(Point(_punchHole.x, 3 - _punchHole.y));
    } else {
      dist1Holes.add(Point(3 - _punchHole.x, _punchHole.y));
    }
    _options.add(_OrigamiOption(holes: dist1Holes, isCorrect: false));
    _options.add(_OrigamiOption(holes: [_punchHole], isCorrect: false));

    final dist3Holes = <Point<int>>[
      _punchHole,
      Point(3 - _punchHole.x, 3 - _punchHole.y),
    ];
    _options.add(_OrigamiOption(holes: dist3Holes, isCorrect: false));

    _options.shuffle(_rng);

    setState(() {});
  }

  void _onSelectOption(_OrigamiOption option) {
    if (option.isCorrect) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      setState(() {
        _correctHits++;
        _score += 150 + (_comboStreak * 25);
        _round++;
      });
      _nextRound();
    } else {
      _comboStreak = 0;
      SoundSynthesizer.playError();
      setState(() {
        _shakeTrigger++;
        _score = max(0, _score - 40);
      });
    }
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalRounds).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'origami-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'origami-unfold',
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
        speedBonus: 120,
        streakBonus: _comboStreak * 20,
      ),
      totalActiveDuration: const Duration(seconds: 40),
      totalActions: _totalRounds,
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
        title: 'Origami Unfold',
        category: 'Problem Solving',
        icon: Icons.folder_zip_rounded,
        instructions:
            'A square sheet of paper is folded in half and punched through.\n\n'
            'Mentally unfold the sheet along the fold line.\n'
            'Select which of the 4 unfolded sheets displays the correct holes.',
        tips: const [
          'Holes reflect across the fold axis like a mirror image.',
          'Identify whether the reflection is horizontal or vertical.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _round = 1;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _nextRound();
        },
      ),
    );
  }

  void _handlePause() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () => Navigator.of(context).pop(),
        onRestart: () {
          Navigator.of(context).pop();
          setState(() {
            _round = 1;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _nextRound();
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
            gameTitle: 'Origami Unfold',
            onPlayAgain: () {
              setState(() {
                _round = 1;
                _score = 0;
                _comboStreak = 0;
                _correctHits = 0;
              });
              _nextRound();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
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
                    title: 'Origami Unfold',
                    facultyColor: _facultyColor,
                    currentRound: min(_round, _totalRounds),
                    totalRounds: _totalRounds,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Instruction Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_zip_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          _foldIsVertical
                              ? 'VERTICAL FOLD (LEFT OVER RIGHT)'
                              : 'HORIZONTAL FOLD (TOP OVER BOTTOM)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Folded Sheet Preview
                  ShakeWidget(
                    shakeTrigger: _shakeTrigger,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.rXl,
                        border: Border.all(
                          color: _facultyColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.08),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _FoldLinePainter(
                                isVertical: _foldIsVertical,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (_punchHole.x / 3) * 110 + 10,
                            top: (_punchHole.y / 3) * 110 + 10,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // 4 Candidate Sheets Grid
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: _options.length,
                        itemBuilder: (context, idx) {
                          final opt = _options[idx];

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onSelectOption(opt),
                              borderRadius: AppRadii.rXl,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppRadii.rXl,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A)
                                          .withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: opt.holes
                                      .map(
                                        (h) => Positioned(
                                          left: (h.x / 3) * 120 + 20,
                                          top: (h.y / 3) * 120 + 20,
                                          child: const DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFDC2626),
                                            ),
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  AppSpacing.gapH12,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoldLinePainter extends CustomPainter {
  const _FoldLinePainter({required this.isVertical, required this.color});
  final bool isVertical;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (isVertical) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FoldLinePainter oldDelegate) =>
      oldDelegate.isVertical != isVertical;
}
