import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Logic Labyrinth Engine Unit Tests', () {
    late LogicLabyrinthDefinition definition;

    setUp(() {
      definition = LogicLabyrinthDefinition();
    });

    test('BFS solver computes verified shortest path correctly', () {
      const start = GridCoordinate(0, 0);
      const target = GridCoordinate(2, 2);
      final walls = {
        const GridCoordinate(1, 0),
        const GridCoordinate(1, 1),
      };

      final path = LogicLabyrinthSolver.solve(
        gridSize: 3,
        start: start,
        target: target,
        walls: walls,
      );

      expect(path, isNotNull);
      expect(path!.first, equals(start));
      expect(path.last, equals(target));
      // Path must go around the wall: (0,0) -> (0,1) -> (0,2) -> (1,2) -> (2,2)
      expect(path.length, equals(5));
      for (final step in path) {
        expect(walls.contains(step), isFalse);
      }
    });

    test('BFS solver enforces visiting checkpoint before target', () {
      const start = GridCoordinate(0, 0);
      const checkpoint = GridCoordinate(0, 2);
      const target = GridCoordinate(2, 2);
      final walls = {const GridCoordinate(1, 1)};

      final path = LogicLabyrinthSolver.solve(
        gridSize: 3,
        start: start,
        target: target,
        walls: walls,
        checkpoint: checkpoint,
      );

      expect(path, isNotNull);
      expect(path!.contains(checkpoint), isTrue);
      final cpIndex = path.indexOf(checkpoint);
      final targetIndex = path.indexOf(target);
      expect(cpIndex < targetIndex, isTrue);
    });

    test('generates deterministic maze layout for a given seed', () {
      final configA = definition.createDefaultConfig(
        seed: 4242,
        difficulty: GameDifficulty.medium,
      );
      final configB = definition.createDefaultConfig(
        seed: 4242,
        difficulty: GameDifficulty.medium,
      );

      final engineA =
          definition.createEngine(config: configA) as LogicLabyrinthGameEngine;
      final engineB =
          definition.createEngine(config: configB) as LogicLabyrinthGameEngine;

      engineA.dispatch(const StartGameAction(timestamp: Duration.zero));
      engineB.dispatch(const StartGameAction(timestamp: Duration.zero));

      expect(engineA.roundState.gridSize, equals(engineB.roundState.gridSize));
      expect(engineA.roundState.walls, equals(engineB.roundState.walls));
      expect(
        engineA.roundState.checkpoint,
        equals(engineB.roundState.checkpoint),
      );
      expect(
        engineA.roundState.optimalPathLength,
        equals(engineB.roundState.optimalPathLength),
      );
    });

    test('rejects out of bounds and wall moves safely without throwing', () {
      final config = definition.createDefaultConfig(
        seed: 100,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as LogicLabyrinthGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      expect(engine.roundState.playerPos, equals(const GridCoordinate(0, 0)));

      // Moving Up or Left from (0,0) is out of bounds
      engine.dispatch(
        MoveLabyrinthAction(
          timestamp: const Duration(milliseconds: 100),
          direction: LabyrinthDirection.up,
        ),
      );
      expect(engine.roundState.playerPos, equals(const GridCoordinate(0, 0)));
      expect(engine.roundState.bouncedWallCount, equals(1));

      engine.dispatch(
        MoveLabyrinthAction(
          timestamp: const Duration(milliseconds: 200),
          direction: LabyrinthDirection.left,
        ),
      );
      expect(engine.roundState.playerPos, equals(const GridCoordinate(0, 0)));
      expect(engine.roundState.bouncedWallCount, equals(2));
    });

    test('reset action returns player to starting position', () {
      final config = definition.createDefaultConfig(
        seed: 100,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as LogicLabyrinthGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      // Make a valid move if possible
      final start = engine.roundState.playerPos;
      var moved = false;
      for (final dir in [LabyrinthDirection.right, LabyrinthDirection.down]) {
        final target = start.move(dir);
        if (!engine.roundState.walls.contains(target)) {
          engine.dispatch(
            MoveLabyrinthAction(
              timestamp: const Duration(milliseconds: 100),
              direction: dir,
            ),
          );
          moved = true;
          break;
        }
      }

      if (moved) {
        expect(engine.roundState.playerPos, isNot(equals(start)));
        engine.dispatch(
          ResetCurrentMazeAction(
            timestamp: const Duration(milliseconds: 300),
          ),
        );
        expect(engine.roundState.playerPos, equals(start));
        expect(engine.roundState.visitedPath, equals([start]));
      }
    });

    test('playing optimal path finishes round and computes valid GameResult',
        () {
      const config = LogicLabyrinthConfig(
        seed: 777,
        difficulty: GameDifficulty.easy,
        totalRounds: 1,
        gridSize: 4,
        obstacleCount: 1,
        hasCheckpoint: false,
      );

      final engine =
          definition.createEngine(config: config) as LogicLabyrinthGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      // Find solution using solver
      final solution = LogicLabyrinthSolver.solve(
        gridSize: engine.roundState.gridSize,
        start: engine.roundState.start,
        target: engine.roundState.target,
        walls: engine.roundState.walls,
      );

      expect(solution, isNotNull);
      var currentPos = engine.roundState.start;

      for (var i = 1; i < solution!.length; i++) {
        final nextPos = solution[i];
        final dx = nextPos.x - currentPos.x;
        final dy = nextPos.y - currentPos.y;

        final LabyrinthDirection dir;
        if (dx == 1) {
          dir = LabyrinthDirection.right;
        } else if (dx == -1) {
          dir = LabyrinthDirection.left;
        } else if (dy == 1) {
          dir = LabyrinthDirection.down;
        } else {
          dir = LabyrinthDirection.up;
        }

        engine.dispatch(
          MoveLabyrinthAction(
            timestamp: Duration(milliseconds: i * 200),
            direction: dir,
          ),
        );
        currentPos = nextPos;
      }

      expect(engine.state.phase, equals(GamePhase.completed));
      expect(engine.completedMazes, equals(1));
      expect(engine.state.score, isPositive);

      final result = engine.computeResult(
        sessionId: 'test-session',
        totalActiveDuration: const Duration(seconds: 15),
        totalActions: engine.totalStepsTaken,
      );

      expect(result.gameId, equals('logic-labyrinth'));
      expect(result.finalScore, isPositive);
      expect(result.metrics['completedMazes'], equals(1));
      expect(result.metrics['efficiency'], greaterThan(0.99));
    });
  });
}
