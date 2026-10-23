import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_actions.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_config.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_models.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_scoring.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_solver.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_state.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Pure Dart deterministic state machine for Logic Labyrinth.
final class LogicLabyrinthGameEngine extends GameEngineBase {
  LogicLabyrinthGameEngine({
    required LogicLabyrinthConfig super.config,
    this.scoringRules = const LogicLabyrinthScoringRules(),
  }) : labyrinthConfig = config;

  final LogicLabyrinthConfig labyrinthConfig;
  final LogicLabyrinthScoringRules scoringRules;

  late LogicLabyrinthRoundState roundState;
  int completedMazes = 0;
  int totalStepsTaken = 0;
  int totalOptimalSteps = 0;
  int totalBounces = 0;

  @override
  String get gameId => 'logic-labyrinth';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    _startRound(1);
  }

  void _startRound(int roundNumber) {
    roundState = _generateRound(roundIndex: roundNumber);
    totalOptimalSteps += roundState.optimalPathLength;

    state = state.copyWith(
      currentRound: roundNumber,
      customData: {
        'roundState': roundState.toJson(),
      },
    );
  }

  LogicLabyrinthRoundState _generateRound({required int roundIndex}) {
    final size = labyrinthConfig.gridSize;
    const start = GridCoordinate(0, 0);
    final target = GridCoordinate(size - 1, size - 1);

    // Attempt generation with verified solution up to 100 tries
    for (var attempt = 0; attempt < 100; attempt++) {
      GridCoordinate? checkpoint;
      if (labyrinthConfig.hasCheckpoint) {
        final cx = random.nextIntInRange(1, size - 2);
        final cy = random.nextIntInRange(0, size - 1);
        checkpoint = GridCoordinate(cx, cy);
        if (checkpoint == start || checkpoint == target) {
          checkpoint = GridCoordinate(size ~/ 2, size ~/ 2);
        }
      }

      final walls = <GridCoordinate>{};
      final candidateCount = labyrinthConfig.obstacleCount;
      var placed = 0;
      var safety = 0;

      while (placed < candidateCount && safety < 100) {
        safety++;
        final wx = random.nextInt(size);
        final wy = random.nextInt(size);
        final wall = GridCoordinate(wx, wy);

        if (wall != start &&
            wall != target &&
            wall != checkpoint &&
            !walls.contains(wall)) {
          walls.add(wall);
          placed++;
        }
      }

      // Verify solution with solver
      final solution = LogicLabyrinthSolver.solve(
        gridSize: size,
        start: start,
        target: target,
        walls: walls,
        checkpoint: checkpoint,
      );

      final minSteps = (target.x - start.x) + (target.y - start.y);
      if (solution != null && (solution.length - 1) >= minSteps) {
        return LogicLabyrinthRoundState(
          roundIndex: roundIndex,
          gridSize: size,
          start: start,
          target: target,
          playerPos: start,
          walls: walls,
          checkpoint: checkpoint,
          optimalPathLength: solution.length - 1,
          visitedPath: const [start],
        );
      }
    }

    // Fallback: guaranteed open path around edges
    return LogicLabyrinthRoundState(
      roundIndex: roundIndex,
      gridSize: size,
      start: start,
      target: target,
      playerPos: start,
      walls: const {},
      checkpoint: null,
      optimalPathLength: (size - 1) * 2,
      visitedPath: const [start],
    );
  }

  @override
  GameState processAction(GameState currentState, GameAction action) {
    if (action is ResetCurrentMazeAction) {
      roundState = roundState.copyWith(
        playerPos: roundState.start,
        checkpointCollected: false,
        visitedPath: [roundState.start],
      );
      return currentState.copyWith(
        customData: {
          'roundState': roundState.toJson(),
        },
      );
    }

    if (action is MoveLabyrinthAction) {
      if (roundState.isRoundCompleted) return currentState;

      final nextPos = roundState.playerPos.move(action.direction);

      // 1. Boundary check
      if (nextPos.x < 0 ||
          nextPos.x >= roundState.gridSize ||
          nextPos.y < 0 ||
          nextPos.y >= roundState.gridSize) {
        totalBounces++;
        roundState = roundState.copyWith(
          bouncedWallCount: roundState.bouncedWallCount + 1,
        );
        return currentState.copyWith(
          customData: {
            'roundState': roundState.toJson(),
          },
        );
      }

      // 2. Wall collision check
      if (roundState.walls.contains(nextPos)) {
        totalBounces++;
        roundState = roundState.copyWith(
          bouncedWallCount: roundState.bouncedWallCount + 1,
        );
        return currentState.copyWith(
          customData: {
            'roundState': roundState.toJson(),
          },
        );
      }

      // Move is valid
      totalStepsTaken++;
      final updatedSteps = roundState.stepCount + 1;
      final updatedVisited = [...roundState.visitedPath, nextPos];

      var checkpointCollected = roundState.checkpointCollected;
      if (roundState.checkpoint != null && nextPos == roundState.checkpoint) {
        checkpointCollected = true;
      }

      final reachedTarget = nextPos == roundState.target;
      final canFinishRound = reachedTarget &&
          (roundState.checkpoint == null || checkpointCollected);

      if (canFinishRound) {
        completedMazes++;
        final isLastRound =
            currentState.currentRound >= currentState.totalRounds;

        if (isLastRound) {
          roundState = roundState.copyWith(
            playerPos: nextPos,
            checkpointCollected: checkpointCollected,
            stepCount: updatedSteps,
            visitedPath: updatedVisited,
            isRoundCompleted: true,
          );

          final breakdown = scoringRules.calculateBreakdown(
            completedMazes: completedMazes,
            totalStepsTaken: totalStepsTaken,
            totalOptimalSteps: totalOptimalSteps,
            totalDuration: currentState.elapsedActiveTime,
            difficulty: labyrinthConfig.difficulty,
          );

          return currentState.copyWith(
            phase: GamePhase.completed,
            score: breakdown.finalScore,
            customData: {
              'roundState': roundState.toJson(),
              'completed': true,
            },
          );
        } else {
          final nextRoundNumber = currentState.currentRound + 1;
          _startRound(nextRoundNumber);

          final intermediateBreakdown = scoringRules.calculateBreakdown(
            completedMazes: completedMazes,
            totalStepsTaken: totalStepsTaken,
            totalOptimalSteps: totalOptimalSteps,
            totalDuration: currentState.elapsedActiveTime,
            difficulty: labyrinthConfig.difficulty,
          );

          return state.copyWith(
            score: intermediateBreakdown.finalScore,
          );
        }
      }

      roundState = roundState.copyWith(
        playerPos: nextPos,
        checkpointCollected: checkpointCollected,
        stepCount: updatedSteps,
        visitedPath: updatedVisited,
      );

      return currentState.copyWith(
        customData: {
          'roundState': roundState.toJson(),
        },
      );
    }

    throw InvalidActionException('Unknown action type ${action.type}');
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    final breakdown = scoringRules.calculateBreakdown(
      completedMazes: completedMazes,
      totalStepsTaken: totalStepsTaken,
      totalOptimalSteps: totalOptimalSteps,
      totalDuration: totalActiveDuration,
      difficulty: labyrinthConfig.difficulty,
    );

    final efficiency = totalStepsTaken > 0
        ? (totalOptimalSteps / totalStepsTaken).clamp(0.0, 1.0)
        : 0.0;

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: labyrinthConfig.seed,
      difficulty: labyrinthConfig.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'gridSize': labyrinthConfig.gridSize,
        'completedMazes': completedMazes,
        'totalStepsTaken': totalStepsTaken,
        'totalOptimalSteps': totalOptimalSteps,
        'efficiency': efficiency,
        'bouncedWallCount': totalBounces,
        'isPractice': labyrinthConfig.isPractice,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
