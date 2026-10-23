import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/training/domain/cognitive_index_calculator.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

void main() {
  group('CognitiveIndexCalculator Unit Tests', () {
    test('computes session index bounded between 10 and 100', () {
      final zeroIndex = CognitiveIndexCalculator.computeSessionIndex(
        accuracy: 0,
        rawScore: 0,
      );
      expect(zeroIndex, 10); // Minimum clamp

      final perfectIndex = CognitiveIndexCalculator.computeSessionIndex(
        accuracy: 1,
        rawScore: 2000,
      );
      expect(perfectIndex, 100);

      final midIndex = CognitiveIndexCalculator.computeSessionIndex(
        accuracy: 0.8,
        rawScore: 750,
      );
      // (0.8 * 70) = 56, (750 / 50) = 15. Total = 71.
      expect(midIndex, 71);
    });

    test('updates domain score with smooth moving average', () {
      const initial = DomainScore(
        domain: CognitiveDomain.memory,
        scoreIndex: 70,
        trendPercentage: 0,
        percentileRank: 72,
        sampleCount: 5,
      );

      final updated = CognitiveIndexCalculator.updateDomainScore(
        existing: initial,
        sessionIndex: 90,
      );

      // (70 * 0.7) + (90 * 0.3) = 49 + 27 = 76
      expect(updated.scoreIndex, 76);
      expect(updated.sampleCount, 6);
      expect(updated.trendPercentage, 20); // 90 - 70
      expect(updated.percentileRank, 78);
    });

    test('computes overall composite brain index across active domains', () {
      final domains = [
        const DomainScore(
          domain: CognitiveDomain.memory,
          scoreIndex: 80,
          trendPercentage: 2,
          percentileRank: 82,
          sampleCount: 4,
        ),
        const DomainScore(
          domain: CognitiveDomain.flexibility,
          scoreIndex: 70,
          trendPercentage: 0,
          percentileRank: 72,
          sampleCount: 3,
        ),
        const DomainScore(
          domain: CognitiveDomain.attention,
          scoreIndex: 90,
          trendPercentage: 4,
          percentileRank: 92,
          sampleCount: 5,
        ),
      ];

      // Average of 80, 70, 90 is 80
      final overall = CognitiveIndexCalculator.computeOverallIndex(domains);
      expect(overall, 80);
    });

    test('returns default 50 if no domains have samples', () {
      final domains = [
        const DomainScore(
          domain: CognitiveDomain.memory,
          scoreIndex: 50,
          trendPercentage: 0,
          percentileRank: 50,
        ),
      ];

      final overall = CognitiveIndexCalculator.computeOverallIndex(domains);
      expect(overall, 50);
    });
  });
}
