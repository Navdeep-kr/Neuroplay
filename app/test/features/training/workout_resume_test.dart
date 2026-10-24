import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';
import 'package:neuroplay/features/training/presentation/workout_session_controller.dart';

GameResult _mockResult(String gameId) => GameResult(
      sessionId: 'sess-$gameId',
      gameId: gameId,
      gameVersion: '1.0.0',
      engineVersion: '1.0.0',
      scoringRulesVersion: '1.0.0',
      seed: 42,
      difficulty: GameDifficulty.medium,
      completionPhase: GamePhase.completed,
      finalScore: 800,
      scoreBreakdown: const ScoreBreakdown(
        rawScore: 800,
        finalScore: 800,
      ),
      totalActiveDuration: const Duration(seconds: 40),
      totalActions: 8,
      metrics: const {'accuracy': 0.9, 'errors': 0},
      completedAt: DateTime.now(),
    );

void main() {
  group('Workout Resume Flow Tests', () {
    final testDate = DateTime(2026, 10, 24);

    test('resumeGameIndex correctly identifies next uncompleted game', () {
      final baseWorkout = WorkoutGenerator.generateDailyWorkout(testDate);
      expect(baseWorkout.games.length, equals(3));
      expect(baseWorkout.resumeGameIndex, equals(0));
      expect(baseWorkout.isPartiallyCompleted, isFalse);

      // Complete game 1
      final partial1 = baseWorkout.copyWith(
        completedGameIds: {baseWorkout.games[0].id},
      );
      expect(partial1.resumeGameIndex, equals(1));
      expect(partial1.isPartiallyCompleted, isTrue);

      // Complete game 1 and 2
      final partial2 = baseWorkout.copyWith(
        completedGameIds: {baseWorkout.games[0].id, baseWorkout.games[1].id},
      );
      expect(partial2.resumeGameIndex, equals(2));
      expect(partial2.isPartiallyCompleted, isTrue);

      // Complete all 3
      final allDone = baseWorkout.copyWith(
        completedGameIds: baseWorkout.games.map((g) => g.id).toSet(),
        isCompleted: true,
      );
      expect(allDone.isPartiallyCompleted, isFalse);
    });

    test('WorkoutSessionNotifier seamlessly resumes at interrupted step',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final baseWorkout = WorkoutGenerator.generateDailyWorkout(testDate);
      final interruptedWorkout = baseWorkout.copyWith(
        completedGameIds: {baseWorkout.games[0].id},
      );

      final notifier = container.read(workoutSessionProvider.notifier)
        ..resumeWorkout(interruptedWorkout);

      final state = container.read(workoutSessionProvider);
      expect(state, isNotNull);
      expect(state!.currentGameIndex, equals(1));
      expect(state.currentGame?.id, equals(baseWorkout.games[1].id));
      expect(state.currentStep, equals(2));
      expect(state.totalCompletedCount, equals(1));
      expect(state.isCompleted, isFalse);

      // Complete game 2
      await notifier.recordGameResult(_mockResult(baseWorkout.games[1].id));
      final stateAfterGame2 = container.read(workoutSessionProvider);
      expect(stateAfterGame2!.totalCompletedCount, equals(2));
      expect(stateAfterGame2.isCompleted, isFalse);

      // Advance to game 3
      notifier.advanceToNextGame();
      final state3 = container.read(workoutSessionProvider);
      expect(state3!.currentGameIndex, equals(2));
      expect(state3.currentGame?.id, equals(baseWorkout.games[2].id));

      // Complete game 3
      await notifier.recordGameResult(_mockResult(baseWorkout.games[2].id));
      final completedState = container.read(workoutSessionProvider);
      expect(completedState!.isCompleted, isTrue);
    });
  });
}
