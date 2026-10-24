import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';

void main() {
  group('WorkoutGenerator Unit Tests', () {
    test(
        'catalog contains all six original playable games with distinct domains',
        () {
      final catalog = WorkoutGenerator.catalog;
      expect(catalog.length, 6);

      final gameIds = catalog.map((g) => g.id).toSet();
      expect(
        gameIds,
        containsAll([
          'memory-matrix',
          'reflex-forge',
          'focus-reactor',
          'logic-labyrinth',
          'number-pulse',
          'word-weaver',
        ]),
      );

      final domains = catalog.map((g) => g.domain).toSet();
      expect(domains.contains(CognitiveDomain.memory), isTrue);
      expect(domains.contains(CognitiveDomain.flexibility), isTrue);
      expect(domains.contains(CognitiveDomain.attention), isTrue);
      expect(domains.contains(CognitiveDomain.problemSolving), isTrue);
      expect(domains.contains(CognitiveDomain.speed), isTrue);
    });

    test('generates deterministic daily workout for the same date', () {
      final date = DateTime(2026, 10, 23);
      final workoutA = WorkoutGenerator.generateDailyWorkout(date);
      final workoutB = WorkoutGenerator.generateDailyWorkout(date);

      expect(workoutA.id, workoutB.id);
      expect(workoutA.title, workoutB.title);
      expect(workoutA.subtitle, workoutB.subtitle);
      expect(workoutA.estimatedMinutes, 9);
      expect(workoutA.games.length, 3);

      for (var i = 0; i < workoutA.games.length; i++) {
        expect(workoutA.games[i].id, workoutB.games[i].id);
      }
    });

    test('different dates cycle through balanced game permutations', () {
      final date1 = DateTime(2026, 10, 21);
      final date2 = DateTime(2026, 10, 22);
      final date3 = DateTime(2026, 10, 23);

      final workout1 = WorkoutGenerator.generateDailyWorkout(date1);
      final workout2 = WorkoutGenerator.generateDailyWorkout(date2);
      final workout3 = WorkoutGenerator.generateDailyWorkout(date3);

      // Each daily workout has 3 distinct games
      expect(workout1.games.map((g) => g.id).toSet().length, 3);
      expect(workout2.games.map((g) => g.id).toSet().length, 3);
      expect(workout3.games.map((g) => g.id).toSet().length, 3);
    });

    test('marks isCompleted true only when all playlist games are finished',
        () {
      final date = DateTime(2026, 10, 23);
      final sample = WorkoutGenerator.generateDailyWorkout(date);
      final workoutIncomplete = WorkoutGenerator.generateDailyWorkout(
        date,
        completedGameIds: {sample.games[0].id, sample.games[1].id},
      );
      expect(workoutIncomplete.isCompleted, isFalse);

      final workoutComplete = WorkoutGenerator.generateDailyWorkout(
        date,
        completedGameIds: sample.games.map((g) => g.id).toSet(),
      );
      expect(workoutComplete.isCompleted, isTrue);
    });
  });
}
