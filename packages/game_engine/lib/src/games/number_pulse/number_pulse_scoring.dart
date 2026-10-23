import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Scoring rules and breakdown calculation for Number Pulse.
final class NumberPulseScoringRules extends ScoringRules {
  const NumberPulseScoringRules({
    super.version = '1.0.0',
    super.basePoints = 200,
    this.streakBonusPerItem = 40,
    this.speedThresholdMs = 4000,
  });

  final int streakBonusPerItem;
  final int speedThresholdMs;

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

    final accuracyBonus = (accuracy * 250).round();
    final streakBonus = streak * streakBonusPerItem;
    final totalPenalties = penaltyCount * 25;

    final durationSeconds = activeDuration.inSeconds;
    final speedBonus = durationSeconds > 0 && durationSeconds < 30
        ? ((30 - durationSeconds) * 6)
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
    required int correctAnswers,
    required int incorrectAnswers,
    required int maxStreak,
    required List<int> responseTimesMs,
    required Duration totalDuration,
    required GameDifficulty difficulty,
  }) {
    final rawBase = correctAnswers * basePoints;
    final total = correctAnswers + incorrectAnswers;
    final accuracy = total > 0 ? (correctAnswers / total).clamp(0.0, 1.0) : 0.0;
    final accuracyBonus = (accuracy * 250).round();

    final streakBonus = maxStreak * streakBonusPerItem;
    final penalties = incorrectAnswers * 25;

    final avgResponseTime = responseTimesMs.isNotEmpty
        ? responseTimesMs.reduce((a, b) => a + b) / responseTimesMs.length
        : 9999.0;
    final speedBonus = avgResponseTime < speedThresholdMs
        ? (((speedThresholdMs - avgResponseTime) / 100) * 5)
            .round()
            .clamp(0, 150)
        : 0;

    final subtotal =
        (rawBase + accuracyBonus + streakBonus + speedBonus - penalties)
            .clamp(0, 99999);
    final finalScore = (subtotal * difficulty.multiplier).round();
    final difficultyBonus = (finalScore - subtotal).clamp(0, 99999);

    return ScoreBreakdown(
      rawScore: rawBase,
      accuracyBonus: accuracyBonus,
      speedBonus: speedBonus,
      streakBonus: streakBonus,
      difficultyBonus: difficultyBonus,
      penalties: penalties,
      finalScore: finalScore,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'number_pulse',
        'version': version,
        'basePoints': basePoints,
        'streakBonusPerItem': streakBonusPerItem,
        'speedThresholdMs': speedThresholdMs,
      };

  @override
  List<Object?> get props => [
        version,
        basePoints,
        streakBonusPerItem,
        speedThresholdMs,
      ];
}
