import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_config.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_engine.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_scoring.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Specification and blueprint for the Word Weaver cognitive game.
final class WordWeaverDefinition extends GameDefinition {
  WordWeaverDefinition({
    super.scoringRules = const WordWeaverScoringRules(),
  }) : super(
          id: 'word-weaver',
          name: 'Word Weaver',
          description:
              'Rapid semantic association and vocabulary organization under cognitive load.',
          category: 'memory',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  WordWeaverConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
    bool isPractice = false,
  }) {
    return WordWeaverConfig.forDifficulty(
      difficulty: difficulty,
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      isPractice: isPractice,
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    if (config is WordWeaverConfig) {
      return WordWeaverGameEngine(
        config: config,
        scoringRules: scoringRules as WordWeaverScoringRules,
      );
    }
    return WordWeaverGameEngine(
      config: WordWeaverConfig(
        seed: config.seed,
        difficulty: config.difficulty,
        totalRounds: config.totalRounds,
        timeLimit: config.timeLimit,
      ),
      scoringRules: scoringRules as WordWeaverScoringRules,
    );
  }
}
