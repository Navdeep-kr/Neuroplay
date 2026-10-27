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

class _SemanticTriple {
  const _SemanticTriple({
    required this.words,
    required this.correctLink,
    required this.distractors,
  });

  final List<String> words;
  final String correctLink;
  final List<String> distractors;
}

/// Semantic Bridge (Remote Associates Test).
class SemanticBridgeScreen extends ConsumerStatefulWidget {
  const SemanticBridgeScreen({super.key});

  @override
  ConsumerState<SemanticBridgeScreen> createState() =>
      _SemanticBridgeScreenState();
}

class _SemanticBridgeScreenState extends ConsumerState<SemanticBridgeScreen> {
  static const int _totalRounds = 10;
  static const Color _facultyColor = Color(0xFF0D9488);

  final List<_SemanticTriple> _triples = const [
    _SemanticTriple(
      words: ['COTTAGE', 'SWISS', 'CAKE'],
      correctLink: 'CHEESE',
      distractors: ['BREAD', 'MILK', 'MOUNTAIN'],
    ),
    _SemanticTriple(
      words: ['NIGHT', 'WRIST', 'STOP'],
      correctLink: 'WATCH',
      distractors: ['CLOCK', 'LIGHT', 'SIGN'],
    ),
    _SemanticTriple(
      words: ['RIVER', 'MONEY', 'BLOOD'],
      correctLink: 'BANK',
      distractors: ['FLOW', 'VAULT', 'VESSEL'],
    ),
    _SemanticTriple(
      words: ['FOUNTAIN', 'BALL', 'GEL'],
      correctLink: 'PEN',
      distractors: ['WATER', 'SPRING', 'INK'],
    ),
    _SemanticTriple(
      words: ['MAN', 'WHEEL', 'HIGH'],
      correctLink: 'CHAIR',
      distractors: ['ROAD', 'TABLE', 'HORSE'],
    ),
    _SemanticTriple(
      words: ['PINE', 'CRAB', 'SAUCE'],
      correctLink: 'APPLE',
      distractors: ['TREE', 'BEACH', 'DIP'],
    ),
    _SemanticTriple(
      words: ['NOTE', 'DIVE', 'SWAN'],
      correctLink: 'SONG',
      distractors: ['BOOK', 'BIRD', 'LAKE'],
    ),
    _SemanticTriple(
      words: ['GOLD', 'CANDLE', 'TOOTH'],
      correctLink: 'STICK',
      distractors: ['RING', 'FIRE', 'PASTE'],
    ),
    _SemanticTriple(
      words: ['CRACKER', 'FLY', 'FIGHTER'],
      correctLink: 'FIRE',
      distractors: ['PLANE', 'BOX', 'JACK'],
    ),
    _SemanticTriple(
      words: ['CHAMBER', 'STAFF', 'BOX'],
      correctLink: 'MUSIC',
      distractors: ['WOOD', 'LOCK', 'ROOM'],
    ),
  ];

  int _round = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  List<String> _currentChoices = [];
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

    final triple = _triples[(_round - 1) % _triples.length];
    setState(() {
      _currentChoices = [triple.correctLink, ...triple.distractors]..shuffle();
    });
  }

  void _onAnswer(String chosen) {
    final triple = _triples[(_round - 1) % _triples.length];

    if (chosen == triple.correctLink) {
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
        _score = max(0, _score - 35);
      });
    }
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalRounds).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'rat-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'semantic-bridge',
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
        title: 'Semantic Bridge',
        category: 'Language',
        icon: Icons.link_rounded,
        instructions:
            'Inspect the 3 prompt words displayed in the center cards.\n\n'
            'Discover the single unifying word that forms a compound or conceptual link with ALL three.\n'
            'Tap the matching choice button swiftly to extend your cognitive streak.',
        tips: const [
          'Say the words aloud: Cottage ___, Swiss ___, Cake ___.',
          'Search for common compound words and conceptual bridges.',
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
            gameTitle: 'Semantic Bridge',
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

    final triple = _triples[(_round - 1) % _triples.length];

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
                    title: 'Semantic Bridge',
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
                      color: const Color(0xFFF0FDFA),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'WHICH WORD CONNECTS ALL THREE PROMPTS?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF115E59),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // 3 Prompt Words
                  Expanded(
                    child: Center(
                      child: ShakeWidget(
                        shakeTrigger: _shakeTrigger,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: triple.words
                                .map(
                                  (word) => Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
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
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        word,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          color: Color(0xFF0F172A),
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
                  ),
                  AppSpacing.gapH24,

                  // 4 Choice Buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _currentChoices
                          .map(
                            (choice) => ElevatedButton(
                              onPressed: () => _onAnswer(choice),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _facultyColor,
                                elevation: 0,
                                side: const BorderSide(
                                  color: _facultyColor,
                                  width: 2,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.rXl,
                                ),
                              ),
                              child: Text(
                                choice,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _facultyColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
