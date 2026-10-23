import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Detailed breakdown of calculated score components.
@immutable
final class ScoreBreakdown extends Equatable {
  const ScoreBreakdown({
    required this.rawScore,
    required this.finalScore,
    this.accuracyBonus = 0,
    this.speedBonus = 0,
    this.difficultyBonus = 0,
    this.streakBonus = 0,
    this.penalties = 0,
  })  : assert(rawScore >= 0, 'rawScore cannot be negative'),
        assert(finalScore >= 0, 'finalScore cannot be negative');

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      rawScore: json['rawScore'] as int,
      finalScore: json['finalScore'] as int,
      accuracyBonus: json['accuracyBonus'] as int? ?? 0,
      speedBonus: json['speedBonus'] as int? ?? 0,
      difficultyBonus: json['difficultyBonus'] as int? ?? 0,
      streakBonus: json['streakBonus'] as int? ?? 0,
      penalties: json['penalties'] as int? ?? 0,
    );
  }

  final int rawScore;
  final int accuracyBonus;
  final int speedBonus;
  final int difficultyBonus;
  final int streakBonus;
  final int penalties;
  final int finalScore;

  Map<String, dynamic> toJson() => {
        'rawScore': rawScore,
        'accuracyBonus': accuracyBonus,
        'speedBonus': speedBonus,
        'difficultyBonus': difficultyBonus,
        'streakBonus': streakBonus,
        'penalties': penalties,
        'finalScore': finalScore,
      };

  @override
  List<Object?> get props => [
        rawScore,
        accuracyBonus,
        speedBonus,
        difficultyBonus,
        streakBonus,
        penalties,
        finalScore,
      ];
}

/// Abstract contract for versioned game scoring rules.
///
/// Ensures score computation is transparent, testable, and version-tracked
/// so adjustments to game balance do not invalidate historical records.
abstract class ScoringRules extends Equatable {
  const ScoringRules({
    required this.version,
    required this.basePoints,
  }) : assert(basePoints >= 0, 'basePoints must be non-negative');

  /// Semantic version of this scoring algorithm (e.g. '1.0.0').
  final String version;

  /// Base points awarded upon completing standard rounds.
  final int basePoints;

  /// Computes a deterministic [ScoreBreakdown] given performance parameters.
  ScoreBreakdown calculateScore({
    required int rawPoints,
    required Duration activeDuration,
    required double accuracy,
    required GameDifficulty difficulty,
    int streak = 0,
    int penaltyCount = 0,
  });

  Map<String, dynamic> toJson();
}

/// Standard linear scoring ruleset for cognitive tasks.
class StandardScoringRules extends ScoringRules {
  const StandardScoringRules({
    super.version = '1.0.0',
    super.basePoints = 100,
    this.accuracyWeight = 500,
    this.speedBonusThreshold = const Duration(milliseconds: 500),
    this.penaltyPerMistake = 25,
  });

  factory StandardScoringRules.fromJson(Map<String, dynamic> json) {
    return StandardScoringRules(
      version: json['version'] as String? ?? '1.0.0',
      basePoints: json['basePoints'] as int? ?? 100,
      accuracyWeight: json['accuracyWeight'] as int? ?? 500,
      speedBonusThreshold: Duration(
        milliseconds: json['speedBonusThresholdMs'] as int? ?? 500,
      ),
      penaltyPerMistake: json['penaltyPerMistake'] as int? ?? 25,
    );
  }

  final int accuracyWeight;
  final Duration speedBonusThreshold;
  final int penaltyPerMistake;

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
      throw GameValidationException('rawPoints cannot be negative: $rawPoints');
    }
    if (activeDuration.isNegative) {
      throw const GameValidationException('activeDuration cannot be negative');
    }

    final accuracyBonus = (accuracy * accuracyWeight).round();
    final streakBonus = streak * 10;
    final totalPenalties = penaltyCount * penaltyPerMistake;

    // Speed bonus awarded if under speed threshold per expected trial
    final durationMs = activeDuration.inMilliseconds;
    final speedBonus =
        durationMs > 0 && durationMs < speedBonusThreshold.inMilliseconds
            ? ((speedBonusThreshold.inMilliseconds - durationMs) * 0.2).round()
            : 0;

    final subtotal = rawPoints +
        basePoints +
        accuracyBonus +
        streakBonus +
        speedBonus -
        totalPenalties;
    final nonNegativeSubtotal = math.max(0, subtotal);

    final difficultyBonus =
        ((nonNegativeSubtotal * difficulty.multiplier) - nonNegativeSubtotal)
            .round();
    final finalScore = nonNegativeSubtotal + difficultyBonus;

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
        'type': 'standard',
        'version': version,
        'basePoints': basePoints,
        'accuracyWeight': accuracyWeight,
        'speedBonusThresholdMs': speedBonusThreshold.inMilliseconds,
        'penaltyPerMistake': penaltyPerMistake,
      };

  @override
  List<Object?> get props => [
        version,
        basePoints,
        accuracyWeight,
        speedBonusThreshold,
        penaltyPerMistake,
      ];
}
