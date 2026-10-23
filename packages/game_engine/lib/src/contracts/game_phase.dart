import 'package:game_engine/src/exceptions/game_exceptions.dart';

/// Represents the discrete phases of a game session lifecycle.
enum GamePhase {
  /// Session is initialized with configuration and seed, waiting to start.
  ready,

  /// Pre-game countdown is active (e.g., 3, 2, 1).
  countdown,

  /// Active gameplay is in progress; actions are processed.
  playing,

  /// Active gameplay is temporarily suspended by user or system interruption.
  paused,

  /// Session completed normally (e.g., all rounds or time elapsed).
  completed,

  /// Session was intentionally abandoned or terminated early.
  aborted;

  /// Whether active gameplay is ongoing.
  bool get isActive => this == GamePhase.playing;

  /// Whether the session is in a suspended state.
  bool get isPaused => this == GamePhase.paused;

  /// Whether this is a terminal phase where no more player actions are accepted.
  bool get isTerminal =>
      this == GamePhase.completed || this == GamePhase.aborted;

  /// Whether player gameplay actions can currently be received.
  bool get canAcceptInput => this == GamePhase.playing;

  /// Verifies if transitioning from `this` to [next] is legally permitted.
  bool canTransitionTo(GamePhase next) {
    switch (this) {
      case GamePhase.ready:
        return next == GamePhase.countdown ||
            next == GamePhase.playing ||
            next == GamePhase.aborted;
      case GamePhase.countdown:
        return next == GamePhase.playing ||
            next == GamePhase.paused ||
            next == GamePhase.aborted;
      case GamePhase.playing:
        return next == GamePhase.paused ||
            next == GamePhase.completed ||
            next == GamePhase.aborted;
      case GamePhase.paused:
        return next == GamePhase.playing ||
            next == GamePhase.countdown ||
            next == GamePhase.aborted;
      case GamePhase.completed:
      case GamePhase.aborted:
        return false; // Terminal states cannot transition
    }
  }

  /// Asserts that transitioning to [next] is legal, throwing [GamePhaseException] if not.
  void assertCanTransitionTo(GamePhase next) {
    if (!canTransitionTo(next)) {
      throw GamePhaseException(
        'Illegal phase transition from $name to ${next.name}',
      );
    }
  }

  static GamePhase fromJson(String json) {
    return GamePhase.values.firstWhere(
      (e) => e.name == json,
      orElse: () => throw GameValidationException('Unknown GamePhase: $json'),
    );
  }

  String toJson() => name;
}
