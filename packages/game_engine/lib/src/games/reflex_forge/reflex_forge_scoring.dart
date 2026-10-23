import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Scoring algorithm for Reflex Forge.
final class ReflexForgeScoringRules extends ScoringRules {
  const ReflexForgeScoringRules({
    super.version = '1.0.0',
    super.basePoints = 150,
    this.pointsPerCorrectMatch = 120,
    this.speedBonusMax = 80,
    this.penaltyPerError = 50,
  });

  final int pointsPerCorrectMatch;
  final int speedBonusMax;
  final int penaltyPerError;

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
      throw const GameValidationException('Accuracy must be between 0.0 and 1.0');
    }
    if (rawPoints < 0) {
      throw const GameValidationException('rawPoints cannot be negative');
    }
    if (activeDuration.isNegative) {
      throw const GameValidationException('activeDuration cannot be negative');
    }

    final accuracyBonus = (accuracy * 350).round();
    final streakBonus = streak * 15;
    final totalPenalties = penaltyCount * penaltyPerError;

    // Speed bonus per trial completed rapidly
    final speedBonus = math.max(0, speedBonusMax * (streak > 2 ? 2 : 1));

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
        'type': 'reflex_forge',
        'version': version,
        'basePoints': basePoints,
        'pointsPerCorrectMatch': pointsPerCorrectMatch,
        'penaltyPerError': penaltyPerError,
      };

  @override
  List<Object?> get props =>
      [version, basePoints, pointsPerCorrectMatch, penaltyPerError];
}
