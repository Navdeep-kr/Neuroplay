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

class _TrailNode {
  const _TrailNode({
    required this.index,
    required this.label,
    required this.x,
    required this.y,
  });
  final int index;
  final String label;
  final double x;
  final double y;
}

/// Trailblazer (Trail Making Test - Task Switching).
class TrailblazerScreen extends ConsumerStatefulWidget {
  const TrailblazerScreen({super.key});

  @override
  ConsumerState<TrailblazerScreen> createState() => _TrailblazerScreenState();
}

class _TrailblazerScreenState extends ConsumerState<TrailblazerScreen> {
  static const int _totalRounds = 3;
  static const Color _facultyColor = Color(0xFF059669);

  final Random _rng = Random();
  final List<String> _sequenceLabels = [
    '1',
    'A',
    '2',
    'B',
    '3',
    'C',
    '4',
    'D',
    '5',
    'E',
    '6',
    'F',
  ];

  int _round = 1;
  int _score = 0;
  int _comboStreak = 0;
  int _currentStep = 0;
  int _shakeTrigger = 0;
  int _mistakes = 0;
  GameResult? _finalResult;

  final List<_TrailNode> _nodes = [];
  final List<_TrailNode> _connectedNodes = [];

  @override
  void initState() {
    super.initState();
    _generateNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialDialog());
  }

  void _generateNodes() {
    _nodes.clear();
    _connectedNodes.clear();
    _currentStep = 0;

    const margin = 0.12;
    for (var i = 0; i < _sequenceLabels.length; i++) {
      var nx = 0.0;
      var ny = 0.0;
      var attempts = 0;
      var valid = false;

      while (!valid && attempts < 100) {
        attempts++;
        nx = margin + _rng.nextDouble() * (1.0 - 2 * margin);
        ny = margin + _rng.nextDouble() * (1.0 - 2 * margin);
        valid = true;

        for (final other in _nodes) {
          final dist = sqrt(pow(nx - other.x, 2) + pow(ny - other.y, 2));
          if (dist < 0.18) {
            valid = false;
            break;
          }
        }
      }

      _nodes.add(
        _TrailNode(
          index: i,
          label: _sequenceLabels[i],
          x: nx,
          y: ny,
        ),
      );
    }
  }

  void _onNodeTap(_TrailNode node) {
    if (node.index == _currentStep) {
      _comboStreak++;
      SoundSynthesizer.playSuccess(streak: _comboStreak);
      setState(() {
        _connectedNodes.add(node);
        _currentStep++;
        _score += 100 + (_comboStreak * 20);
      });

      if (_currentStep >= _nodes.length) {
        SoundSynthesizer.playFanfare();
        if (_round < _totalRounds) {
          setState(() {
            _round++;
          });
          _generateNodes();
        } else {
          _finishGame();
        }
      }
    } else if (node.index > _currentStep) {
      _comboStreak = 0;
      SoundSynthesizer.playError();
      setState(() {
        _shakeTrigger++;
        _mistakes++;
        _score = max(0, _score - 30);
      });
    }
  }

  void _finishGame() {
    final totalSteps = _totalRounds * _sequenceLabels.length;
    final accuracy = (totalSteps / (totalSteps + _mistakes)).clamp(0.0, 1.0);

    final result = GameResult(
      sessionId: 'trail-${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'trailblazer',
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
        speedBonus: 150,
        streakBonus: _comboStreak * 20,
        penalties: _mistakes * 20,
      ),
      totalActiveDuration: const Duration(seconds: 45),
      totalActions: totalSteps + _mistakes,
      metrics: {
        'accuracy': accuracy,
        'mistakes': _mistakes,
        'rounds': _totalRounds,
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
        title: 'Trailblazer',
        category: 'Flexibility',
        icon: Icons.alt_route_rounded,
        instructions: 'Connect scattered circles in alternating sequence:\n'
            '1 -> A -> 2 -> B -> 3 -> C...\n\n'
            'Tap the next designated target node to extend your illuminated trail.',
        tips: const [
          'Pre-scan the canvas for the next letter while tapping the number.',
          'Fluid task switching creates continuous accuracy multiplier streaks.',
        ],
        onStart: ({required difficulty, required isPractice}) {
          setState(() {
            _round = 1;
            _score = 0;
            _comboStreak = 0;
            _mistakes = 0;
          });
          _generateNodes();
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
            _mistakes = 0;
          });
          _generateNodes();
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
            gameTitle: 'Trailblazer',
            onPlayAgain: () {
              setState(() {
                _round = 1;
                _score = 0;
                _comboStreak = 0;
                _mistakes = 0;
              });
              _generateNodes();
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    final nextTargetLabel = _currentStep < _sequenceLabels.length
        ? _sequenceLabels[_currentStep]
        : 'DONE';

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
                    title: 'Trailblazer',
                    facultyColor: _facultyColor,
                    currentRound: _round,
                    totalRounds: _totalRounds,
                    score: _score,
                    comboStreak: _comboStreak,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Target Instruction Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: AppRadii.rFull,
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 18,
                          color: _facultyColor,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'NEXT TARGET: [ $nextTargetLabel ]',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Trail Arena
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 440,
                            maxHeight: 440,
                          ),
                          child: ShakeWidget(
                            shakeTrigger: _shakeTrigger,
                            child: DecoratedBox(
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
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadii.rXxl,
                                child: CustomPaint(
                                  painter: _TrailPainter(
                                    connectedNodes: _connectedNodes,
                                    facultyColor: _facultyColor,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final w = constraints.maxWidth;
                                      final h = constraints.maxHeight;

                                      return Stack(
                                        children: _nodes.map((node) {
                                          final isConnected =
                                              node.index < _currentStep;
                                          final isNext =
                                              node.index == _currentStep;

                                          return Positioned(
                                            left: (node.x * w) - 22,
                                            top: (node.y * h) - 22,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _onNodeTap(node),
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isConnected
                                                        ? _facultyColor
                                                        : isNext
                                                            ? const Color(
                                                                0xFFECFDF5,
                                                              )
                                                            : Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          isConnected || isNext
                                                              ? _facultyColor
                                                              : const Color(
                                                                  0xFF94A3B8,
                                                                ),
                                                      width: isNext ? 3 : 2,
                                                    ),
                                                    boxShadow: isNext
                                                        ? [
                                                            BoxShadow(
                                                              color: _facultyColor
                                                                  .withValues(
                                                                alpha: 0.35,
                                                              ),
                                                              blurRadius: 10,
                                                              spreadRadius: 2,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      node.label,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isConnected
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF0F172A,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
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

class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.connectedNodes,
    required this.facultyColor,
  });

  final List<_TrailNode> connectedNodes;
  final Color facultyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (connectedNodes.length < 2) return;

    final paint = Paint()
      ..color = facultyColor.withValues(alpha: 0.65)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(
        connectedNodes.first.x * size.width,
        connectedNodes.first.y * size.height,
      );

    for (var i = 1; i < connectedNodes.length; i++) {
      path.lineTo(
        connectedNodes[i].x * size.width,
        connectedNodes[i].y * size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      oldDelegate.connectedNodes.length != connectedNodes.length;
}
