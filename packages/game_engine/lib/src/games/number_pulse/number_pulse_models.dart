import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Type of mathematical pattern driving the numerical sequence.
enum SequencePatternType {
  arithmetic('Arithmetic', 'Constant step addition or subtraction'),
  geometric('Geometric', 'Constant ratio multiplication'),
  alternating('Alternating', 'Two repeating interleaved operations'),
  fibonacci('Additive', 'Each term is the sum of previous two terms');

  const SequencePatternType(this.label, this.description);
  final String label;
  final String description;
}

/// A single mental arithmetic question generated for Number Pulse.
@immutable
final class NumberPulseQuestion extends Equatable {
  const NumberPulseQuestion({
    required this.sequence,
    required this.missingIndex,
    required this.correctAnswer,
    required this.options,
    required this.patternType,
    required this.explanation,
  }) : assert(options.length == 4, 'Must provide exactly 4 options');

  factory NumberPulseQuestion.fromJson(Map<String, dynamic> json) {
    return NumberPulseQuestion(
      sequence: (json['sequence'] as List<dynamic>).cast<int>(),
      missingIndex: json['missingIndex'] as int,
      correctAnswer: json['correctAnswer'] as int,
      options: (json['options'] as List<dynamic>).cast<int>(),
      patternType:
          SequencePatternType.values.byName(json['patternType'] as String),
      explanation: json['explanation'] as String,
    );
  }

  /// The numbers in the sequence (the missing value is also in this list).
  final List<int> sequence;

  /// Index in [sequence] where the player must guess the value.
  final int missingIndex;

  /// The true numerical value at [missingIndex].
  final int correctAnswer;

  /// 4 options including 1 correct answer and 3 distractors.
  final List<int> options;

  /// The underlying pattern generator type.
  final SequencePatternType patternType;

  /// Concise pedagogical explanation for the pattern.
  final String explanation;

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'missingIndex': missingIndex,
        'correctAnswer': correctAnswer,
        'options': options,
        'patternType': patternType.name,
        'explanation': explanation,
      };

  @override
  List<Object?> get props => [
        sequence,
        missingIndex,
        correctAnswer,
        options,
        patternType,
        explanation,
      ];
}
