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

enum _ArrowDirection { left, right }

class _FlankerTrial {
  const _FlankerTrial({
    required this.targetDirection,
    required this.isCongruent,
  });

  final _ArrowDirection targetDirection;
  final bool isCongruent;

  List<_ArrowDirection> get arrows {
    final flanker = isCongruent
        ? targetDirection
        : (targetDirection == _ArrowDirection.left
            ? _ArrowDirection.right
            : _ArrowDirection.left);

    return [flanker, flanker, targetDirection, flanker, flanker];
  }
}

/// Flanker Strike (Eriksen Flanker Task).
class FlankerStrikeScreen extends ConsumerStatefulWidget {
  const FlankerStrikeScreen({super.key});

  @override
  ConsumerState<FlankerStrikeScreen> createState() =>
      _FlankerStrikeScreenState();
}

class _FlankerStrikeScreenState extends ConsumerState<FlankerStrikeScreen> {
  static const int _totalTrials = 25;
  static const Color _facultyColor = Color(0xFFD97706);

  final Random _rng = Random();

  int _trialIndex = 0;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  _FlankerTrial? _currentTrial;
  DateTime _trialStartTime = DateTime.now();
  final List<int> _latencies = [];
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

    final target =
        _rng.nextBool() ? _ArrowDirection.left : _ArrowDirection.right;
    final isCongruent = _rng.nextDouble() < 0.45;

    setState(() {
      _trialIndex++;
      _currentTrial = _FlankerTrial(
        targetDirection: target,
        isCongruent: isCongruent,
      );
      _trialStartTime = DateTime.now();
    });
  }

  void _onAnswer(_ArrowDirection direction) {
    if (_currentTrial == null) return;
    final latency = DateTime.now().difference(_trialStartTime).inMilliseconds;
    _latencies.add(latency);

    if (direction == _currentTrial!.targetDirection) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      final speedBonus = latency < 450 ? 30 : 0;
      setState(() {
        _correctHits++;
        _score += 100 + (_comboStreak * 15) + speedBonus;
      });
    } else {
      _comboStreak = 0;
      SoundSynthesizer.playError();
      setState(() {
        _shakeTrigger++;
        _score = max(0, _score - 30);
      });
    }

    _nextTrial();
  }

  void _finishGame() {
    final accuracy = (_correctHits / _totalTrials).clamp(0.0, 1.0);
    final medianRt = _latencies.isNotEmpty
        ? (_latencies..sort())[_latencies.length ~/ 2]
        : 450;

    final result = GameResult(
      sessionId: 'flanker-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'flanker-strike',
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
        'medianRtMs': medianRt,
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
        title: 'Flanker Strike',
        category: 'Attention',
        icon: Icons.center_focus_strong_rounded,
        instructions: 'A row of 5 arrows will appear in rapid succession.\n\n'
            'Focus SOLELY on the center target arrow, ignoring flanking arrows.\n'
            'Tap [LEFT] or [RIGHT] (or Arrow Keys) to indicate the center arrow direction.',
        tips: const [
          'Filter out peripheral visual noise by locking your gaze at the exact center.',
          'Sub-450ms responses trigger bonus cognitive points.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _trialIndex = 0;
            _score = 0;
            _comboStreak = 0;
            _correctHits = 0;
            _latencies.clear();
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
            _latencies.clear();
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
            gameTitle: 'Flanker Strike',
            onPlayAgain: () {
              setState(() {
                _trialIndex = 0;
                _score = 0;
                _comboStreak = 0;
                _correctHits = 0;
                _latencies.clear();
              });
              _nextTrial();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    final arrows = _currentTrial?.arrows ?? [];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _onAnswer(_ArrowDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _onAnswer(_ArrowDirection.right),
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
                    title: 'Flanker Strike',
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
                      color: const Color(0xFFFEF3C7),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_strong_rounded,
                          size: 16,
                          color: _facultyColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'INDICATE CENTER ARROW DIRECTION ONLY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH32,

                  // Central Stimulus Box
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
                              children: arrows.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final dir = entry.value;
                                final isCenter = idx == 2;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    dir == _ArrowDirection.left
                                        ? Icons.arrow_back_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: isCenter ? 54 : 42,
                                    color: isCenter
                                        ? _facultyColor
                                        : const Color(0xFF94A3B8),
                                  ),
                                );
                              }).toList(),
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
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () => _onAnswer(_ArrowDirection.left),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 24,
                              ),
                              label: const Text(
                                'LEFT [◀]',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () => _onAnswer(_ArrowDirection.right),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 24,
                              ),
                              label: const Text(
                                'RIGHT [▶]',
                                style: TextStyle(
                                  fontSize: 15,
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
