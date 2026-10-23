import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/games/logic_labyrinth/logic_labyrinth_models.dart';
import 'package:meta/meta.dart';

/// Player attempts to step one cell in [direction].
@immutable
final class MoveLabyrinthAction extends GameAction {
  MoveLabyrinthAction({
    required super.timestamp,
    required this.direction,
  }) : super(
          type: 'move_labyrinth',
          payload: {'direction': direction.name},
        );

  final LabyrinthDirection direction;

  @override
  List<Object?> get props => [type, timestamp, direction];
}

/// Player resets position back to start of current maze round.
@immutable
final class ResetCurrentMazeAction extends GameAction {
  ResetCurrentMazeAction({required super.timestamp})
      : super(type: 'reset_current_maze');
}
