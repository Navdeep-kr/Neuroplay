import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

GameResult _createTestResult({
  required String gameId,
  int finalScore = 750,
  double accuracy = 0.85,
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
        'isPractice': false,
        'accuracy': accuracy,
        'errors': 0,
      },
      completedAt: DateTime.now(),
    );

void main() {
  group('WorkoutSessionController Unit Tests', () {
    test('initializes and steps through daily workout playlist sequentially',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workout =
          WorkoutGenerator.generateDailyWorkout(DateTime(2026, 10, 23));
      final notifier = container.read(workoutSessionProvider.notifier);

      expect(container.read(workoutSessionProvider), isNull);

      notifier.startWorkout(workout);

      final state1 = container.read(workoutSessionProvider);
      expect(state1, isNotNull);
      expect(state1!.currentGameIndex, 0);
      expect(state1.currentStep, 1);
      expect(state1.totalGames, 3);
      expect(state1.currentGame?.id, workout.games[0].id);
      expect(state1.nextGame?.id, workout.games[1].id);
      expect(state1.isCompleted, isFalse);

      // Record first game result
      final result1 =
          _createTestResult(gameId: workout.games[0].id, finalScore: 700);
      await notifier.recordGameResult(result1);

      final stateAfterGame1 = container.read(workoutSessionProvider);
      expect(stateAfterGame1!.completedResults.length, 1);
      expect(stateAfterGame1.isCompleted, isFalse);

      // Advance to Game 2
      final nextGame = notifier.advanceToNextGame();
      expect(nextGame?.id, workout.games[1].id);

      final state2 = container.read(workoutSessionProvider);
      expect(state2!.currentGameIndex, 1);
      expect(state2.currentStep, 2);

      // Record Game 2
      final result2 = _createTestResult(gameId: workout.games[1].id);
      await notifier.recordGameResult(result2);

      // Advance to Game 3
      notifier.advanceToNextGame();
      final state3 = container.read(workoutSessionProvider);
      expect(state3!.currentGameIndex, 2);
      expect(state3.nextGame, isNull);

      // Record final Game 3
      final result3 =
          _createTestResult(gameId: workout.games[2].id, finalScore: 800);
      await notifier.recordGameResult(result3);

      final finalState = container.read(workoutSessionProvider);
      expect(finalState!.completedResults.length, 3);
      expect(finalState.isCompleted, isTrue);

      notifier.endWorkout();
      expect(container.read(workoutSessionProvider), isNull);
    });
  });
}
