import 'dart:async';
import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_config.dart';
import 'package:game_engine/src/contracts/game_definition.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/session/game_engine_base.dart';
import 'package:game_engine/src/timing/monotonic_clock.dart';

/// Active runtime session controller binding monotonic timing, action dispatching,
/// state reactivity, and deterministic result synthesis.
class GameSession {
  GameSession({
    required this.id,
    required this.definition,
    required this.config,
    PausableMonotonicClock? clock,
  })  : clock = clock ?? PausableMonotonicClock(),
        engine = definition.createEngine(config: config),
        _actionHistory = [] {
    if (id.trim().isEmpty) {
      throw const GameValidationException('GameSession id cannot be empty');
    }
    _stateController = StreamController<GameState>.broadcast(
      onListen: () => _stateController.add(engine.state),
    );
  }

  /// Unique session identifier (UUID).
  final String id;

  /// Game specification blueprint.
  final GameDefinition definition;

  /// Configuration and seed.
  final GameConfig config;

  /// Monotonic elapsed time clock.
  final PausableMonotonicClock clock;

  /// Underlying headless state machine.
  final GameEngineBase engine;

  final List<GameAction> _actionHistory;
  late final StreamController<GameState> _stateController;
  bool _isDisposed = false;

  /// Current game state snapshot.
  GameState get state => engine.state;

  /// Monotonic active gameplay duration (excludes pauses).
  Duration get activeDuration => clock.elapsedActiveTime;

  /// Chronological audit log of valid actions accepted during this session.
  List<GameAction> get actionHistory => List.unmodifiable(_actionHistory);

  /// Broadcast stream of state changes.
  Stream<GameState> get stateStream => _stateController.stream;

  /// Whether the session has completed or been aborted.
  bool get isFinished => engine.state.isTerminal;

  /// Starts the game and starts the monotonic active clock.
  void start() {
    _assertNotDisposed();
    clock.start();
    final action = StartGameAction(timestamp: clock.elapsedActiveTime);
    _applyAction(action);
  }

  /// Dispatches a player or game action, setting its monotonic timestamp.
  bool dispatch(GameAction action) {
    _assertNotDisposed();
    if (state.isTerminal) {
      throw const InvalidActionException(
        'Cannot dispatch actions to a finalized game session',
      );
    }

    final timestampedAction = action.timestamp == Duration.zero
        ? _rebindTimestamp(action, clock.elapsedActiveTime)
        : action;

    return _applyAction(timestampedAction);
  }

  /// Temporarily suspends gameplay and freezes monotonic active timing.
  ///
  /// Can be triggered by the user pausing or by OS lifecycle events
  /// (e.g. app moving to background, incoming phone call).
  void pause({String? reason}) {
    _assertNotDisposed();
    if (state.phase != GamePhase.playing &&
        state.phase != GamePhase.countdown) {
      return;
    }
    clock.pause();
    final action = PauseGameAction(
      timestamp: clock.elapsedActiveTime,
      reason: reason,
    );
    _applyAction(action);
  }

  /// Resumes gameplay and monotonic active timing after pause or app return.
  void resume() {
    _assertNotDisposed();
    if (state.phase != GamePhase.paused) return;
    clock.start();
    final action = ResumeGameAction(timestamp: clock.elapsedActiveTime);
    _applyAction(action);
  }

  /// Aborts gameplay and terminates the session early.
  void abort({String? reason}) {
    _assertNotDisposed();
    if (state.isTerminal) return;
    clock.pause();
    final action = AbortGameAction(
      timestamp: clock.elapsedActiveTime,
      reason: reason,
    );
    _applyAction(action);
  }

  /// Finalizes the session and computes the validated [GameResult].
  GameResult finish({bool isOffline = false}) {
    _assertNotDisposed();
    if (!state.isTerminal) {
      // Force completion if finishing while playing
      engine.state = engine.state.copyWith(
        phase: GamePhase.completed,
        elapsedActiveTime: clock.elapsedActiveTime,
      );
      clock.pause();
    }

    return engine.computeResult(
      sessionId: id,
      totalActiveDuration: clock.elapsedActiveTime,
      totalActions: _actionHistory.length,
      isOffline: isOffline,
    );
  }

  /// Releases resources and stream listeners.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    clock.pause();
    _stateController.close();
  }

  bool _applyAction(GameAction action) {
    final applied = engine.dispatch(action);
    if (applied) {
      _actionHistory.add(action);
      if (!_stateController.isClosed) {
        _stateController.add(engine.state);
      }
    }
    return applied;
  }

  GameAction _rebindTimestamp(GameAction original, Duration newTimestamp) {
    if (original is RespondAction) {
      return RespondAction(
        timestamp: newTimestamp,
        responseValue: original.responseValue,
        targetId: original.targetId,
      );
    }
    return original;
  }

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw const GameValidationException('GameSession has been disposed');
    }
  }
}
