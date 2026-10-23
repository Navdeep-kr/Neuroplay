import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_config.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_engine.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_scoring.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Specification and blueprint for the Number Pulse cognitive game.
final class NumberPulseDefinition extends GameDefinition {
  NumberPulseDefinition({
    super.scoringRules = const NumberPulseScoringRules(),
  }) : super(
          id: 'number-pulse',
          name: 'Number Pulse',
          description:
              'Rapid mental arithmetic and numerical sequence recognition under time pressure.',
          category: 'speed',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  NumberPulseConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
    bool isPractice = false,
  }) {
    return NumberPulseConfig.forDifficulty(
      difficulty: difficulty,
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      isPractice: isPractice,
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    if (config is NumberPulseConfig) {
      return NumberPulseGameEngine(
        config: config,
        scoringRules: scoringRules as NumberPulseScoringRules,
      );
    }
    return NumberPulseGameEngine(
      config: NumberPulseConfig(
        seed: config.seed,
        difficulty: config.difficulty,
        totalRounds: config.totalRounds,
        timeLimit: config.timeLimit,
      ),
      scoringRules: scoringRules as NumberPulseScoringRules,
    );
  }
}
