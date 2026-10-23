import 'package:equatable/equatable.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_models.dart';
import 'package:meta/meta.dart';

/// State of an individual trial / round in Number Pulse.
@immutable
final class NumberPulseTrialState extends Equatable {
  const NumberPulseTrialState({
    required this.roundIndex,
    required this.question,
    this.selectedAnswer,
    this.isCorrect,
    this.isAnswered = false,
    this.responseTimeMs,
  });

  factory NumberPulseTrialState.fromJson(Map<String, dynamic> json) {
    return NumberPulseTrialState(
      roundIndex: json['roundIndex'] as int,
      question: NumberPulseQuestion.fromJson(
        json['question'] as Map<String, dynamic>,
      ),
      selectedAnswer: json['selectedAnswer'] as int?,
      isCorrect: json['isCorrect'] as bool?,
      isAnswered: json['isAnswered'] as bool? ?? false,
      responseTimeMs: json['responseTimeMs'] as int?,
    );
  }

  final int roundIndex;
  final NumberPulseQuestion question;
  final int? selectedAnswer;
  final bool? isCorrect;
  final bool isAnswered;
  final int? responseTimeMs;

  NumberPulseTrialState copyWith({
    int? roundIndex,
    NumberPulseQuestion? question,
    int? selectedAnswer,
    bool? isCorrect,
    bool? isAnswered,
    int? responseTimeMs,
  }) {
    return NumberPulseTrialState(
      roundIndex: roundIndex ?? this.roundIndex,
      question: question ?? this.question,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      isAnswered: isAnswered ?? this.isAnswered,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'roundIndex': roundIndex,
        'question': question.toJson(),
        'selectedAnswer': selectedAnswer,
        'isCorrect': isCorrect,
        'isAnswered': isAnswered,
        'responseTimeMs': responseTimeMs,
      };

  @override
  List<Object?> get props => [
        roundIndex,
        question,
        selectedAnswer,
        isCorrect,
        isAnswered,
        responseTimeMs,
      ];
}
