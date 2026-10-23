import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_config.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_engine.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_scoring.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Specification and blueprint for the Memory Matrix cognitive game.
final class MemoryMatrixDefinition extends GameDefinition {
  MemoryMatrixDefinition({
    super.scoringRules = const MemoryMatrixScoringRules(),
  }) : super(
          id: 'memory-matrix',
          name: 'Memory Matrix',
          description:
              'Memorize and accurately reproduce spatial tile patterns.',
          category: 'memory',
          version: const GameEngineVersion(1, 0, 0),
        );

  @override
  MemoryMatrixConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
    bool isPractice = false,
  }) {
    final int gridSize;
    final int targetCount;
    final Duration previewDuration;

    if (isPractice) {
      gridSize = 3;
      targetCount = 3;
      previewDuration = const Duration(milliseconds: 2500);
    } else {
      switch (difficulty.name) {
        case 'easy':
          gridSize = 3;
          targetCount = 3;
          previewDuration = const Duration(milliseconds: 2000);
          break;
        case 'hard':
          gridSize = 5;
          targetCount = 5;
          previewDuration = const Duration(milliseconds: 1200);
          break;
        case 'expert':
          gridSize = 5;
          targetCount = 6;
          previewDuration = const Duration(milliseconds: 1000);
          break;
        case 'medium':
        default:
          gridSize = 4;
          targetCount = 4;
          previewDuration = const Duration(milliseconds: 1500);
          break;
      }
    }

    return MemoryMatrixConfig(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      difficulty: difficulty,
      totalRounds: isPractice ? 2 : 5,
      gridSize: gridSize,
      targetCount: targetCount,
      previewDuration: previewDuration,
      isPractice: isPractice,
    );
  }

  @override
  GameEngineBase createEngine({required GameConfig config}) {
    if (config is MemoryMatrixConfig) {
      return MemoryMatrixGameEngine(
        config: config,
        scoringRules: scoringRules as MemoryMatrixScoringRules,
      );
    }
    return MemoryMatrixGameEngine(
      config: MemoryMatrixConfig(
        seed: config.seed,
        difficulty: config.difficulty,
        totalRounds: config.totalRounds,
        timeLimit: config.timeLimit,
      ),
      scoringRules: scoringRules as MemoryMatrixScoringRules,
    );
  }
}
