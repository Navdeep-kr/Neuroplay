import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Configuration contract for Word Weaver.
@immutable
final class WordWeaverConfig extends GameConfig {
  const WordWeaverConfig({
    required super.seed,
    super.difficulty = GameDifficulty.medium,
    super.totalRounds = 5,
    super.timeLimit,
    this.maxDifficultyTier = 2,
    this.isPractice = false,
  });

  factory WordWeaverConfig.forDifficulty({
    required GameDifficulty difficulty,
    required int seed,
    bool isPractice = false,
  }) {
    if (isPractice) {
      return WordWeaverConfig(
        seed: seed,
        difficulty: difficulty,
        isPractice: true,
        maxDifficultyTier: 1,
        totalRounds: 2,
      );
    }

    switch (difficulty) {
      case GameDifficulty.easy:
        return WordWeaverConfig(
          seed: seed,
          difficulty: difficulty,
          maxDifficultyTier: 1,
          totalRounds: 4,
        );
      case GameDifficulty.medium:
        return WordWeaverConfig(
          seed: seed,
          difficulty: difficulty,
          maxDifficultyTier: 2,
          totalRounds: 5,
        );
      case GameDifficulty.hard:
        return WordWeaverConfig(
          seed: seed,
          difficulty: difficulty,
          maxDifficultyTier: 3,
          totalRounds: 6,
        );
      case GameDifficulty.expert:
        return WordWeaverConfig(
          seed: seed,
          difficulty: difficulty,
          maxDifficultyTier: 3,
          totalRounds: 7,
        );
    }
    throw ArgumentError('Unsupported difficulty: $difficulty');
  }

  final int maxDifficultyTier;
  final bool isPractice;

  @override
  void validate() {
    super.validate();
    if (maxDifficultyTier < 1 || maxDifficultyTier > 3) {
      throw GameValidationException(
        'maxDifficultyTier must be between 1 and 3, got $maxDifficultyTier',
      );
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'maxDifficultyTier': maxDifficultyTier,
        'isPractice': isPractice,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        maxDifficultyTier,
        isPractice,
      ];
}
