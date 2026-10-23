import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Scoring algorithm for Memory Matrix.
final class MemoryMatrixScoringRules extends ScoringRules {
  const MemoryMatrixScoringRules({
    super.version = '1.0.0',
    super.basePoints = 150,
    this.pointsPerCorrectTile = 100,
    this.penaltyPerMistake = 40,
    this.perfectRoundBonus = 150,
  });

  final int pointsPerCorrectTile;
  final int penaltyPerMistake;
  final int perfectRoundBonus;

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

    final accuracyBonus = (accuracy * 400).round();
    final streakBonus = streak * perfectRoundBonus;
    final totalPenalties = penaltyCount * penaltyPerMistake;

    // Moderate speed bonus for completing recall promptly without rushing
    final durationSeconds = activeDuration.inSeconds;
    final speedBonus = durationSeconds > 0 && durationSeconds < 30
        ? ((30 - durationSeconds) * 10)
        : 0;

    final subtotal = math.max(
      0,
      rawPoints +
          basePoints +
          accuracyBonus +
          streakBonus +
          speedBonus -
          totalPenalties,
    );
    final difficultyBonus =
        ((subtotal * difficulty.multiplier) - subtotal).round();
    final finalScore = subtotal + difficultyBonus;

    return ScoreBreakdown(
      rawScore: rawPoints,
      accuracyBonus: accuracyBonus,
      speedBonus: speedBonus,
      difficultyBonus: difficultyBonus,
      streakBonus: streakBonus,
      penalties: totalPenalties,
      finalScore: finalScore,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'memory_matrix',
        'version': version,
        'basePoints': basePoints,
        'pointsPerCorrectTile': pointsPerCorrectTile,
        'penaltyPerMistake': penaltyPerMistake,
        'perfectRoundBonus': perfectRoundBonus,
      };

  @override
  List<Object?> get props => [
        version,
        basePoints,
        pointsPerCorrectTile,
        penaltyPerMistake,
        perfectRoundBonus,
      ];
}
