import 'package:game_engine/src/contracts/game_action.dart';
import 'package:meta/meta.dart';

/// Player submits a numerical guess for the active Number Pulse question.
@immutable
final class SelectNumberPulseAnswerAction extends GameAction {
  SelectNumberPulseAnswerAction({
    required super.timestamp,
    required this.selectedAnswer,
  }) : super(
          type: 'select_number_pulse_answer',
          payload: {'selectedAnswer': selectedAnswer},
        );

  final int selectedAnswer;

  @override
  List<Object?> get props => [type, timestamp, selectedAnswer];
}
