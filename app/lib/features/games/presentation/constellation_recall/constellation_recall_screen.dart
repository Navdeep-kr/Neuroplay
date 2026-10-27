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

class _StarNode {
  const _StarNode({required this.id, required this.icon, required this.color});
  final int id;
  final IconData icon;
  final Color color;
}

/// Constellation Recall (Spatial Object-Location Memory).
class ConstellationRecallScreen extends ConsumerStatefulWidget {
  const ConstellationRecallScreen({super.key});

  @override
  ConsumerState<ConstellationRecallScreen> createState() =>
      _ConstellationRecallScreenState();
}

class _ConstellationRecallScreenState
    extends ConsumerState<ConstellationRecallScreen> {
  static const int _totalRounds = 8;
  static const int _gridSize = 16;

  final Random _rng = Random();
  final List<IconData> _starIcons = [
    Icons.star_rounded,
    Icons.diamond_rounded,
    Icons.wb_sunny_rounded,
    Icons.lens_blur_rounded,
    Icons.flare_rounded,
  ];

  final List<Color> _starColors = [
    const Color(0xFF2563EB),
    const Color(0xFF7C3AED),
    const Color(0xFFD97706),
    const Color(0xFF059669),
    const Color(0xFFDC2626),
  ];

  int _round = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _correctHits = 0;
  int _shakeTrigger = 0;
  bool _isObserving = true;
  int? _displacedStarId;
  GameResult? _finalResult;

  final Map<int, _StarNode> _initialLocations = {};
  Map<int, _StarNode> _activeLocations = {};
  Timer? _observeTimer;

  @override
  void initState() {
    super.initState();
    _startNextRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  @override
  void dispose() {
    _observeTimer?.cancel();
    super.dispose();
  }

  void _startNextRound() {
    if (_round > _totalRounds) {
      _finishGame();
      return;
    }

    _initialLocations.clear();
    _activeLocations.clear();

    final positions = List.generate(_gridSize, (i) => i)..shuffle(_rng);
    final chosenPositions = positions.take(5).toList();

    for (var i = 0; i < 5; i++) {
      final node = _StarNode(
        id: i,
        icon: _starIcons[i % _starIcons.length],
        color: _starColors[i % _starColors.length],
      );
      _initialLocations[chosenPositions[i]] = node;
    }

    setState(() {
      _isObserving = true;
      _activeLocations = Map.from(_initialLocations);
    });

    SoundSynthesizer.playClick();

    _observeTimer?.cancel();
    _observeTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      _displaceOneStar();
    });
  }

  void _displaceOneStar() {
    final starToDisplaceIndex = _rng.nextInt(5);
    var originalPos = -1;
    _StarNode? displacedNode;

    for (final entry in _initialLocations.entries) {
      if (entry.value.id == starToDisplaceIndex) {
        originalPos = entry.key;
        displacedNode = entry.value;
        break;
      }
    }

    if (displacedNode == null) return;
    _displacedStarId = displacedNode.id;

    final emptyPositions = List.generate(_gridSize, (i) => i)
        .where((pos) => !_initialLocations.containsKey(pos))
        .toList()
      ..shuffle(_rng);

    final newPos = emptyPositions.first;
    final newLocations = Map<int, _StarNode>.from(_initialLocations)
      ..remove(originalPos)
      ..[newPos] = displacedNode;

    setState(() {
      _isObserving = false;
      _activeLocations = newLocations;
    });
  }

  void _onTileTap(int position) {
    if (_isObserving) return;
    final star = _activeLocations[position];
    if (star == null) return;

    if (star.id == _displacedStarId) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      setState(() {
        _correctHits++;
        _score += 150 + (_comboStreak * 25);
        _round++;
      });
      _startNextRound();
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
    _observeTimer?.cancel();
    final accuracy = (_correctHits / _totalRounds).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'const-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'constellation-recall',
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
        title: 'Constellation Recall',
        category: 'Memory',
        icon: Icons.star_rounded,
        instructions:
            'Memorize the celestial coordinates of the 5 glowing stars.\n\n'
            'After 3 seconds, exactly ONE star will alter its position.\n'
            'Tap the relocated star to score points and maintain your streak.',
        tips: const [
          'Form spatial triangles or shapes in your mind.',
          'Notice which quad has the densest star group.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          _round = 1;
          _score = 0;
          _comboStreak = 0;
          _correctHits = 0;
          _startNextRound();
        },
      ),
    );
  }

  void _handlePause() {
    _observeTimer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _startNextRound();
        },
        onRestart: () {
          Navigator.of(context).pop();
          _round = 1;
          _score = 0;
          _comboStreak = 0;
          _correctHits = 0;
          _startNextRound();
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
            gameTitle: 'Constellation Recall',
            onPlayAgain: () {
              _round = 1;
              _score = 0;
              _comboStreak = 0;
              _correctHits = 0;
              _startNextRound();
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
                    title: 'Constellation Recall',
                    currentRound: min(_round, _totalRounds),
                    totalRounds: _totalRounds,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Phase Banner
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _isObserving
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFECFDF5),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(
                        color: _isObserving
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isObserving
                              ? Icons.visibility_rounded
                              : Icons.touch_app_rounded,
                          size: 16,
                          color: _isObserving
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF059669),
                        ),
                        AppSpacing.gapW8,
                        Text(
                          _isObserving
                              ? 'MEMORIZE STAR COORDINATES (3s)'
                              : 'TAP THE SHIFTED STAR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isObserving
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Celestial 4x4 Grid
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 420,
                            maxHeight: 420,
                          ),
                          child: ShakeWidget(
                            shakeTrigger: _shakeTrigger,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B132B),
                                borderRadius: AppRadii.rXxl,
                                border: Border.all(
                                  color: const Color(0xFF1E293B),
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
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _gridSize,
                                itemBuilder: (context, index) {
                                  final star = _activeLocations[index];

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: star != null
                                          ? () => _onTileTap(index)
                                          : null,
                                      borderRadius: AppRadii.rLg,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C2541),
                                          borderRadius: AppRadii.rLg,
                                          border: Border.all(
                                            color: star != null
                                                ? star.color
                                                : const Color(0xFF334155),
                                            width: star != null ? 2 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: star != null
                                              ? Icon(
                                                  star.icon,
                                                  size: 32,
                                                  color: star.color,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
