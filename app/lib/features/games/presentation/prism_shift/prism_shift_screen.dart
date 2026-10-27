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

enum _PrismRule { matchInk, matchWord }

class _PrismTrial {
  const _PrismTrial({
    required this.wordText,
    required this.inkColor,
    required this.inkColorName,
    required this.rule,
  });

  final String wordText;
  final Color inkColor;
  final String inkColorName;
  final _PrismRule rule;

  String get correctColorName =>
      rule == _PrismRule.matchInk ? inkColorName : wordText;
}

/// Prism Shift (Stroop & Inhibitory Control).
class PrismShiftScreen extends ConsumerStatefulWidget {
  const PrismShiftScreen({super.key});

  @override
  ConsumerState<PrismShiftScreen> createState() => _PrismShiftScreenState();
}

class _PrismShiftScreenState extends ConsumerState<PrismShiftScreen> {
  static const int _totalTrials = 20;
  static const Color _facultyColor = Color(0xFF059669);

  final Random _rng = Random();

  final List<String> _colorNames = ['RED', 'BLUE', 'GREEN', 'AMBER'];
  final Map<String, Color> _colorPalette = {
    'RED': const Color(0xFFDC2626),
    'BLUE': const Color(0xFF2563EB),
    'GREEN': const Color(0xFF059669),
    'AMBER': const Color(0xFFD97706),
  };

  int _trialIndex = 0;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  _PrismTrial? _currentTrial;
  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _nextTrial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  void _nextTrial() {
    if (_trialIndex >= _totalTrials) {
      _finishGame();
      return;
    }

    final word = _colorNames[_rng.nextInt(_colorNames.length)];
    String ink;
    if (_rng.nextDouble() < 0.7) {
      final others = _colorNames.where((c) => c != word).toList();
      ink = others[_rng.nextInt(others.length)];
    } else {
      ink = word;
    }

    final rule = _rng.nextBool() ? _PrismRule.matchInk : _PrismRule.matchWord;

    setState(() {
      _trialIndex++;
      _currentTrial = _PrismTrial(
        wordText: word,
        inkColor: _colorPalette[ink]!,
        inkColorName: ink,
        rule: rule,
      );
    });
  }

  void _onChooseColor(String chosenColor) {
    if (_currentTrial == null) return;

    if (chosenColor == _currentTrial!.correctColorName) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      setState(() {
        _correctHits++;
        _score += 100 + (_comboStreak * 15);
      });
    } else {
      _comboStreak = 0;
      SoundSynthesizer.playError();
      setState(() {
        _shakeTrigger++;
        _score = max(0, _score - 35);
      });
    }

    _nextTrial();
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalTrials).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'prism-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'prism-shift',
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
        title: 'Prism Shift',
        category: 'Flexibility',
        icon: Icons.palette_rounded,
        instructions:
            'Pay strict attention to the top Rule Banner before answering.\n\n'
            'If [MATCH INK COLOR]: tap the font color, ignoring the word.\n'
            'If [MATCH WORD TEXT]: tap the word meaning, ignoring the font color.',
        tips: const [
          'The brain naturally wants to read the text; inhibit this impulse.',
          'Double check the active banner on every trial.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _trialIndex = 0;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
          });
          _nextTrial();
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
          _nextTrial();
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
            gameTitle: 'Prism Shift',
            onPlayAgain: () {
              setState(() {
                _trialIndex = 0;
                _score = 0;
                _comboStreak = 0;
                _correctHits = 0;
              });
              _nextTrial();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    final isInkRule = _currentTrial?.rule == _PrismRule.matchInk;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _onChooseColor('RED'),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _onChooseColor('BLUE'),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _onChooseColor('GREEN'),
        const SingleActivator(LogicalKeyboardKey.digit4): () =>
            _onChooseColor('AMBER'),
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
                    title: 'Prism Shift',
                    facultyColor: _facultyColor,
                    currentRound: min(_trialIndex, _totalTrials),
                    totalRounds: _totalTrials,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH24,

                  // Dynamic Rule Banner
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isInkRule
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFEF3C7),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(
                        color: isInkRule
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFFCD34D),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isInkRule
                              ? Icons.palette_rounded
                              : Icons.text_fields_rounded,
                          size: 20,
                          color: isInkRule
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706),
                        ),
                        AppSpacing.gapW8,
                        Text(
                          isInkRule
                              ? 'RULE: TAP INK COLOR'
                              : 'RULE: TAP WRITTEN WORD',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isInkRule
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH32,

                  // Stimulus Center Card
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
                            child: Text(
                              _currentTrial?.wordText ?? '',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: _currentTrial?.inkColor ??
                                    const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // 4 Color Response Buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildColorBtn(
                              'RED',
                              _colorPalette['RED']!,
                              '1',
                            ),
                            AppSpacing.gapW12,
                            _buildColorBtn(
                              'BLUE',
                              _colorPalette['BLUE']!,
                              '2',
                            ),
                          ],
                        ),
                        AppSpacing.gapH12,
                        Row(
                          children: [
                            _buildColorBtn(
                              'GREEN',
                              _colorPalette['GREEN']!,
                              '3',
                            ),
                            AppSpacing.gapW12,
                            _buildColorBtn(
                              'AMBER',
                              _colorPalette['AMBER']!,
                              '4',
                            ),
                          ],
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

  Widget _buildColorBtn(String name, Color color, String keyNum) => Expanded(
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () => _onChooseColor(name),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              elevation: 0,
              side: BorderSide(color: color, width: 2),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.rXl,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 12,
                    height: 12,
                  ),
                ),
                AppSpacing.gapW8,
                Text(
                  '$name [$keyNum]',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
