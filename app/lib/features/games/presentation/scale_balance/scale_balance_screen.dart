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

enum _ScaleChoice { left, equal, right }

class _ScaleProblem {
  const _ScaleProblem({
    required this.leftText,
    required this.leftVal,
    required this.rightText,
    required this.rightVal,
  });

  final String leftText;
  final int leftVal;
  final String rightText;
  final int rightVal;

  _ScaleChoice get correctChoice {
    if (leftVal > rightVal) return _ScaleChoice.left;
    if (rightVal > leftVal) return _ScaleChoice.right;
    return _ScaleChoice.equal;
  }
}

/// Scale Balance (Rapid Arithmetic Magnitude Comparison).
class ScaleBalanceScreen extends ConsumerStatefulWidget {
  const ScaleBalanceScreen({super.key});

  @override
  ConsumerState<ScaleBalanceScreen> createState() => _ScaleBalanceScreenState();
}

class _ScaleBalanceScreenState extends ConsumerState<ScaleBalanceScreen> {
  static const int _totalTrials = 15;
  static const Color _facultyColor = Color(0xFFC026D3);

  final Random _rng = Random();

  int _trialIndex = 0;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  _ScaleProblem? _currentProblem;
  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _nextProblem();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  void _nextProblem() {
    if (_trialIndex >= _totalTrials) {
      _finishGame();
      return;
    }

    final isEqual = _rng.nextDouble() < 0.3;
    int a;
    int b;
    int c;
    int d;
    String lText;
    String rText;
    int lVal;
    int rVal;

    if (isEqual) {
      final base = 20 + _rng.nextInt(60);
      a = 5 + _rng.nextInt(base - 10);
      b = base - a;
      c = 2 + _rng.nextInt(base - 5);
      d = base - c;
      lText = '$a + $b';
      rText = '$c + $d';
      lVal = base;
      rVal = base;
    } else {
      final opType = _rng.nextInt(3);
      if (opType == 0) {
        final m1 = 4 + _rng.nextInt(6);
        final m2 = 5 + _rng.nextInt(8);
        lVal = m1 * m2;
        lText = '$m1 × $m2';

        final diff = (_rng.nextBool() ? 1 : -1) * (1 + _rng.nextInt(8));
        rVal = lVal + diff;
        final r1 = 10 + _rng.nextInt(max(1, rVal - 10));
        final r2 = rVal - r1;
        rText = '$r1 + $r2';
      } else {
        final v1 = 15 + _rng.nextInt(40);
        final v2 = 10 + _rng.nextInt(40);
        lVal = v1 + v2;
        lText = '$v1 + $v2';

        final diff = (_rng.nextBool() ? 1 : -1) * (2 + _rng.nextInt(12));
        rVal = lVal + diff;
        final v3 = 10 + _rng.nextInt(max(1, rVal - 10));
        final v4 = rVal - v3;
        rText = '$v3 + $v4';
      }
    }

    setState(() {
      _trialIndex++;
      _currentProblem = _ScaleProblem(
        leftText: lText,
        leftVal: lVal,
        rightText: rText,
        rightVal: rVal,
      );
    });
  }

  void _onAnswer(_ScaleChoice choice) {
    if (_currentProblem == null) return;

    if (choice == _currentProblem!.correctChoice) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      setState(() {
        _correctHits++;
        _score += 100 + (_comboStreak * 20);
      });
    } else {
      _comboStreak = 0;
      SoundSynthesizer.playError();
      setState(() {
        _shakeTrigger++;
        _score = max(0, _score - 35);
      });
    }

    _nextProblem();
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalTrials).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'scale-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'scale-balance',
      gameVersion: '1.0.0',
      engineVersion: '1.0.0',
      scoringRulesVersion: '1.0.0',
      seed: 42,
      difficulty: GameDifficulty.medium,
      completionPhase: GamePhase.completed,
      finalScore: _score,
      scoreBreakdown: ScoreBreakdown(
        rawScore: _score,
        finalScore: _score,
        speedBonus: 100,
        streakBonus: _comboStreak * 15,
      ),
      totalActiveDuration: const Duration(seconds: 35),
      totalActions: _totalTrials,
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
        title: 'Scale Balance',
        category: 'Calculation',
        icon: Icons.balance_rounded,
        instructions:
            'Evaluate the math expressions displayed on the left and right pans.\n\n'
            'Tap [LEFT] if the left side is heavier / greater.\n'
            'Tap [RIGHT] if the right side is heavier / greater.\n'
            'Tap [EQUAL] if both expressions calculate to the exact same value.',
        tips: const [
          'Estimate orders of magnitude before doing full exact computation.',
          'Notice when expressions simplify quickly.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _trialIndex = 0;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _nextProblem();
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
            _trialIndex = 0;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _nextProblem();
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
            gameTitle: 'Scale Balance',
            onPlayAgain: () {
              setState(() {
                _trialIndex = 0;
                _score = 0;
                _comboStreak = 0;
                _correctHits = 0;
              });
              _nextProblem();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _onAnswer(_ScaleChoice.left),
        const SingleActivator(LogicalKeyboardKey.space): () =>
            _onAnswer(_ScaleChoice.equal),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _onAnswer(_ScaleChoice.right),
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
                    title: 'Scale Balance',
                    facultyColor: _facultyColor,
                    currentRound: min(_trialIndex, _totalTrials),
                    totalRounds: _totalTrials,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH24,

                  // Instruction Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF4FF),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFFF0ABFC)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.scale_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'WHICH PAN HAS GREATER VALUE?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF86198F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH32,

                  // Interactive Scale Visual & Pans
                  Expanded(
                    child: Center(
                      child: ShakeWidget(
                        shakeTrigger: _shakeTrigger,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Row(
                            children: [
                              // Left Pan
                              Expanded(
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: AppRadii.rXxl,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.08),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currentProblem?.leftText ?? '',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.gapW16,

                              // Fulcrum Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDF4FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.balance_rounded,
                                    color: _facultyColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              AppSpacing.gapW16,

                              // Right Pan
                              Expanded(
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: AppRadii.rXxl,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.08),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currentProblem?.rightText ?? '',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // 3 Decision Buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _onAnswer(_ScaleChoice.left),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
                                ),
                              ),
                              child: const Text(
                                'LEFT [◀]',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _onAnswer(_ScaleChoice.equal),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _facultyColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
                                ),
                              ),
                              child: const Text(
                                'EQUAL [=]',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _onAnswer(_ScaleChoice.right),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
                                ),
                              ),
                              child: const Text(
                                'RIGHT [▶]',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
