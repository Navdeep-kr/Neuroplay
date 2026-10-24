import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_result.dart';

/// Base contract for extracting and evaluating game-specific cognitive performance.
abstract class GameDifficultyRule {
  const GameDifficultyRule();

  String get gameId;

  /// Evaluates a valid [GameResult] into a normalized performance index [0.0 - 100.0].
  double evaluatePerformance(GameResult result);

  /// Computes a robust median from a list of response times in milliseconds,
  /// discarding anticipatory mashing (< [minThresholdMs]) and idle pauses (> [maxThresholdMs]).
  double? computeRobustMedianRt(
    List<int> responseTimes, {
    int minThresholdMs = 150,
    int maxThresholdMs = 8000,
  }) {
    final validTimes = responseTimes
        .where((t) => t >= minThresholdMs && t <= maxThresholdMs)
        .toList();

    if (validTimes.isEmpty) return null;
    validTimes.sort();

    final middle = validTimes.length ~/ 2;
    if (validTimes.length.isOdd) {
      return validTimes[middle].toDouble();
    } else {
      return (validTimes[middle - 1] + validTimes[middle]) / 2.0;
    }
  }
}

/// Evaluation rule for Memory Matrix (Spatial Pattern Recall).
final class MemoryMatrixDifficultyRule extends GameDifficultyRule {
  const MemoryMatrixDifficultyRule();

  @override
  String get gameId => 'memory-matrix';

  @override
  double evaluatePerformance(GameResult result) {
    // Primary: accuracy (0.0 - 1.0)
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ??
        (result.metrics['accuracyPercent'] != null
            ? (result.metrics['accuracyPercent'] as num).toDouble() / 100.0
            : 0.5);

    final mistakes = (result.metrics['mistakeCount'] as num?)?.toInt() ?? 0;
    final perfectRounds =
        (result.metrics['perfectRounds'] as num?)?.toInt() ?? 0;

    // Base score from accuracy
    var score = accuracy * 85.0;

    // Bonus for perfect rounds (consistent working memory stability)
    score += (perfectRounds * 3.0).clamp(0.0, 15.0);

    // Minor penalty for high mistake count
    score -= (mistakes * 2.0).clamp(0.0, 15.0);

    return score.clamp(0.0, 100.0);
  }
}

/// Evaluation rule for Reflex Forge (Task Switching & Processing Speed).
final class ReflexForgeDifficultyRule extends GameDifficultyRule {
  const ReflexForgeDifficultyRule();

  @override
  String get gameId => 'reflex-forge';

  @override
  double evaluatePerformance(GameResult result) {
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 0.5;

    // 70% weight on accuracy
    var score = accuracy * 70.0;

    // 30% weight on robust reaction time
    final avgRt = (result.metrics['averageResponseTimeMs'] as num?)?.toDouble();
    if (avgRt != null && avgRt > 0) {
      // Benchmark: 400ms = 30 pts, 1500ms = 0 pts
      final clampedRt = avgRt.clamp(400.0, 1500.0);
      final speedFactor = 1.0 - ((clampedRt - 400.0) / 1100.0);
      score += (speedFactor * 30.0);
    } else {
      score += (accuracy * 30.0);
    }

    return score.clamp(0.0, 100.0);
  }
}

/// Evaluation rule for Focus Reactor (Selective Attention & Distractor Suppression).
final class FocusReactorDifficultyRule extends GameDifficultyRule {
  const FocusReactorDifficultyRule();

  @override
  String get gameId => 'focus-reactor';

  @override
  double evaluatePerformance(GameResult result) {
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 0.5;
    final falseAlarms = (result.metrics['falseAlarms'] as num?)?.toInt() ?? 0;

    // 70% weight on accuracy
    var score = accuracy * 70.0;

    // 30% weight on response speed
    final avgRt = (result.metrics['averageResponseTimeMs'] as num?)?.toDouble();
    if (avgRt != null && avgRt > 0) {
      // Benchmark: 450ms = 30 pts, 1800ms = 0 pts
      final clampedRt = avgRt.clamp(450.0, 1800.0);
      final speedFactor = 1.0 - ((clampedRt - 450.0) / 1350.0);
      score += (speedFactor * 30.0);
    } else {
      score += (accuracy * 30.0);
    }

    // Suppress impulsivity: penalize false alarms
    score -= (falseAlarms * 3.0).clamp(0.0, 15.0);

    return score.clamp(0.0, 100.0);
  }
}

/// Evaluation rule for Logic Labyrinth (Spatial Planning & Deductive Reasoning).
final class LogicLabyrinthDifficultyRule extends GameDifficultyRule {
  const LogicLabyrinthDifficultyRule();

  @override
  String get gameId => 'logic-labyrinth';

  @override
  double evaluatePerformance(GameResult result) {
    // Primary: path efficiency (optimal steps / actual steps taken)
    final efficiency = (result.metrics['efficiency'] as num?)?.toDouble() ??
        ((result.metrics['totalStepsTaken'] != null &&
                result.metrics['totalOptimalSteps'] != null &&
                (result.metrics['totalStepsTaken'] as num) > 0)
            ? ((result.metrics['totalOptimalSteps'] as num) /
                    (result.metrics['totalStepsTaken'] as num))
                .toDouble()
            : 0.5);

    final bounces = (result.metrics['bouncedWallCount'] as num?)?.toInt() ?? 0;
    final completedMazes =
        (result.metrics['completedMazes'] as num?)?.toInt() ?? 1;

    // 75% efficiency weight
    var score = efficiency.clamp(0.0, 1.0) * 75.0;

    // 25% maze completion weight
    score += (completedMazes >= 3 ? 25.0 : completedMazes * 8.0);

    // Penalty for bumping walls repeatedly
    score -= (bounces * 1.5).clamp(0.0, 15.0);

    return score.clamp(0.0, 100.0);
  }
}

/// Evaluation rule for Number Pulse (Mental Arithmetic & Numerical Sequences).
final class NumberPulseDifficultyRule extends GameDifficultyRule {
  const NumberPulseDifficultyRule();

  @override
  String get gameId => 'number-pulse';

  @override
  double evaluatePerformance(GameResult result) {
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 0.5;
    final maxStreak = (result.metrics['maxStreak'] as num?)?.toInt() ?? 0;

    // 70% accuracy
    var score = accuracy * 70.0;

    // Streak bonus
    score += math.min(maxStreak * 2.0, 10.0);

    // 20% response speed
    final avgRt = (result.metrics['averageResponseTimeMs'] as num?)?.toDouble();
    if (avgRt != null && avgRt > 0) {
      // Benchmark: 1000ms = 20 pts, 4500ms = 0 pts
      final clampedRt = avgRt.clamp(1000.0, 4500.0);
      final speedFactor = 1.0 - ((clampedRt - 1000.0) / 3500.0);
      score += (speedFactor * 20.0);
    } else {
      score += (accuracy * 20.0);
    }

    return score.clamp(0.0, 100.0);
  }
}

/// Evaluation rule for Word Weaver (Semantic Association & Vocabulary Retrieval).
final class WordWeaverDifficultyRule extends GameDifficultyRule {
  const WordWeaverDifficultyRule();

  @override
  String get gameId => 'word-weaver';

  @override
  double evaluatePerformance(GameResult result) {
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 0.5;
    final maxStreak = (result.metrics['maxStreak'] as num?)?.toInt() ?? 0;

    // 75% accuracy
    var score = accuracy * 75.0;

    // Streak bonus
    score += math.min(maxStreak * 2.0, 10.0);

    // 15% retrieval speed
    final avgRt = (result.metrics['averageResponseTimeMs'] as num?)?.toDouble();
    if (avgRt != null && avgRt > 0) {
      // Benchmark: 1200ms = 15 pts, 4500ms = 0 pts
      final clampedRt = avgRt.clamp(1200.0, 4500.0);
      final speedFactor = 1.0 - ((clampedRt - 1200.0) / 3300.0);
      score += (speedFactor * 15.0);
    } else {
      score += (accuracy * 15.0);
    }

    return score.clamp(0.0, 100.0);
  }
}
