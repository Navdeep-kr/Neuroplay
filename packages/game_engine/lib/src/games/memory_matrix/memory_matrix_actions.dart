import 'package:game_engine/src/contracts/game_action.dart';

/// Dispatched when the pattern preview period concludes and recall begins.
final class BeginRecallAction extends GameAction {
  BeginRecallAction({required super.timestamp}) : super(type: 'begin_recall');
}

/// Dispatched when player taps or activates a tile in the grid.
final class SelectTileAction extends GameAction {
  SelectTileAction({
    required super.timestamp,
    required this.tileIndex,
  }) : super(
          type: 'select_tile',
          payload: {'tileIndex': tileIndex},
        );

  final int tileIndex;

  @override
  List<Object?> get props => [type, timestamp, tileIndex];
}
