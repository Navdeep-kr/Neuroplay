import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Configuration parameters for Focus Reactor.
final class FocusReactorConfig extends GameConfig {
  const FocusReactorConfig({
    required super.seed,
    super.difficulty = GameDifficulty.medium,
    super.totalRounds = 8,
    super.timeLimit,
    this.displaySlots = 4,
    this.targetPresenceRatio = 0.75,
    this.speedBonusThreshold = const Duration(milliseconds: 1400),
    this.isPractice = false,
  });

  /// Total item slots displayed simultaneously (4 on easy/medium, 6 on hard).
  final int displaySlots;

  /// Probability [0.0 - 1.0] that the target appears in the array.
  final double targetPresenceRatio;

  /// Speed threshold in milliseconds to earn rapid attention bonus.
  final Duration speedBonusThreshold;

  /// Whether running in tutorial / practice mode.
  final bool isPractice;

  @override
  void validate() {
    super.validate();
    if (displaySlots < 3 || displaySlots > 8) {
      throw const GameValidationException(
        'displaySlots must be between 3 and 8',
      );
    }
    if (targetPresenceRatio <= 0.0 || targetPresenceRatio >= 1.0) {
      throw const GameValidationException(
        'targetPresenceRatio must be between 0.0 and 1.0',
      );
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'displaySlots': displaySlots,
        'targetPresenceRatio': targetPresenceRatio,
        'speedBonusThresholdMs': speedBonusThreshold.inMilliseconds,
        'isPractice': isPractice,
      };
}
