import 'dart:math' as math;
import 'package:game_engine/game_engine.dart';

/// Test fixture: Reaction Time Game Definition.
final class ReactionTimeGameDefinition extends GameDefinition {
  ReactionTimeGameDefinition({
    super.scoringRules = const ReactionTimeScoringRules(),
  }) : super(
          id: 'reaction-time',
          name: 'Reaction Time',
          description:
              'Measure cognitive response speed upon visual stimulus presentation.',
          category: 'processing_speed',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  GameConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
  }) {
    return GameConfig(
      seed: seed ?? 42,
      difficulty: difficulty,
      totalRounds: 3,
      customParameters: {
        'minDelayMs': 1000,
        'maxDelayMs': 2500,
      },
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    return ReactionTimeGameEngine(config: config, scoringRules: scoringRules);
  }
}

/// Scoring rules specialized for Reaction Time.
final class ReactionTimeScoringRules extends ScoringRules {
  const ReactionTimeScoringRules({
    super.version = '1.0.0',
    super.basePoints = 200,
  });

  @override
  ScoreBreakdown calculateScore({
    required int rawPoints,
    required Duration activeDuration,
    required double accuracy,
    required GameDifficulty difficulty,
    int streak = 0,
    int penaltyCount = 0,
  }) {
    final accuracyBonus = (accuracy * 300).round();
    final speedBonus =
        math.max(0, 1000 - (rawPoints)); // rawPoints is avg reaction time in ms
    final penalties = penaltyCount * 50;

    final subtotal =
        math.max(0, basePoints + speedBonus + accuracyBonus - penalties);
    final difficultyBonus =
        ((subtotal * difficulty.multiplier) - subtotal).round();
    final finalScore = subtotal + difficultyBonus;

    return ScoreBreakdown(
      rawScore: rawPoints,
      accuracyBonus: accuracyBonus,
      speedBonus: speedBonus,
      difficultyBonus: difficultyBonus,
      streakBonus: 0,
      penalties: penalties,
      finalScore: finalScore,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'reaction_time',
        'version': version,
        'basePoints': basePoints,
      };

  @override
  List<Object?> get props => [version, basePoints];
}

/// Concrete engine for Reaction Time.
final class ReactionTimeGameEngine extends GameEngineBase {
  ReactionTimeGameEngine({
    required super.config,
    required this.scoringRules,
  });

  final ScoringRules scoringRules;

  final List<int> reactionTimesMs = [];
  int earlyTaps = 0;
  Duration? currentStimulusShownAt;

  @override
  String get gameId => 'reaction-time';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    _scheduleNextStimulus(Duration.zero);
  }

  void _scheduleNextStimulus(Duration baseTimestamp) {
    final minDelay = config.customParameters['minDelayMs'] as int? ?? 1000;
    final maxDelay = config.customParameters['maxDelayMs'] as int? ?? 2500;
    final delay = random.nextIntInRange(minDelay, maxDelay);
    currentStimulusShownAt = baseTimestamp + Duration(milliseconds: delay);
  }

  @override
  GameState processAction(GameState currentState, GameAction action) {
    if (action is! RespondAction) {
      throw InvalidActionException('Unexpected action type: ${action.type}');
    }

    if (currentStimulusShownAt == null) {
      throw const InvalidActionException('No active stimulus in progress');
    }

    // Check if player tapped before the stimulus appeared
    if (action.timestamp < currentStimulusShownAt!) {
      earlyTaps++;
      // Reschedule stimulus with penalty
      _scheduleNextStimulus(action.timestamp);
      return currentState.copyWith(
        score: math.max(0, currentState.score - 50),
        customData: {
          'earlyTap': true,
          'penaltyCount': earlyTaps,
        },
      );
    }

    // Valid tap after stimulus
    final reactionTimeMs =
        (action.timestamp - currentStimulusShownAt!).inMilliseconds;
    reactionTimesMs.add(reactionTimeMs);

    final nextRound = currentState.currentRound + 1;
    final isLastRound = nextRound > currentState.totalRounds;

    if (isLastRound) {
      return currentState.copyWith(
        phase: GamePhase.completed,
        currentRound: currentState.totalRounds,
        customData: {
          'lastReactionTimeMs': reactionTimeMs,
          'completed': true,
        },
      );
    } else {
      _scheduleNextStimulus(action.timestamp);
      return currentState.copyWith(
        currentRound: nextRound,
        customData: {
          'lastReactionTimeMs': reactionTimeMs,
          'earlyTap': false,
        },
      );
    }
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    final avgReaction = reactionTimesMs.isNotEmpty
        ? (reactionTimesMs.reduce((a, b) => a + b) / reactionTimesMs.length)
            .round()
        : 9999;
    final bestReaction =
        reactionTimesMs.isNotEmpty ? reactionTimesMs.reduce(math.min) : 9999;

    final totalTrials = reactionTimesMs.length + earlyTaps;
    final accuracy =
        totalTrials > 0 ? reactionTimesMs.length / totalTrials : 0.0;

    final breakdown = scoringRules.calculateScore(
      rawPoints: avgReaction,
      activeDuration: totalActiveDuration,
      accuracy: accuracy,
      difficulty: config.difficulty,
      penaltyCount: earlyTaps,
    );

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: config.seed,
      difficulty: config.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'averageReactionTimeMs': avgReaction,
        'bestReactionTimeMs': bestReaction,
        'accuracyPercent': (accuracy * 100).round(),
        'earlyTapCount': earlyTaps,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
