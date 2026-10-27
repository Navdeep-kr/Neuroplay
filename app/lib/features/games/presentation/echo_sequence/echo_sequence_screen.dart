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
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

class _EchoStimulus {
  const _EchoStimulus({required this.position, required this.letter});
  final int position;
  final String letter;
}

/// Echo Sequence (Dual N-Back Working Memory).
class EchoSequenceScreen extends ConsumerStatefulWidget {
  const EchoSequenceScreen({super.key, this.nBack = 2});
  final int nBack;

  @override
  ConsumerState<EchoSequenceScreen> createState() => _EchoSequenceScreenState();
}

class _EchoSequenceScreenState extends ConsumerState<EchoSequenceScreen> {
  static const int _totalRounds = 16;
  static const Color _facultyColor = Color(0xFF2563EB); // Cobalt Sapphire

  final Random _rng = Random(42);
  final List<String> _letters = ['A', 'B', 'C', 'H', 'K', 'L', 'O', 'T'];

  final List<_EchoStimulus> _history = [];
  Timer? _stimulusTimer;

  int _currentIndex = 0;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _totalDecisions = 0;
  bool _isFlashing = false;
  bool _positionMatchedThisTrial = false;
  bool _letterMatchedThisTrial = false;
  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _generateSequence();
    _advanceTrial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  @override
  void dispose() {
    _stimulusTimer?.cancel();
    super.dispose();
  }

  void _generateSequence() {
    _history.clear();
    for (var i = 0; i < _totalRounds; i++) {
      int pos;
      String letter;
      if (i >= widget.nBack && _rng.nextDouble() < 0.35) {
        pos = _history[i - widget.nBack].position;
      } else {
        pos = _rng.nextInt(9);
      }
      if (i >= widget.nBack && _rng.nextDouble() < 0.35) {
        letter = _history[i - widget.nBack].letter;
      } else {
        letter = _letters[_rng.nextInt(_letters.length)];
      }
      _history.add(_EchoStimulus(position: pos, letter: letter));
    }
  }

  void _startRhythm() {
    _currentIndex = 0;
    _score = 0;
    _comboStreak = 0;
    _correctHits = 0;
    _totalDecisions = 0;
    _finalResult = null;
    _advanceTrial();
  }

  void _advanceTrial() {
    if (_currentIndex >= _totalRounds) {
      _finishGame();
      return;
    }

    setState(() {
      _isFlashing = true;
      _positionMatchedThisTrial = false;
      _letterMatchedThisTrial = false;
    });

    SoundSynthesizer.playClick();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isFlashing = false);
    });

    _stimulusTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _currentIndex++;
      _advanceTrial();
    });
  }

  void _onPositionMatch() {
    if (_positionMatchedThisTrial || _currentIndex < widget.nBack) return;
    _positionMatchedThisTrial = true;
    _totalDecisions++;

    final currentPos = _history[_currentIndex].position;
    final targetPos = _history[_currentIndex - widget.nBack].position;

    if (currentPos == targetPos) {
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
        _score = max(0, _score - 30);
      });
    }
  }

  void _onLetterMatch() {
    if (_letterMatchedThisTrial || _currentIndex < widget.nBack) return;
    _letterMatchedThisTrial = true;
    _totalDecisions++;

    final currentLetter = _history[_currentIndex].letter;
    final targetLetter = _history[_currentIndex - widget.nBack].letter;

    if (currentLetter == targetLetter) {
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
        _score = max(0, _score - 30);
      });
    }
  }

  void _finishGame() {
    _stimulusTimer?.cancel();
    final accuracy = _totalDecisions > 0
        ? (_correctHits / _totalDecisions).clamp(0.0, 1.0)
        : 0.85;

    final result = GameResult(
      sessionId: 'echo-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'echo-sequence',
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
        streakBonus: _comboStreak * 10,
      ),
      totalActiveDuration: const Duration(seconds: 35),
      totalActions: _totalDecisions,
      metrics: {
        'accuracy': accuracy,
        'nBack': widget.nBack,
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
        title: 'Echo Sequence',
        category: 'Memory',
        icon: Icons.psychology_outlined,
        instructions:
            'Watch the 3x3 grid flash tiles and letters in rhythmic sequence.\n\n'
            'Tap [Position Match] if current tile matches ${widget.nBack} steps ago.\n'
            'Tap [Letter Match] if current letter matches ${widget.nBack} steps ago.',
        tips: const [
          'Dual N-Back tests both spatial and auditory buffers.',
          'Try to mentally track both letter sound and position simultaneously.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          _startRhythm();
        },
      ),
    );
  }

  void _handlePause() {
    _stimulusTimer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _advanceTrial();
        },
        onRestart: () {
          Navigator.of(context).pop();
          _generateSequence();
          _startRhythm();
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
            gameTitle: 'Echo Sequence',
            onPlayAgain: () {
              _generateSequence();
              _startRhythm();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    final currentStimulus =
        _history.isNotEmpty && _currentIndex < _history.length
            ? _history[_currentIndex]
            : null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.digit1): _onPositionMatch,
        const SingleActivator(LogicalKeyboardKey.digit2): _onLetterMatch,
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
                    title: 'Echo Sequence',
                    currentRound: min(_currentIndex + 1, _totalRounds),
                    totalRounds: _totalRounds,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Instruction Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          size: 16,
                          color: _facultyColor,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          '${widget.nBack}-Back Working Memory Task',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // 3x3 Arena Grid
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 380,
                            maxHeight: 380,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
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
                                      .withValues(alpha: 0.06),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: 9,
                              itemBuilder: (context, index) {
                                final isTarget = _isFlashing &&
                                    currentStimulus != null &&
                                    currentStimulus.position == index;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isTarget
                                        ? _facultyColor
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: AppRadii.rLg,
                                    border: Border.all(
                                      color: isTarget
                                          ? _facultyColor
                                          : const Color(0xFFCBD5E1),
                                      width: isTarget ? 3 : 1.5,
                                    ),
                                    boxShadow: isTarget
                                        ? [
                                            BoxShadow(
                                              color: _facultyColor.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: isTarget
                                        ? Text(
                                            currentStimulus.letter,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Dual Action Response Buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _currentIndex >= widget.nBack
                                  ? _onPositionMatch
                                  : null,
                              icon: const Icon(Icons.grid_on_rounded, size: 20),
                              label: const Text(
                                'Position Match [1]',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _currentIndex >= widget.nBack
                                  ? _onLetterMatch
                                  : null,
                              icon: const Icon(
                                Icons.spellcheck_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'Letter Match [2]',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _facultyColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
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
