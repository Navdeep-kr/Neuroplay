import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_config.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_engine.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_scoring.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Specification and blueprint for the Focus Reactor cognitive exercise.
final class FocusReactorDefinition extends GameDefinition {
  FocusReactorDefinition({
    super.scoringRules = const FocusReactorScoringRules(),
  }) : super(
          id: 'focus-reactor',
          name: 'Focus Reactor',
          description:
              'Identify designated target symbols amidst visual distractors or signal absence.',
          category: 'attention',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  FocusReactorConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
    bool isPractice = false,
  }) {
    final int totalRounds;
    final int displaySlots;
    final Duration speedBonusThreshold;

    if (isPractice) {
      totalRounds = 3;
      displaySlots = 3;
      speedBonusThreshold = const Duration(milliseconds: 2500);
    } else {
      switch (difficulty.name) {
        case 'easy':
          totalRounds = 6;
          displaySlots = 3;
          speedBonusThreshold = const Duration(milliseconds: 1800);
          break;
        case 'hard':
          totalRounds = 10;
          displaySlots = 6;
          speedBonusThreshold = const Duration(milliseconds: 1100);
          break;
        case 'expert':
          totalRounds = 12;
          displaySlots = 6;
          speedBonusThreshold = const Duration(milliseconds: 900);
          break;
        case 'medium':
        default:
          totalRounds = 8;
          displaySlots = 4;
          speedBonusThreshold = const Duration(milliseconds: 1400);
          break;
      }
    }

    return FocusReactorConfig(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      difficulty: difficulty,
      totalRounds: totalRounds,
      displaySlots: displaySlots,
      speedBonusThreshold: speedBonusThreshold,
      isPractice: isPractice,
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    if (config is FocusReactorConfig) {
      return FocusReactorGameEngine(
        config: config,
        scoringRules: scoringRules as FocusReactorScoringRules,
      );
    }
    return FocusReactorGameEngine(
      config: FocusReactorConfig(
        seed: config.seed,
        difficulty: config.difficulty,
        totalRounds: config.totalRounds,
        timeLimit: config.timeLimit,
      ),
      scoringRules: scoringRules as FocusReactorScoringRules,
    );
  }
}
