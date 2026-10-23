import 'package:equatable/equatable.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Base configuration specifying parameters for a deterministic game run.
@immutable
class GameConfig extends Equatable {
  const GameConfig({
    required this.seed,
    this.difficulty = GameDifficulty.medium,
    this.totalRounds = 5,
    this.timeLimit,
    this.customParameters = const {},
  }) : assert(totalRounds > 0, 'totalRounds must be positive');

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      seed: json['seed'] as int,
      difficulty: GameDifficulty.fromJson(json['difficulty']),
      totalRounds: json['totalRounds'] as int? ?? 5,
      timeLimit: json['timeLimitMs'] != null
          ? Duration(milliseconds: json['timeLimitMs'] as int)
          : null,
      customParameters:
          (json['customParameters'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Initial seed used for all pseudo-random sequence generations.
  final int seed;

  /// Game difficulty level.
  final GameDifficulty difficulty;

  /// Total number of rounds / trials in the session.
  final int totalRounds;

  /// Optional maximum duration limit for the full session or each trial.
  final Duration? timeLimit;

  /// Game-specific custom tuning parameters.
  final Map<String, dynamic> customParameters;

  /// Validates configuration values, throwing [GameValidationException] if invalid.
  void validate() {
    if (totalRounds <= 0) {
      throw const GameValidationException('totalRounds must be greater than 0');
    }
    if (timeLimit != null && timeLimit! <= Duration.zero) {
      throw const GameValidationException('timeLimit must be positive if set');
    }
  }

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'difficulty': difficulty.toJson(),
        'totalRounds': totalRounds,
        if (timeLimit != null) 'timeLimitMs': timeLimit!.inMilliseconds,
        'customParameters': customParameters,
      };

  @override
  List<Object?> get props => [
        seed,
        difficulty,
        totalRounds,
        timeLimit,
        customParameters,
      ];
}
