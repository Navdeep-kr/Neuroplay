import 'package:game_engine/src/contracts/game_action.dart';

/// Dispatched when the player selects an option index (0, 1, or 2).
final class SelectReflexOptionAction extends GameAction {
  SelectReflexOptionAction({
    required super.timestamp,
    required this.selectedIndex,
  }) : super(
          type: 'select_option',
          payload: {'selectedIndex': selectedIndex},
        );

  final int selectedIndex;

  @override
  List<Object?> get props => [type, timestamp, selectedIndex];
}
