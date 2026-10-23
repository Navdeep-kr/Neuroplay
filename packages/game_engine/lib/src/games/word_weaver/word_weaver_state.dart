import 'package:equatable/equatable.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_models.dart';
import 'package:meta/meta.dart';

/// State of an individual trial / round in Word Weaver.
@immutable
final class WordWeaverTrialState extends Equatable {
  const WordWeaverTrialState({
    required this.roundIndex,
    required this.question,
    this.selectedWord,
    this.isCorrect,
    this.isAnswered = false,
    this.responseTimeMs,
  });

  factory WordWeaverTrialState.fromJson(Map<String, dynamic> json) {
    return WordWeaverTrialState(
      roundIndex: json['roundIndex'] as int,
      question: WordWeaverQuestion.fromJson(
        json['question'] as Map<String, dynamic>,
      ),
      selectedWord: json['selectedWord'] as String?,
      isCorrect: json['isCorrect'] as bool?,
      isAnswered: json['isAnswered'] as bool? ?? false,
      responseTimeMs: json['responseTimeMs'] as int?,
    );
  }

  final int roundIndex;
  final WordWeaverQuestion question;
  final String? selectedWord;
  final bool? isCorrect;
  final bool isAnswered;
  final int? responseTimeMs;

  WordWeaverTrialState copyWith({
    int? roundIndex,
    WordWeaverQuestion? question,
    String? selectedWord,
    bool? isCorrect,
    bool? isAnswered,
    int? responseTimeMs,
  }) {
    return WordWeaverTrialState(
      roundIndex: roundIndex ?? this.roundIndex,
      question: question ?? this.question,
      selectedWord: selectedWord ?? this.selectedWord,
      isCorrect: isCorrect ?? this.isCorrect,
      isAnswered: isAnswered ?? this.isAnswered,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'roundIndex': roundIndex,
        'question': question.toJson(),
        'selectedWord': selectedWord,
        'isCorrect': isCorrect,
        'isAnswered': isAnswered,
        'responseTimeMs': responseTimeMs,
      };

  @override
  List<Object?> get props => [
        roundIndex,
        question,
        selectedWord,
        isCorrect,
        isAnswered,
        responseTimeMs,
      ];
}
