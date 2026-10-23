import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Configuration for a Memory Matrix game run.
final class MemoryMatrixConfig extends GameConfig {
  const MemoryMatrixConfig({
    required super.seed,
    super.difficulty = GameDifficulty.medium,
    super.totalRounds = 5,
    super.timeLimit,
    this.gridSize = 4,
    this.targetCount = 4,
    this.previewDuration = const Duration(milliseconds: 1500),
    this.isPractice = false,
  }) : assert(
          gridSize >= 3 && gridSize <= 6,
          'gridSize must be between 3 and 6',
        );

  /// Size of the grid (e.g. 3 for 3x3, 4 for 4x4, 5 for 5x5).
  final int gridSize;

  /// Number of illuminated tiles to remember per round.
  final int targetCount;

  /// How long the illuminated pattern is visible before recall starts.
  final Duration previewDuration;

  /// Whether this session is run in tutorial / practice mode.
  final bool isPractice;

  int get totalTiles => gridSize * gridSize;

  @override
  void validate() {
    super.validate();
    if (gridSize < 3 || gridSize > 6) {
      throw const GameValidationException('gridSize must be between 3 and 6');
    }
    if (targetCount < 2 || targetCount > totalTiles - 1) {
      throw GameValidationException(
        'targetCount ($targetCount) must be between 2 and ${totalTiles - 1}',
      );
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'gridSize': gridSize,
        'targetCount': targetCount,
        'previewDurationMs': previewDuration.inMilliseconds,
        'isPractice': isPractice,
      };
}
