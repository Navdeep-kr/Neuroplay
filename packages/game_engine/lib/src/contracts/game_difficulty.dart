import 'package:equatable/equatable.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Difficulty level for a game run with associated score multipliers.
@immutable
final class GameDifficulty extends Equatable
    implements Comparable<GameDifficulty> {
  const GameDifficulty({
    required this.name,
    required this.displayName,
    required this.multiplier,
    required this.level,
  })  : assert(multiplier > 0, 'Difficulty multiplier must be positive'),
        assert(level >= 0, 'Difficulty level must be non-negative');

  static const easy = GameDifficulty(
    name: 'easy',
    displayName: 'Easy',
    multiplier: 1.0,
    level: 1,
  );

  static const medium = GameDifficulty(
    name: 'medium',
    displayName: 'Medium',
    multiplier: 1.25,
    level: 2,
  );

  static const hard = GameDifficulty(
    name: 'hard',
    displayName: 'Hard',
    multiplier: 1.5,
    level: 3,
  );

  static const expert = GameDifficulty(
    name: 'expert',
    displayName: 'Expert',
    multiplier: 2.0,
    level: 4,
  );

  static const List<GameDifficulty> values = [easy, medium, hard, expert];

  factory GameDifficulty.fromJson(dynamic json) {
    if (json is String) {
      final match =
          values.where((d) => d.name.toLowerCase() == json.toLowerCase());
      if (match.isNotEmpty) return match.first;
      throw GameValidationException('Unknown GameDifficulty name: $json');
    }
    if (json is Map<String, dynamic>) {
      return GameDifficulty(
        name: json['name'] as String,
        displayName: json['displayName'] as String? ?? json['name'] as String,
        multiplier: (json['multiplier'] as num).toDouble(),
        level: json['level'] as int? ?? 1,
      );
    }
    throw GameValidationException('Invalid GameDifficulty format: $json');
  }

  final String name;
  final String displayName;
  final double multiplier;
  final int level;

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'multiplier': multiplier,
        'level': level,
      };

  @override
  int compareTo(GameDifficulty other) => level.compareTo(other.level);

  @override
  List<Object?> get props => [name, multiplier, level];

  @override
  String toString() => 'GameDifficulty($name, x$multiplier)';
}
