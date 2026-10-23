import 'package:game_engine/src/contracts/game_action.dart';
import 'package:meta/meta.dart';

/// Player submits their selected word association guess.
@immutable
final class SelectWordAssociationAction extends GameAction {
  SelectWordAssociationAction({
    required super.timestamp,
    required this.selectedWord,
  }) : super(
          type: 'select_word_association',
          payload: {'selectedWord': selectedWord},
        );

  final String selectedWord;

  @override
  List<Object?> get props => [type, timestamp, selectedWord];
}
