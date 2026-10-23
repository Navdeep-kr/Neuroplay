import 'package:equatable/equatable.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Immutable, validated output of a finalized cognitive game session.
///
/// **Architectural Security Boundary**:
/// [GameResult] strictly represents client-side gameplay performance metrics.
/// It contains NO mechanism or authority to grant user XP, unlock subscriptions,
/// or directly modify backend entitlement records. All XP granting and entitlement
/// evaluations are calculated securely server-side via trusted Supabase Edge Functions.
@immutable
final class GameResult extends Equatable {
  GameResult({
    required this.sessionId,
    required this.gameId,
    required this.gameVersion,
    required this.engineVersion,
    required this.scoringRulesVersion,
    required this.seed,
    required this.difficulty,
    required this.completionPhase,
    required this.finalScore,
    required this.scoreBreakdown,
    required this.totalActiveDuration,
    required this.totalActions,
    required this.metrics,
    required this.completedAt,
    this.isOffline = false,
  }) {
    validate();
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    try {
      return GameResult(
        sessionId: json['sessionId'] as String,
        gameId: json['gameId'] as String,
        gameVersion: json['gameVersion'] as String,
        engineVersion: json['engineVersion'] as String,
        scoringRulesVersion: json['scoringRulesVersion'] as String,
        seed: json['seed'] as int,
        difficulty: GameDifficulty.fromJson(json['difficulty']),
        completionPhase: GamePhase.fromJson(json['completionPhase'] as String),
        finalScore: json['finalScore'] as int,
        scoreBreakdown: ScoreBreakdown.fromJson(
          json['scoreBreakdown'] as Map<String, dynamic>,
        ),
        totalActiveDuration: Duration(
          milliseconds: json['totalActiveDurationMs'] as int,
        ),
        totalActions: json['totalActions'] as int,
        metrics: (json['metrics'] as Map<String, dynamic>?) ?? const {},
        completedAt: DateTime.parse(json['completedAt'] as String),
        isOffline: json['isOffline'] as bool? ?? false,
      );
    } catch (e) {
      if (e is GameValidationException) rethrow;
      throw GameValidationException('Failed to parse GameResult JSON', e);
    }
  }

  final String sessionId;
  final String gameId;
  final String gameVersion;
  final String engineVersion;
  final String scoringRulesVersion;
  final int seed;
  final GameDifficulty difficulty;
  final GamePhase completionPhase;
  final int finalScore;
  final ScoreBreakdown scoreBreakdown;
  final Duration totalActiveDuration;
  final int totalActions;
  final Map<String, dynamic> metrics;
  final DateTime completedAt;
  final bool isOffline;

  /// Validates integrity of all result fields.
  void validate() {
    if (sessionId.trim().isEmpty) {
      throw const GameValidationException('sessionId cannot be empty');
    }
    if (gameId.trim().isEmpty) {
      throw const GameValidationException('gameId cannot be empty');
    }
    if (gameVersion.trim().isEmpty) {
      throw const GameValidationException('gameVersion cannot be empty');
    }
    if (engineVersion.trim().isEmpty) {
      throw const GameValidationException('engineVersion cannot be empty');
    }
    if (!completionPhase.isTerminal) {
      throw GameValidationException(
        'completionPhase must be terminal (completed or aborted), got: ${completionPhase.name}',
      );
    }
    if (finalScore < 0) {
      throw GameValidationException(
        'finalScore cannot be negative: $finalScore',
      );
    }
    if (totalActiveDuration.isNegative) {
      throw const GameValidationException(
        'totalActiveDuration cannot be negative',
      );
    }
    if (totalActions < 0) {
      throw GameValidationException(
        'totalActions cannot be negative: $totalActions',
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'engineVersion': engineVersion,
        'scoringRulesVersion': scoringRulesVersion,
        'seed': seed,
        'difficulty': difficulty.toJson(),
        'completionPhase': completionPhase.toJson(),
        'finalScore': finalScore,
        'scoreBreakdown': scoreBreakdown.toJson(),
        'totalActiveDurationMs': totalActiveDuration.inMilliseconds,
        'totalActions': totalActions,
        'metrics': metrics,
        'completedAt': completedAt.toIso8601String(),
        'isOffline': isOffline,
      };

  @override
  List<Object?> get props => [
        sessionId,
        gameId,
        gameVersion,
        engineVersion,
        scoringRulesVersion,
        seed,
        difficulty,
        completionPhase,
        finalScore,
        scoreBreakdown,
        totalActiveDuration,
        totalActions,
        metrics,
        completedAt,
        isOffline,
      ];
}
