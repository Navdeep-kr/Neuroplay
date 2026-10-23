import 'package:neuroplay/features/training/domain/training_models.dart';

/// Pure domain logic for aggregating domain scores and overall brain indices.
abstract final class CognitiveIndexCalculator {
  /// Computes a normalized 0-100 score index for an exercise attempt.
  ///
  /// Weighting: 70% accuracy + 30% scaled score.
  static int computeSessionIndex({
    required double accuracy,
    required int rawScore,
  }) {
    final clampedAccuracy = accuracy.clamp(0.0, 1.0);
    final accuracyPoints = clampedAccuracy * 70.0;
    final scorePoints = (rawScore / 50.0).clamp(0.0, 30.0);
    final total = (accuracyPoints + scorePoints).round();
    return total.clamp(10, 100);
  }

  /// Updates an existing [DomainScore] with a new session index using an exponential moving average.
  static DomainScore updateDomainScore({
    required DomainScore existing,
    required int sessionIndex,
  }) {
    final updatedIndex =
        (existing.scoreIndex * 0.7 + sessionIndex * 0.3).round().clamp(10, 100);
    final newSampleCount = existing.sampleCount + 1;
    final trend = sessionIndex - existing.scoreIndex;
    final percentile = (updatedIndex + 2).clamp(1, 99);

    return DomainScore(
      domain: existing.domain,
      scoreIndex: updatedIndex,
      trendPercentage: trend,
      percentileRank: percentile,
      sampleCount: newSampleCount,
    );
  }

  /// Calculates overall composite brain index from domain scores.
  static int computeOverallIndex(List<DomainScore> domainScores) {
    if (domainScores.isEmpty) return 50;
    final active = domainScores.where((d) => d.sampleCount > 0).toList();
    if (active.isEmpty) return 50;
    final sum = active.fold<int>(0, (acc, d) => acc + d.scoreIndex);
    return (sum / active.length).round().clamp(10, 100);
  }
}
