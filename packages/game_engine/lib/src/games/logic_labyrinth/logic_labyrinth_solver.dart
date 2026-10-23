import 'dart:collection';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_models.dart';

/// Solver and solution verifier for Logic Labyrinth puzzles using BFS.
abstract final class LogicLabyrinthSolver {
  /// Solves the shortest path from [start] to [target] on a grid of [gridSize],
  /// avoiding [walls] and visiting [checkpoint] first if provided.
  ///
  /// Returns the ordered list of coordinates from start to target, or null if unsolvable.
  static List<GridCoordinate>? solve({
    required int gridSize,
    required GridCoordinate start,
    required GridCoordinate target,
    required Set<GridCoordinate> walls,
    GridCoordinate? checkpoint,
  }) {
    if (checkpoint != null) {
      // 1. Solve start -> checkpoint
      final pathToCp = _bfs(
        gridSize: gridSize,
        from: start,
        to: checkpoint,
        walls: walls,
      );
      if (pathToCp == null) return null;

      // 2. Solve checkpoint -> target
      final pathToTarget = _bfs(
        gridSize: gridSize,
        from: checkpoint,
        to: target,
        walls: walls,
      );
      if (pathToTarget == null) return null;

      // Combine paths (excluding duplicate checkpoint node)
      return [...pathToCp, ...pathToTarget.sublist(1)];
    } else {
      return _bfs(
        gridSize: gridSize,
        from: start,
        to: target,
        walls: walls,
      );
    }
  }

  static List<GridCoordinate>? _bfs({
    required int gridSize,
    required GridCoordinate from,
    required GridCoordinate to,
    required Set<GridCoordinate> walls,
  }) {
    if (from == to) return [from];

    final queue = Queue<GridCoordinate>()..add(from);
    final visited = <GridCoordinate>{from};
    final parentMap = <GridCoordinate, GridCoordinate>{};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == to) {
        // Reconstruct path
        final path = <GridCoordinate>[current];
        var curr = current;
        while (parentMap.containsKey(curr)) {
          curr = parentMap[curr]!;
          path.insert(0, curr);
        }
        return path;
      }

      for (final dir in LabyrinthDirection.values) {
        final next = current.move(dir);

        // Check boundaries
        if (next.x < 0 ||
            next.x >= gridSize ||
            next.y < 0 ||
            next.y >= gridSize) {
          continue;
        }

        // Check wall and visited
        if (walls.contains(next) || visited.contains(next)) {
          continue;
        }

        visited.add(next);
        parentMap[next] = current;
        queue.add(next);
      }
    }

    return null; // No path found
  }
}
