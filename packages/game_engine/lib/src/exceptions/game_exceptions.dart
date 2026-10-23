/// Base exception for all game engine failures.
abstract class GameException implements Exception {
  const GameException(this.message, [this.details]);

  final String message;
  final Object? details;

  @override
  String toString() {
    if (details != null) {
      return '$runtimeType: $message ($details)';
    }
    return '$runtimeType: $message';
  }
}

/// Thrown when an input, configuration, or state fails validation rules.
class GameValidationException extends GameException {
  const GameValidationException(super.message, [super.details]);
}

/// Thrown when an action cannot be applied to the current game state or phase.
class InvalidActionException extends GameException {
  const InvalidActionException(super.message, [super.details]);
}

/// Thrown when an invalid game phase transition is attempted.
class GamePhaseException extends GameException {
  const GamePhaseException(super.message, [super.details]);
}
