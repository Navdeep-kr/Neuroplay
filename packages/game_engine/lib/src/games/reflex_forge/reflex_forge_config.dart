import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Configuration for Reflex Forge.
final class ReflexForgeConfig extends GameConfig {
  const ReflexForgeConfig({
    required super.seed,
    super.difficulty = GameDifficulty.medium,
    super.totalRounds = 8,
    super.timeLimit,
    this.ruleShiftFrequency = 3,
    this.optionsCount = 3,
    this.speedTarget = const Duration(milliseconds: 1200),
    this.isPractice = false,
  });

  /// How many trials occur before the matching rule switches.
  final int ruleShiftFrequency;

  /// Number of choice options presented per trial.
  final int optionsCount;

  /// Target response time in milliseconds for full speed bonus.
  final Duration speedTarget;

  /// Whether running in tutorial / practice mode.
  final bool isPractice;

  @override
  void validate() {
    super.validate();
    if (ruleShiftFrequency < 1) {
      throw const GameValidationException(
        'ruleShiftFrequency must be at least 1',
      );
    }
    if (optionsCount < 2 || optionsCount > 4) {
      throw const GameValidationException(
        'optionsCount must be between 2 and 4',
      );
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'ruleShiftFrequency': ruleShiftFrequency,
        'optionsCount': optionsCount,
        'speedTargetMs': speedTarget.inMilliseconds,
        'isPractice': isPractice,
      };
}
