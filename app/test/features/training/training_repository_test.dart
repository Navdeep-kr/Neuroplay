import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/data/local_training_repository.dart';

GameResult _createTestResult({
  required String gameId,
  int finalScore = 850,
  double accuracy = 0.9,
  bool isPractice = false,
}) =>
    GameResult(
      sessionId: 'session-$gameId',
      gameId: gameId,
      gameVersion: '1.0.0',
      engineVersion: '1.0.0',
      scoringRulesVersion: '1.0.0',
      seed: 42,
      difficulty: GameDifficulty.medium,
      completionPhase: GamePhase.completed,
      finalScore: finalScore,
      scoreBreakdown: ScoreBreakdown(
        rawScore: finalScore,
        accuracyBonus: (accuracy * 100).round(),
        finalScore: finalScore,
      ),
      totalActiveDuration: const Duration(seconds: 60),
      totalActions: 10,
      metrics: {
        'isPractice': isPractice,
        'accuracy': accuracy,
        'errors': 0,
      },
      completedAt: DateTime.now(),
    );

void main() {
  group('LocalTrainingRepository Tests', () {
    late LocalTrainingRepository repo;

    setUp(() {
      repo = LocalTrainingRepository();
    });

    test('initializes today workout and user streak properly', () async {
      final workout = await repo.getTodayWorkout();
      expect(workout.games.length, 3);
      expect(workout.isCompleted, isFalse);

      final streak = await repo.getUserStreak();
      expect(streak.currentStreak, greaterThanOrEqualTo(1));
    });

    test('records game session and updates streak and domain scores', () async {
      final initialStreak = await repo.getUserStreak();
      final workout = await repo.getTodayWorkout();
      final firstGame = workout.games.first;

      final result = _createTestResult(gameId: firstGame.id);

      await repo.recordGameSession(result, workoutId: workout.id);

      final updatedStreak = await repo.getUserStreak();
      expect(
        updatedStreak.totalSessionsCompleted,
        initialStreak.totalSessionsCompleted + 1,
      );

      final scores = await repo.getDomainScores();
      final domainScore =
          scores.firstWhere((s) => s.domain == firstGame.domain);
      expect(domainScore.sampleCount, greaterThan(0));
    });

    test('completing all games in workout marks workout as completed',
        () async {
      final workout = await repo.getTodayWorkout();

      for (final game in workout.games) {
        final result = _createTestResult(
          gameId: game.id,
          finalScore: 800,
          accuracy: 0.85,
        );
        await repo.recordGameSession(result, workoutId: workout.id);
      }

      final updatedWorkout = await repo.getTodayWorkout();
      expect(updatedWorkout.isCompleted, isTrue);

      final streak = await repo.getUserStreak();
      expect(streak.totalWorkoutsCompleted, greaterThanOrEqualTo(1));
    });
  });
}
