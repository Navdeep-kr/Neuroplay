import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_config.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_engine.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_scoring.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Blueprint for the Reflex Forge cognitive exercise.
final class ReflexForgeDefinition extends GameDefinition {
  ReflexForgeDefinition({
    super.scoringRules = const ReflexForgeScoringRules(),
  }) : super(
          id: 'reflex-forge',
          name: 'Reflex Forge',
          description:
              'Match geometric symbols to dynamically shifting rules with speed and precision.',
          category: 'flexibility',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  ReflexForgeConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
    bool isPractice = false,
  }) {
    final int totalRounds;
    final int ruleShiftFrequency;
    final Duration speedTarget;

    if (isPractice) {
      totalRounds = 3;
      ruleShiftFrequency = 2;
      speedTarget = const Duration(milliseconds: 2500);
    } else {
      switch (difficulty.name) {
        case 'easy':
          totalRounds = 6;
          ruleShiftFrequency = 3;
          speedTarget = const Duration(milliseconds: 1800);
          break;
        case 'hard':
          totalRounds = 10;
          ruleShiftFrequency = 2;
          speedTarget = const Duration(milliseconds: 1000);
          break;
        case 'expert':
          totalRounds = 12;
          ruleShiftFrequency = 2;
          speedTarget = const Duration(milliseconds: 800);
          break;
        case 'medium':
        default:
          totalRounds = 8;
          ruleShiftFrequency = 3;
          speedTarget = const Duration(milliseconds: 1300);
          break;
      }
    }

    return ReflexForgeConfig(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      difficulty: difficulty,
      totalRounds: totalRounds,
      ruleShiftFrequency: ruleShiftFrequency,
      speedTarget: speedTarget,
      isPractice: isPractice,
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    if (config is ReflexForgeConfig) {
      return ReflexForgeGameEngine(
        config: config,
        scoringRules: scoringRules as ReflexForgeScoringRules,
      );
    }
    return ReflexForgeGameEngine(
      config: ReflexForgeConfig(
        seed: config.seed,
        difficulty: config.difficulty,
        totalRounds: config.totalRounds,
        timeLimit: config.timeLimit,
      ),
      scoringRules: scoringRules as ReflexForgeScoringRules,
    );
  }
}
