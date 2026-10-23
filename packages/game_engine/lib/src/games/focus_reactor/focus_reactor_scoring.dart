import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Scoring algorithm for Focus Reactor.
final class FocusReactorScoringRules extends ScoringRules {
  const FocusReactorScoringRules({
    super.version = '1.0.0',
    super.basePoints = 150,
    this.pointsPerHit = 100,
    this.pointsPerCorrectRejection = 120,
    this.penaltyPerFalseAlarm = 60,
    this.penaltyPerMiss = 40,
  });

  final int pointsPerHit;
  final int pointsPerCorrectRejection;
  final int penaltyPerFalseAlarm;
  final int penaltyPerMiss;

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
      throw const GameValidationException(
        'Accuracy must be between 0.0 and 1.0',
      );
    }
    if (rawPoints < 0) {
      throw const GameValidationException('rawPoints cannot be negative');
    }
    if (activeDuration.isNegative) {
      throw const GameValidationException('activeDuration cannot be negative');
    }

    final accuracyBonus = (accuracy * 350).round();
    final streakBonus = streak * 15;
    final totalPenalties = penaltyCount * penaltyPerFalseAlarm;

    // Fast selective attention bonus
    final durationSeconds = activeDuration.inSeconds;
    final speedBonus = durationSeconds > 0 && durationSeconds < 25
        ? (25 - durationSeconds) * 8
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
        'type': 'focus_reactor',
        'version': version,
        'basePoints': basePoints,
        'pointsPerHit': pointsPerHit,
        'pointsPerCorrectRejection': pointsPerCorrectRejection,
        'penaltyPerFalseAlarm': penaltyPerFalseAlarm,
      };

  @override
  List<Object?> get props => [
        version,
        basePoints,
        pointsPerHit,
        pointsPerCorrectRejection,
        penaltyPerFalseAlarm,
      ];
}
