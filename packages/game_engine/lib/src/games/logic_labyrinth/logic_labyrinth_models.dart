import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// 2D coordinate on the labyrinth grid.
@immutable
class GridCoordinate extends Equatable {
  const GridCoordinate(this.x, this.y);

  factory GridCoordinate.fromJson(Map<String, dynamic> json) =>
      GridCoordinate(json['x'] as int, json['y'] as int);

  final int x;
  final int y;

  GridCoordinate move(LabyrinthDirection direction) {
    switch (direction) {
      case LabyrinthDirection.up:
        return GridCoordinate(x, y - 1);
      case LabyrinthDirection.down:
        return GridCoordinate(x, y + 1);
      case LabyrinthDirection.left:
        return GridCoordinate(x - 1, y);
      case LabyrinthDirection.right:
        return GridCoordinate(x + 1, y);
    }
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';
}

/// Cardinal move directions.
enum LabyrinthDirection {
  up('Up', 0, -1),
  down('Down', 0, 1),
  left('Left', -1, 0),
  right('Right', 1, 0);

  const LabyrinthDirection(this.label, this.dx, this.dy);
  final String label;
  final int dx;
  final int dy;
}

/// Types of grid cells.
enum CellType {
  path,
  wall,
  start,
  target,
  checkpoint;

  bool get isWalkable => this != wall;
}
