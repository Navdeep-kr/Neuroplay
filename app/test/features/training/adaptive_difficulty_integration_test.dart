import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/data/local_training_repository.dart';

void main() {
  group('Adaptive Difficulty Integration Tests', () {
    late LocalTrainingRepository repo;

    setUp(() {
      repo = LocalTrainingRepository();
    });

    test('initial skill estimate starts at calibrated baseline (50.0)',
        () async {
      final skill = await repo.getSkillEstimate('memory-matrix');
      expect(skill.continuousRating, equals(50.0));
      expect(skill.recommendedDifficulty, equals(GameDifficulty.medium));
      expect(skill.sampleCount, equals(0));
      expect(
        SkillEstimate.nonClinicalDisclaimer,
        contains('strictly non-clinical'),
      );
    });

    test(
        'recording valid high-accuracy sessions increases rating and logs adjustments',
        () async {
      final result1 = GameResult(
        sessionId: 'sess-01',
        gameId: 'memory-matrix',
        gameVersion: '1.0.0',
        engineVersion: '1.0.0',
        scoringRulesVersion: '1.0.0',
        seed: 1234,
        difficulty: GameDifficulty.medium,
        completionPhase: GamePhase.completed,
        finalScore: 1200,
        scoreBreakdown: const ScoreBreakdown(
          rawScore: 1000,
          accuracyBonus: 200,
          finalScore: 1200,
        ),
        totalActiveDuration: const Duration(seconds: 45),
        totalActions: 10,
        metrics: {
          'accuracy': 1.0,
          'errors': 0,
          'maxStreak': 5,
        },
        completedAt: DateTime.now(),
      );

      await repo.recordGameSession(result1);

      final updatedSkill = await repo.getSkillEstimate('memory-matrix');
      expect(updatedSkill.sampleCount, equals(1));
      expect(updatedSkill.continuousRating, greaterThan(50.0));
      expect(updatedSkill.consecutiveStrongSessions, equals(1));

      // Check adjustment audit history
      final history =
          await repo.getDifficultyAdjustmentHistory(gameId: 'memory-matrix');
      expect(history.length, equals(1));
      expect(history.first.algorithmVersion, equals('1.0.0'));
      expect(history.first.reason, contains('rating increased'));
    });

    test('practice mode sessions do not modify durable skill ratings',
        () async {
      final initialSkill = await repo.getSkillEstimate('memory-matrix');

      final practiceResult = GameResult(
        sessionId: 'sess-practice',
        gameId: 'memory-matrix',
        gameVersion: '1.0.0',
        engineVersion: '1.0.0',
        scoringRulesVersion: '1.0.0',
        seed: 1234,
        difficulty: GameDifficulty.medium,
        completionPhase: GamePhase.completed,
        finalScore: 1500,
        scoreBreakdown: const ScoreBreakdown(
          rawScore: 1500,
          finalScore: 1500,
        ),
        totalActiveDuration: const Duration(seconds: 60),
        totalActions: 12,
        metrics: {
          'isPractice': true,
          'accuracy': 1.0,
        },
        completedAt: DateTime.now(),
      );

      await repo.recordGameSession(practiceResult);

      final afterPractice = await repo.getSkillEstimate('memory-matrix');
      expect(
        afterPractice.continuousRating,
        equals(initialSkill.continuousRating),
      );
      expect(afterPractice.sampleCount, equals(0));
    });
  });
}
