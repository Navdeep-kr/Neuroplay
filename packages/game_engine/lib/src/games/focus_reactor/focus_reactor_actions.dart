import 'package:game_engine/src/contracts/game_action.dart';

/// Dispatched when the player selects a specific item slot.
final class SelectFocusSlotAction extends GameAction {
  SelectFocusSlotAction({
    required super.timestamp,
    required this.slotIndex,
  }) : super(
          type: 'select_focus_slot',
          payload: {'slotIndex': slotIndex},
        );

  final int slotIndex;

  @override
  List<Object?> get props => [type, timestamp, slotIndex];
}

/// Dispatched when the player declares that the target is absent from the array.
final class SelectNoTargetAction extends GameAction {
  SelectNoTargetAction({required super.timestamp})
      : super(
          type: 'select_no_target',
        );
}
