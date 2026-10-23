import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Scoring rules and breakdown calculation for Logic Labyrinth.
final class LogicLabyrinthScoringRules extends ScoringRules {
  const LogicLabyrinthScoringRules({
    super.version = '1.0.0',
    super.basePoints = 400,
    this.perfectPathBonus = 250,
    this.excessStepPenalty = 15,
  });

  final int perfectPathBonus;
  final int excessStepPenalty;

  @override
  ScoreBreakdown calculateScore({
    required int rawPoints,
    required Duration activeDuration,
    required double accuracy,
    required GameDifficulty difficulty,
    int streak = 0,
    int penaltyCount = 0,
  }) {
    if (accuracy < 0.0 || accuracy > 1.0) {
      throw GameValidationException(
        'Accuracy must be between 0.0 and 1.0, got: $accuracy',
      );
    }
    if (rawPoints < 0) {
      throw const GameValidationException('rawPoints cannot be negative');
    }
    if (activeDuration.isNegative) {
      throw const GameValidationException('activeDuration cannot be negative');
    }

    final accuracyBonus = (accuracy * 300).round();
    final streakBonus = streak * perfectPathBonus;
    final totalPenalties = penaltyCount * excessStepPenalty;

    final durationSeconds = activeDuration.inSeconds;
    final speedBonus = durationSeconds > 0 && durationSeconds < 60
        ? ((60 - durationSeconds) * 5)
        : 0;

    final subtotal =
        (rawPoints + accuracyBonus + streakBonus + speedBonus - totalPenalties)
            .clamp(0, 1000000);
    final finalScore = (subtotal * difficulty.multiplier).round();
    final difficultyBonus = (finalScore - subtotal).clamp(0, 1000000);

    return ScoreBreakdown(
      rawScore: rawPoints,
      accuracyBonus: accuracyBonus,
      speedBonus: speedBonus,
      streakBonus: streakBonus,
      difficultyBonus: difficultyBonus,
      penalties: totalPenalties,
      finalScore: finalScore,
    );
  }

  ScoreBreakdown calculateBreakdown({
    required int completedMazes,
    required int totalStepsTaken,
    required int totalOptimalSteps,
    required Duration totalDuration,
    required GameDifficulty difficulty,
  }) {
    final rawBase = completedMazes * basePoints;

    final efficiency = totalStepsTaken > 0
        ? (totalOptimalSteps / totalStepsTaken).clamp(0.0, 1.0)
        : 1.0;
    final accuracyBonus = (efficiency * 300).round();

    final excessSteps = (totalStepsTaken - totalOptimalSteps).clamp(0, 999);
    final penalties = excessSteps * excessStepPenalty;

    final perfectBonus = (excessSteps == 0 && completedMazes > 0)
        ? (completedMazes * perfectPathBonus)
        : 0;

    final secondsPerMaze =
        completedMazes > 0 ? totalDuration.inSeconds / completedMazes : 999.0;
    final speedBonus = secondsPerMaze < 30.0
        ? ((30.0 - secondsPerMaze) * 8).round().clamp(0, 200)
        : 0;

    final subtotal =
        (rawBase + accuracyBonus + perfectBonus + speedBonus - penalties)
            .clamp(0, 99999);
    final finalScore = (subtotal * difficulty.multiplier).round();
    final difficultyBonus = (finalScore - subtotal).clamp(0, 99999);

    return ScoreBreakdown(
      rawScore: rawBase,
      accuracyBonus: accuracyBonus,
      speedBonus: speedBonus,
      streakBonus: perfectBonus,
      difficultyBonus: difficultyBonus,
      penalties: penalties,
      finalScore: finalScore,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'logic_labyrinth',
        'version': version,
        'basePoints': basePoints,
        'perfectPathBonus': perfectPathBonus,
        'excessStepPenalty': excessStepPenalty,
      };

  @override
  List<Object?> get props => [
        version,
        basePoints,
        perfectPathBonus,
        excessStepPenalty,
      ];
}
