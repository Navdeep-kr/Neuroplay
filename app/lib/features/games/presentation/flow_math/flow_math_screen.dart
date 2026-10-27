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

class _FlowProblem {
  const _FlowProblem({
    required this.a,
    required this.b,
    required this.result,
    required this.correctOp,
  });

  final int a;
  final int b;
  final int result;
  final String correctOp;
}

/// Flow Math (Mental Arithmetic Constraint Satisfaction).
class FlowMathScreen extends ConsumerStatefulWidget {
  const FlowMathScreen({super.key});

  @override
  ConsumerState<FlowMathScreen> createState() => _FlowMathScreenState();
}

class _FlowMathScreenState extends ConsumerState<FlowMathScreen> {
  static const int _totalTrials = 15;
  static const Color _facultyColor = Color(0xFFC026D3);

  final Random _rng = Random();

  int _trialIndex = 0;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  _FlowProblem? _currentProblem;
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

    final opType = _rng.nextInt(4);
    int a;
    int b;
    int res;
    String op;

    switch (opType) {
      case 0:
        a = 10 + _rng.nextInt(40);
        b = 10 + _rng.nextInt(40);
        res = a + b;
        op = '+';
      case 1:
        a = 30 + _rng.nextInt(50);
        b = 10 + _rng.nextInt(25);
        res = a - b;
        op = '-';
      case 2:
        a = 3 + _rng.nextInt(10);
        b = 3 + _rng.nextInt(9);
        res = a * b;
        op = '×';
      default:
        b = 2 + _rng.nextInt(9);
        final factor = 3 + _rng.nextInt(10);
        a = b * factor;
        res = factor;
        op = '÷';
    }

    setState(() {
      _trialIndex++;
      _currentProblem = _FlowProblem(
        a: a,
        b: b,
        result: res,
        correctOp: op,
      );
    });
  }

  void _onAnswer(String chosenOp) {
    if (_currentProblem == null) return;

    if (chosenOp == _currentProblem!.correctOp) {
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
        _score = max(0, _score - 30);
      });
    }

    _nextProblem();
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalTrials).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'flow-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'flow-math',
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
      totalActiveDuration: const Duration(seconds: 30),
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
        title: 'Flow Math',
        category: 'Calculation',
        icon: Icons.calculate_rounded,
        instructions:
            'An incomplete arithmetic equation will appear on screen.\n\n'
            'Deduce which operator (+, -, ×, ÷) makes the equation true.\n'
            'Tap the matching operator button swiftly before time runs out.',
        tips: const [
          'Look at the magnitude difference between left and right sides.',
          'Large increases suggest multiplication; decreases suggest division or subtraction.',
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
            gameTitle: 'Flow Math',
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

    final p = _currentProblem;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.equal): () => _onAnswer('+'),
        const SingleActivator(LogicalKeyboardKey.minus): () => _onAnswer('-'),
        const SingleActivator(LogicalKeyboardKey.keyX): () => _onAnswer('×'),
        const SingleActivator(LogicalKeyboardKey.slash): () => _onAnswer('÷'),
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
                    title: 'Flow Math',
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
                          Icons.calculate_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'WHICH OPERATOR COMPLETES THE EQUATION?',
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

                  // Central Equation Card
                  Expanded(
                    child: Center(
                      child: ShakeWidget(
                        shakeTrigger: _shakeTrigger,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            maxWidth: 440,
                            maxHeight: 220,
                          ),
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
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${p?.a ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                AppSpacing.gapW16,
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF4FF),
                                    borderRadius: AppRadii.rLg,
                                    border: Border.all(
                                      color: _facultyColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: _facultyColor,
                                      ),
                                    ),
                                  ),
                                ),
                                AppSpacing.gapW16,
                                Text(
                                  '${p?.b ?? ''} = ${p?.result ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // 4 Operator Response Buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Row(
                      children: [
                        _buildOpBtn('+', '+'),
                        AppSpacing.gapW12,
                        _buildOpBtn('-', '-'),
                        AppSpacing.gapW12,
                        _buildOpBtn('×', '×'),
                        AppSpacing.gapW12,
                        _buildOpBtn('÷', '÷'),
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

  Widget _buildOpBtn(String symbol, String label) => Expanded(
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () => _onAnswer(symbol),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _facultyColor,
              elevation: 0,
              side: const BorderSide(color: _facultyColor, width: 2),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.rXl,
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _facultyColor,
              ),
            ),
          ),
        ),
      );
}
