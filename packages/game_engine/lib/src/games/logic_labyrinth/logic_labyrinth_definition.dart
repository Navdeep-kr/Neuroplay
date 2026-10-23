import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_config.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_engine.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_scoring.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Specification and blueprint for the Logic Labyrinth cognitive game.
final class LogicLabyrinthDefinition extends GameDefinition {
  LogicLabyrinthDefinition({
    super.scoringRules = const LogicLabyrinthScoringRules(),
  }) : super(
          id: 'logic-labyrinth',
          name: 'Logic Labyrinth',
          description:
              'Plan and navigate optimal paths through spatial mazes with obstacles and checkpoints.',
          category: 'problemSolving',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  LogicLabyrinthConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
    bool isPractice = false,
  }) {
    return LogicLabyrinthConfig.forDifficulty(
      difficulty: difficulty,
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      isPractice: isPractice,
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    if (config is LogicLabyrinthConfig) {
      return LogicLabyrinthGameEngine(
        config: config,
        scoringRules: scoringRules as LogicLabyrinthScoringRules,
      );
    }
    return LogicLabyrinthGameEngine(
      config: LogicLabyrinthConfig(
        seed: config.seed,
        difficulty: config.difficulty,
        totalRounds: config.totalRounds,
        timeLimit: config.timeLimit,
      ),
      scoringRules: scoringRules as LogicLabyrinthScoringRules,
    );
  }
}
