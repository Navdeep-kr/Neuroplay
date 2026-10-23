import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Configuration contract for Logic Labyrinth.
@immutable
final class LogicLabyrinthConfig extends GameConfig {
  const LogicLabyrinthConfig({
    required super.seed,
    super.difficulty = GameDifficulty.medium,
    super.totalRounds = 3,
    super.timeLimit,
    this.gridSize = 5,
    this.obstacleCount = 4,
    this.hasCheckpoint = true,
    this.isPractice = false,
  });

  factory LogicLabyrinthConfig.forDifficulty({
    required GameDifficulty difficulty,
    required int seed,
    bool isPractice = false,
  }) {
    if (isPractice) {
      return LogicLabyrinthConfig(
        seed: seed,
        difficulty: difficulty,
        isPractice: true,
        gridSize: 4,
        obstacleCount: 2,
        hasCheckpoint: false,
        totalRounds: 1,
      );
    }

    switch (difficulty) {
      case GameDifficulty.easy:
        return LogicLabyrinthConfig(
          seed: seed,
          difficulty: difficulty,
          gridSize: 4,
          obstacleCount: 2,
          hasCheckpoint: false,
          totalRounds: 3,
        );
      case GameDifficulty.medium:
        return LogicLabyrinthConfig(
          seed: seed,
          difficulty: difficulty,
          gridSize: 5,
          obstacleCount: 4,
          hasCheckpoint: true,
          totalRounds: 3,
        );
      case GameDifficulty.hard:
        return LogicLabyrinthConfig(
          seed: seed,
          difficulty: difficulty,
          gridSize: 6,
          obstacleCount: 7,
          hasCheckpoint: true,
          totalRounds: 3,
        );
      case GameDifficulty.expert:
        return LogicLabyrinthConfig(
          seed: seed,
          difficulty: difficulty,
          gridSize: 7,
          obstacleCount: 11,
          hasCheckpoint: true,
          totalRounds: 3,
        );
    }
    throw ArgumentError('Unsupported difficulty: $difficulty');
  }

  final int gridSize;
  final int obstacleCount;
  final bool hasCheckpoint;
  final bool isPractice;

  @override
  void validate() {
    super.validate();
    if (gridSize < 3 || gridSize > 10) {
      throw GameValidationException(
        'gridSize must be between 3 and 10, got $gridSize',
      );
    }
    if (obstacleCount < 0) {
      throw const GameValidationException('obstacleCount cannot be negative');
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'gridSize': gridSize,
        'obstacleCount': obstacleCount,
        'hasCheckpoint': hasCheckpoint,
        'isPractice': isPractice,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        gridSize,
        obstacleCount,
        hasCheckpoint,
        isPractice,
      ];
}
