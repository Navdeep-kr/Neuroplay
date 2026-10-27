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

/// Tower of Chronos (Sequential Planning & Tower of London).
class TowerOfChronosScreen extends ConsumerStatefulWidget {
  const TowerOfChronosScreen({super.key});

  @override
  ConsumerState<TowerOfChronosScreen> createState() =>
      _TowerOfChronosScreenState();
}

class _TowerOfChronosScreenState extends ConsumerState<TowerOfChronosScreen> {
  static const int _totalPuzzles = 3;
  static const Color _facultyColor = Color(0xFF4F46E5);

  final List<List<int>> _pegs = [[], [], []];
  int? _selectedPegIndex;
  int _moves = 0;
  int _puzzleIndex = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _shakeTrigger = 0;
  GameResult? _finalResult;

  final Map<int, Color> _discColors = {
    1: const Color(0xFF38BDF8),
    2: const Color(0xFF10B981),
    3: const Color(0xFFF59E0B),
    4: const Color(0xFF4F46E5),
  };

  @override
  void initState() {
    super.initState();
    _initPuzzle();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  void _initPuzzle() {
    _pegs[0].clear();
    _pegs[1].clear();
    _pegs[2].clear();
    _selectedPegIndex = null;
    _moves = 0;

    final discCount = _puzzleIndex == 3 ? 4 : 3;
    for (var i = discCount; i >= 1; i--) {
      _pegs[0].add(i);
    }

    setState(() {});
  }

  void _onPegTap(int pegIdx) {
    if (_selectedPegIndex == null) {
      if (_pegs[pegIdx].isNotEmpty) {
        setState(() => _selectedPegIndex = pegIdx);
        SoundSynthesizer.playClick();
      }
    } else {
      final fromPeg = _selectedPegIndex!;
      final toPeg = pegIdx;

      if (fromPeg == toPeg) {
        setState(() => _selectedPegIndex = null);
        return;
      }

      final movingDisc = _pegs[fromPeg].last;
      if (_pegs[toPeg].isEmpty || _pegs[toPeg].last > movingDisc) {
        _pegs[fromPeg].removeLast();
        _pegs[toPeg].add(movingDisc);
        _selectedPegIndex = null;
        _moves++;
        _comboStreak++;
        SoundSynthesizer.playSuccess(streak: _comboStreak);
        setState(() {});

        _checkVictory();
      } else {
        _comboStreak = 0;
        SoundSynthesizer.playError();
        setState(() {
          _shakeTrigger++;
          _selectedPegIndex = null;
        });
      }
    }
  }

  void _checkVictory() {
    final discCount = _puzzleIndex == 3 ? 4 : 3;
    if (_pegs[2].length == discCount) {
      SoundSynthesizer.playFanfare();
      final optimalMoves = pow(2, discCount) - 1;
      final efficiencyBonus =
          max(0, 150 - ((_moves - optimalMoves) * 15).toInt());

      setState(() {
        _score += 250 + (_comboStreak * 30) + efficiencyBonus;
      });

      if (_puzzleIndex < _totalPuzzles) {
        setState(() => _puzzleIndex++);
        _initPuzzle();
      } else {
        _finishGame();
      }
    }
  }

  void _finishGame() {
    final result = GameResult(
      sessionId: 'tower-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'tower-of-chronos',
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
        streakBonus: _comboStreak * 25,
      ),
      totalActiveDuration: const Duration(seconds: 45),
      totalActions: _moves,
      metrics: {
        'puzzlesSolved': _totalPuzzles,
        'totalMoves': _moves,
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
        title: 'Tower of Chronos',
        category: 'Problem Solving',
        icon: Icons.alt_route_rounded,
        instructions:
            'Transfer the entire disc stack from Left Peg [1] to Right Peg [3].\n\n'
            'Tap a peg to lift its top disc, then tap destination peg to drop it.\n'
            'RULE: You can NEVER place a larger disc on top of a smaller disc.',
        tips: const [
          'Break the challenge into sub-goals: move the top n-1 discs to the spare peg first.',
          'Fewer moves yield significantly higher efficiency scores.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _puzzleIndex = 1;
            _score = 0;
            _comboStreak = 0;
          });
          _initPuzzle();
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
            _puzzleIndex = 1;
            _score = 0;
            _comboStreak = 0;
          });
          _initPuzzle();
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
            gameTitle: 'Tower of Chronos',
            onPlayAgain: () {
              setState(() {
                _puzzleIndex = 1;
                _score = 0;
                _comboStreak = 0;
              });
              _initPuzzle();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.digit1): () => _onPegTap(0),
        const SingleActivator(LogicalKeyboardKey.digit2): () => _onPegTap(1),
        const SingleActivator(LogicalKeyboardKey.digit3): () => _onPegTap(2),
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
                    title: 'Tower of Chronos',
                    facultyColor: _facultyColor,
                    currentRound: _puzzleIndex,
                    totalRounds: _totalPuzzles,
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
                          Icons.alt_route_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'GOAL: MOVE STACK TO PEG 3 • MOVES: $_moves',
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

                  // 3 Pegs Arena
                  Expanded(
                    child: Center(
                      child: ShakeWidget(
                        shakeTrigger: _shakeTrigger,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 500,
                            maxHeight: 340,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.lg,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPegColumn(0, 'PEG 1'),
                                _buildPegColumn(1, 'PEG 2'),
                                _buildPegColumn(2, 'PEG 3 (GOAL)'),
                              ],
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

  Widget _buildPegColumn(int pegIdx, String label) {
    final isSelected = _selectedPegIndex == pegIdx;
    final discs = _pegs[pegIdx];

    return Expanded(
      child: GestureDetector(
        onTap: () => _onPegTap(pegIdx),
        child: ColoredBox(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 10,
                    height: 180,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? _facultyColor : const Color(0xFFCBD5E1),
                      borderRadius: AppRadii.rFull,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: discs.reversed.map((discSize) {
                      final width = 45.0 + (discSize * 24.0);
                      final color = _discColors[discSize] ?? _facultyColor;

                      return Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: width,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: AppRadii.rFull,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$discSize',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              AppSpacing.gapH12,
              Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(
                  color: isSelected ? _facultyColor : const Color(0xFF64748B),
                  borderRadius: AppRadii.rFull,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? _facultyColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
