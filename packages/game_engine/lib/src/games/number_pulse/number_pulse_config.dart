import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Configuration contract for Number Pulse.
@immutable
final class NumberPulseConfig extends GameConfig {
  const NumberPulseConfig({
    required super.seed,
    super.difficulty = GameDifficulty.medium,
    super.totalRounds = 5,
    super.timeLimit,
    this.sequenceLength = 5,
    this.allowedPatterns = const [
      'arithmetic',
      'geometric',
      'alternating',
      'fibonacci',
    ],
    this.isPractice = false,
  });

  factory NumberPulseConfig.forDifficulty({
    required GameDifficulty difficulty,
    required int seed,
    bool isPractice = false,
  }) {
    if (isPractice) {
      return NumberPulseConfig(
        seed: seed,
        difficulty: difficulty,
        isPractice: true,
        sequenceLength: 4,
        totalRounds: 2,
        allowedPatterns: const ['arithmetic'],
      );
    }

    switch (difficulty) {
      case GameDifficulty.easy:
        return NumberPulseConfig(
          seed: seed,
          difficulty: difficulty,
          sequenceLength: 4,
          totalRounds: 5,
          allowedPatterns: const ['arithmetic', 'alternating'],
        );
      case GameDifficulty.medium:
        return NumberPulseConfig(
          seed: seed,
          difficulty: difficulty,
          sequenceLength: 5,
          totalRounds: 5,
          allowedPatterns: const ['arithmetic', 'geometric', 'alternating'],
        );
      case GameDifficulty.hard:
        return NumberPulseConfig(
          seed: seed,
          difficulty: difficulty,
          sequenceLength: 5,
          totalRounds: 6,
          allowedPatterns: const [
            'arithmetic',
            'geometric',
            'alternating',
            'fibonacci',
          ],
        );
      case GameDifficulty.expert:
        return NumberPulseConfig(
          seed: seed,
          difficulty: difficulty,
          sequenceLength: 6,
          totalRounds: 7,
          allowedPatterns: const [
            'arithmetic',
            'geometric',
            'alternating',
            'fibonacci',
          ],
        );
    }
    throw ArgumentError('Unsupported difficulty: $difficulty');
  }

  final int sequenceLength;
  final List<String> allowedPatterns;
  final bool isPractice;

  @override
  void validate() {
    super.validate();
    if (sequenceLength < 3 || sequenceLength > 8) {
      throw GameValidationException(
        'sequenceLength must be between 3 and 8, got $sequenceLength',
      );
    }
    if (allowedPatterns.isEmpty) {
      throw const GameValidationException('allowedPatterns cannot be empty');
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'sequenceLength': sequenceLength,
        'allowedPatterns': allowedPatterns,
        'isPractice': isPractice,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        sequenceLength,
        allowedPatterns,
        isPractice,
      ];
}
