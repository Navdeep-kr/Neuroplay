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

class _AnagramItem {
  const _AnagramItem({required this.targetWord, required this.hint});
  final String targetWord;
  final String hint;
}

/// Word Rapids (Lexical Anagram Search).
class WordRapidsScreen extends ConsumerStatefulWidget {
  const WordRapidsScreen({super.key});

  @override
  ConsumerState<WordRapidsScreen> createState() => _WordRapidsScreenState();
}

class _WordRapidsScreenState extends ConsumerState<WordRapidsScreen> {
  static const int _totalRounds = 10;
  static const Color _facultyColor = Color(0xFF0D9488);

  final Random _rng = Random();

  final List<_AnagramItem> _wordList = const [
    _AnagramItem(targetWord: 'BRAIN', hint: 'Central organ of thought'),
    _AnagramItem(targetWord: 'FOCUS', hint: 'Concentrated mental attention'),
    _AnagramItem(targetWord: 'SWIFT', hint: 'Moving with great velocity'),
    _AnagramItem(targetWord: 'SPARK', hint: 'Sudden flash of inspiration'),
    _AnagramItem(
      targetWord: 'AGILE',
      hint: 'Quick and nimble executive control',
    ),
    _AnagramItem(targetWord: 'SHARP', hint: 'Keen perceptual acuity'),
    _AnagramItem(targetWord: 'LOGIC', hint: 'Valid deductive reasoning'),
    _AnagramItem(
      targetWord: 'FLOAT',
      hint: 'Effortlessly drift in equilibrium',
    ),
    _AnagramItem(targetWord: 'CLEVER', hint: 'Quick to understand and solve'),
    _AnagramItem(targetWord: 'MEMORY', hint: 'Retention of neural knowledge'),
  ];

  int _round = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;

  List<String> _poolLetters = [];
  final List<String> _selectedLetters = [];
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

    final item = _wordList[(_round - 1) % _wordList.length];
    final letters = item.targetWord.split('')..shuffle(_rng);

    setState(() {
      _poolLetters = letters;
      _selectedLetters.clear();
    });
  }

  void _onLetterTapFromPool(int index) {
    if (index >= _poolLetters.length) return;
    final letter = _poolLetters.removeAt(index);
    SoundSynthesizer.playClick();
    setState(() {
      _selectedLetters.add(letter);
    });
  }

  void _onLetterTapFromTray(int index) {
    if (index >= _selectedLetters.length) return;
    final letter = _selectedLetters.removeAt(index);
    setState(() {
      _poolLetters.add(letter);
    });
  }

  void _onClear() {
    setState(() {
      _poolLetters.addAll(_selectedLetters);
      _selectedLetters.clear();
    });
  }

  void _onSubmit() {
    final item = _wordList[(_round - 1) % _wordList.length];
    final constructed = _selectedLetters.join();

    if (constructed == item.targetWord) {
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
        _score = max(0, _score - 30);
      });
    }
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalRounds).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'rapids-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'word-rapids',
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
        title: 'Word Rapids',
        category: 'Language',
        icon: Icons.spellcheck_rounded,
        instructions:
            'An array of scrambled letters will appear in your pool.\n\n'
            'Tap the letters in sequence to form a valid English word matching the hint.\n'
            'Tap letters in the upper tray to undo, or tap [SUBMIT] to lock your answer.',
        tips: const [
          'Read the semantic hint first to anticipate root words.',
          'Identify common prefixes and suffixes.',
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
            gameTitle: 'Word Rapids',
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

    final item = _wordList[(_round - 1) % _wordList.length];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.enter): _onSubmit,
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
                    title: 'Word Rapids',
                    facultyColor: _facultyColor,
                    currentRound: min(_round, _totalRounds),
                    totalRounds: _totalRounds,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Hint Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'HINT: ${item.hint.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF115E59),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH32,

                  // Constructed Word Tray
                  ShakeWidget(
                    shakeTrigger: _shakeTrigger,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        maxWidth: 440,
                        minHeight: 80,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.rXxl,
                        border: Border.all(
                          color: _facultyColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _selectedLetters.isEmpty
                            ? const Text(
                                'Tap letter tiles below to construct word',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedLetters
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => GestureDetector(
                                        onTap: () =>
                                            _onLetterTapFromTray(entry.key),
                                        child: Container(
                                          width: 48,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: _facultyColor,
                                            borderRadius: AppRadii.rLg,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _facultyColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH32,

                  // Available Letter Pool
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: _poolLetters
                              .asMap()
                              .entries
                              .map(
                                (entry) => GestureDetector(
                                  onTap: () => _onLetterTapFromPool(entry.key),
                                  child: Container(
                                    width: 56,
                                    height: 60,
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
                                              .withValues(alpha: 0.06),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Action Buttons: Clear & Submit
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed:
                                  _selectedLetters.isNotEmpty ? _onClear : null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
                                ),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _selectedLetters.length ==
                                      item.targetWord.length
                                  ? _onSubmit
                                  : null,
                              icon: const Icon(Icons.check_rounded, size: 20),
                              label: const Text(
                                'SUBMIT [Enter]',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
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
