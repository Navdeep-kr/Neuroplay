import 'package:equatable/equatable.dart';

/// Phase within an individual Memory Matrix round.
enum MemoryMatrixRoundPhase {
  /// Target pattern is shown to the user.
  memorize,

  /// Pattern is hidden; player taps tiles to recall positions.
  recall,

  /// Round feedback is displayed before next round begins.
  feedback,
}

/// Specialized round state payload for Memory Matrix.
final class MemoryMatrixRoundState extends Equatable {
  const MemoryMatrixRoundState({
    required this.roundPhase,
    required this.targetIndices,
    required this.selectedCorrectIndices,
    required this.selectedMistakeIndices,
    this.roundCompletedSuccessfully = false,
  });

  final MemoryMatrixRoundPhase roundPhase;
  final List<int> targetIndices;
  final Set<int> selectedCorrectIndices;
  final Set<int> selectedMistakeIndices;
  final bool roundCompletedSuccessfully;

  bool get isMemorizing => roundPhase == MemoryMatrixRoundPhase.memorize;
  bool get isRecalling => roundPhase == MemoryMatrixRoundPhase.recall;
  bool get isFeedback => roundPhase == MemoryMatrixRoundPhase.feedback;

  int get remainingTargets =>
      targetIndices.length - selectedCorrectIndices.length;

  MemoryMatrixRoundState copyWith({
    MemoryMatrixRoundPhase? roundPhase,
    List<int>? targetIndices,
    Set<int>? selectedCorrectIndices,
    Set<int>? selectedMistakeIndices,
    bool? roundCompletedSuccessfully,
  }) {
    return MemoryMatrixRoundState(
      roundPhase: roundPhase ?? this.roundPhase,
      targetIndices: targetIndices ?? this.targetIndices,
      selectedCorrectIndices:
          selectedCorrectIndices ?? this.selectedCorrectIndices,
      selectedMistakeIndices:
          selectedMistakeIndices ?? this.selectedMistakeIndices,
      roundCompletedSuccessfully:
          roundCompletedSuccessfully ?? this.roundCompletedSuccessfully,
    );
  }

  Map<String, dynamic> toJson() => {
        'roundPhase': roundPhase.name,
        'targetIndices': targetIndices,
        'selectedCorrect': selectedCorrectIndices.toList(),
        'selectedMistakes': selectedMistakeIndices.toList(),
        'roundCompletedSuccessfully': roundCompletedSuccessfully,
      };

  @override
  List<Object?> get props => [
        roundPhase,
        targetIndices,
        selectedCorrectIndices,
        selectedMistakeIndices,
        roundCompletedSuccessfully,
      ];
}
