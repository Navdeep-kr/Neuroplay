import 'package:equatable/equatable.dart';
import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/scoring_rules.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/session/game_engine_base.dart';
import 'package:meta/meta.dart';

/// Specification and metadata blueprint for a cognitive game.
@immutable
abstract class GameDefinition extends Equatable {
  GameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.version,
    required this.scoringRules,
    this.minimumEngineVersion = GameEngineVersion.current,
  }) {
    _validate();
  }

  /// Stable unique identifier (e.g. 'reaction-time', 'stroop-clash').
  final String id;

  /// Human-readable game title.
  final String name;

  /// Short explanation of cognitive rules and objectives.
  final String description;

  /// Cognitive category (e.g. 'attention', 'memory', 'speed', 'flexibility').
  final String category;

  /// Explicit version of this game's rules and stimuli configuration.
  final GameEngineVersion version;

  /// Minimum framework engine version required to execute this game.
  final GameEngineVersion minimumEngineVersion;

  /// Scoring calculation rules for this game.
  final ScoringRules scoringRules;

  void _validate() {
    if (id.trim().isEmpty) {
      throw const GameValidationException('GameDefinition id cannot be empty');
    }
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw GameValidationException(
        'GameDefinition id must be lowercase alphanumeric with hyphens, got: $id',
      );
    }
  }

  /// Generates a valid default configuration for this game.
  GameConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
  });

  /// Factory creating an executable, headless game engine instance.
  GameEngineBase createEngine({required GameConfig config});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'version': version.toString(),
        'minimumEngineVersion': minimumEngineVersion.toString(),
        'scoringRules': scoringRules.toJson(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        version,
        minimumEngineVersion,
        scoringRules,
      ];
}
