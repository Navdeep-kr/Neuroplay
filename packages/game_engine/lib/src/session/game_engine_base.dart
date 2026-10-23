import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/randomness/seeded_random.dart';
import 'package:meta/meta.dart';

/// Abstract deterministic state machine underlying a cognitive game.
///
/// Implementations MUST be pure Dart and have zero dependencies on Flutter
/// or UI presentation code. For an identical [config.seed] and identical
/// sequence of [GameAction] inputs, the state transitions MUST be 100% deterministic.
abstract class GameEngineBase {
  GameEngineBase({
    required this.config,
  })  : random = SeededRandom(config.seed),
        state = GameState(
          phase: GamePhase.ready,
          currentRound: 0,
          totalRounds: config.totalRounds,
          score: 0,
          elapsedActiveTime: Duration.zero,
        ) {
    config.validate();
  }

  /// Initial configuration and seed.
  final GameConfig config;

  /// Deterministic pseudo-random generator seeded from [config.seed].
  final SeededRandom random;

  /// Current state snapshot.
  GameState state;

  /// Associated game definition ID.
  String get gameId;

  /// Associated game definition version.
  String get gameVersion;

  /// Associated scoring rules version.
  String get scoringRulesVersion;

  /// Evaluates an incoming player action, updates [state], and returns true if applied.
  ///
  /// Rejects actions safely if invalid in the current phase or if input validation fails.
  bool dispatch(GameAction action) {
    if (state.isTerminal) {
      throw const InvalidActionException(
        'Cannot dispatch actions to a terminal session (completed or aborted)',
      );
    }

    if (action is StartGameAction) {
      if (state.phase != GamePhase.ready &&
          state.phase != GamePhase.countdown) {
        throw InvalidActionException(
          'Start action is invalid in current phase: ${state.phase.name}',
        );
      }
      state = state.copyWith(
        phase: GamePhase.playing,
        currentRound: state.currentRound == 0 ? 1 : state.currentRound,
        elapsedActiveTime: action.timestamp,
      );
      onGameStarted();
      return true;
    }

    if (action is PauseGameAction) {
      if (state.phase != GamePhase.playing &&
          state.phase != GamePhase.countdown) {
        throw InvalidActionException(
          'Pause action is invalid in non-active phase: ${state.phase.name}',
        );
      }
      state = state.copyWith(
        phase: GamePhase.paused,
        elapsedActiveTime: action.timestamp,
      );
      return true;
    }

    if (action is ResumeGameAction) {
      if (state.phase != GamePhase.paused) {
        throw InvalidActionException(
          'Resume action is invalid when not paused: ${state.phase.name}',
        );
      }
      state = state.copyWith(
        phase: GamePhase.playing,
        elapsedActiveTime: action.timestamp,
      );
      return true;
    }

    if (action is AbortGameAction) {
      state = state.copyWith(
        phase: GamePhase.aborted,
        elapsedActiveTime: action.timestamp,
      );
      return true;
    }

    // Must be in playing phase to process game-specific input
    if (!state.phase.canAcceptInput) {
      return false;
    }

    final previousState = state;
    final nextState = processAction(state, action);
    state = nextState.copyWith(elapsedActiveTime: action.timestamp);

    return state != previousState;
  }

  /// Hook called once when game transitions into [GamePhase.playing].
  @protected
  void onGameStarted() {}

  /// Game-specific deterministic state transition logic.
  ///
  /// Must return the new [GameState] or throw [InvalidActionException] / [GameValidationException].
  @protected
  GameState processAction(GameState currentState, GameAction action);

  /// Computes the validated [GameResult] upon session termination.
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  });
}
