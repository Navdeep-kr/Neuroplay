import 'package:equatable/equatable.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_models.dart';
import 'package:meta/meta.dart';

/// State of an individual round/maze within Logic Labyrinth.
@immutable
final class LogicLabyrinthRoundState extends Equatable {
  const LogicLabyrinthRoundState({
    required this.roundIndex,
    required this.gridSize,
    required this.start,
    required this.target,
    required this.playerPos,
    required this.walls,
    this.checkpoint,
    this.checkpointCollected = false,
    required this.optimalPathLength,
    this.stepCount = 0,
    required this.visitedPath,
    this.isRoundCompleted = false,
    this.bouncedWallCount = 0,
  });

  factory LogicLabyrinthRoundState.fromJson(Map<String, dynamic> json) {
    return LogicLabyrinthRoundState(
      roundIndex: json['roundIndex'] as int,
      gridSize: json['gridSize'] as int,
      start: GridCoordinate.fromJson(json['start'] as Map<String, dynamic>),
      target: GridCoordinate.fromJson(json['target'] as Map<String, dynamic>),
      playerPos:
          GridCoordinate.fromJson(json['playerPos'] as Map<String, dynamic>),
      walls: (json['walls'] as List<dynamic>)
          .map((e) => GridCoordinate.fromJson(e as Map<String, dynamic>))
          .toSet(),
      checkpoint: json['checkpoint'] != null
          ? GridCoordinate.fromJson(json['checkpoint'] as Map<String, dynamic>)
          : null,
      checkpointCollected: json['checkpointCollected'] as bool? ?? false,
      optimalPathLength: json['optimalPathLength'] as int,
      stepCount: json['stepCount'] as int? ?? 0,
      visitedPath: (json['visitedPath'] as List<dynamic>)
          .map((e) => GridCoordinate.fromJson(e as Map<String, dynamic>))
          .toList(),
      isRoundCompleted: json['isRoundCompleted'] as bool? ?? false,
      bouncedWallCount: json['bouncedWallCount'] as int? ?? 0,
    );
  }

  final int roundIndex;
  final int gridSize;
  final GridCoordinate start;
  final GridCoordinate target;
  final GridCoordinate playerPos;
  final Set<GridCoordinate> walls;
  final GridCoordinate? checkpoint;
  final bool checkpointCollected;
  final int optimalPathLength;
  final int stepCount;
  final List<GridCoordinate> visitedPath;
  final bool isRoundCompleted;
  final int bouncedWallCount;

  bool get needsCheckpoint => checkpoint != null && !checkpointCollected;

  LogicLabyrinthRoundState copyWith({
    int? roundIndex,
    int? gridSize,
    GridCoordinate? start,
    GridCoordinate? target,
    GridCoordinate? playerPos,
    Set<GridCoordinate>? walls,
    GridCoordinate? checkpoint,
    bool? checkpointCollected,
    int? optimalPathLength,
    int? stepCount,
    List<GridCoordinate>? visitedPath,
    bool? isRoundCompleted,
    int? bouncedWallCount,
  }) {
    return LogicLabyrinthRoundState(
      roundIndex: roundIndex ?? this.roundIndex,
      gridSize: gridSize ?? this.gridSize,
      start: start ?? this.start,
      target: target ?? this.target,
      playerPos: playerPos ?? this.playerPos,
      walls: walls ?? this.walls,
      checkpoint: checkpoint ?? this.checkpoint,
      checkpointCollected: checkpointCollected ?? this.checkpointCollected,
      optimalPathLength: optimalPathLength ?? this.optimalPathLength,
      stepCount: stepCount ?? this.stepCount,
      visitedPath: visitedPath ?? this.visitedPath,
      isRoundCompleted: isRoundCompleted ?? this.isRoundCompleted,
      bouncedWallCount: bouncedWallCount ?? this.bouncedWallCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'roundIndex': roundIndex,
        'gridSize': gridSize,
        'start': start.toJson(),
        'target': target.toJson(),
        'playerPos': playerPos.toJson(),
        'walls': walls.map((w) => w.toJson()).toList(),
        'checkpoint': checkpoint?.toJson(),
        'checkpointCollected': checkpointCollected,
        'optimalPathLength': optimalPathLength,
        'stepCount': stepCount,
        'visitedPath': visitedPath.map((v) => v.toJson()).toList(),
        'isRoundCompleted': isRoundCompleted,
        'bouncedWallCount': bouncedWallCount,
      };

  @override
  List<Object?> get props => [
        roundIndex,
        gridSize,
        start,
        target,
        playerPos,
        walls,
        checkpoint,
        checkpointCollected,
        optimalPathLength,
        stepCount,
        visitedPath,
        isRoundCompleted,
        bouncedWallCount,
      ];
}
