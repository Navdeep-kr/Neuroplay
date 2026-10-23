import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/training/domain/streak_calculator.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

void main() {
  group('StreakCalculator Unit Tests', () {
    test('first activity ever initializes streak to 1', () {
      const initial = UserStreak.empty;
      final now = DateTime(2026, 10, 23, 10, 30);

      final updated = StreakCalculator.calculateOnActivity(
        current: initial,
        now: now,
      );

      expect(updated.currentStreak, 1);
      expect(updated.longestStreak, 1);
      expect(updated.totalSessionsCompleted, 1);
      expect(updated.totalWorkoutsCompleted, 0);
      expect(updated.lastActivityDate, DateTime(2026, 10, 23));
    });

    test('multiple activities on the same day maintain current streak', () {
      final initial = UserStreak(
        currentStreak: 4,
        longestStreak: 7,
        lastActivityDate: DateTime(2026, 10, 23),
        totalSessionsCompleted: 10,
        totalWorkoutsCompleted: 3,
      );
      final sameDayLater = DateTime(2026, 10, 23, 18, 45);

      final updated = StreakCalculator.calculateOnActivity(
        current: initial,
        now: sameDayLater,
      );

      expect(updated.currentStreak, 4);
      expect(updated.longestStreak, 7);
      expect(updated.totalSessionsCompleted, 11);
    });

    test('activity on consecutive calendar day increments streak', () {
      final initial = UserStreak(
        currentStreak: 4,
        longestStreak: 7,
        lastActivityDate: DateTime(2026, 10, 22),
        totalSessionsCompleted: 10,
        totalWorkoutsCompleted: 3,
      );
      final nextDay = DateTime(2026, 10, 23, 9, 15);

      final updated = StreakCalculator.calculateOnActivity(
        current: initial,
        now: nextDay,
      );

      expect(updated.currentStreak, 5);
      expect(updated.longestStreak, 7);
      expect(updated.totalSessionsCompleted, 11);
    });

    test('current streak exceeding longest streak updates longest streak', () {
      final initial = UserStreak(
        currentStreak: 7,
        longestStreak: 7,
        lastActivityDate: DateTime(2026, 10, 22),
        totalSessionsCompleted: 15,
        totalWorkoutsCompleted: 7,
      );
      final nextDay = DateTime(2026, 10, 23, 9, 15);

      final updated = StreakCalculator.calculateOnActivity(
        current: initial,
        now: nextDay,
      );

      expect(updated.currentStreak, 8);
      expect(updated.longestStreak, 8);
    });

    test('missed day resets current streak back to 1', () {
      final initial = UserStreak(
        currentStreak: 12,
        longestStreak: 12,
        lastActivityDate: DateTime(2026, 10, 20),
        totalSessionsCompleted: 20,
        totalWorkoutsCompleted: 10,
      );
      final twoDaysLater = DateTime(2026, 10, 23, 9, 15);

      final updated = StreakCalculator.calculateOnActivity(
        current: initial,
        now: twoDaysLater,
      );

      expect(updated.currentStreak, 1);
      expect(updated.longestStreak, 12);
      expect(updated.totalSessionsCompleted, 21);
    });

    test('completed workout flag increments totalWorkoutsCompleted', () {
      final initial = UserStreak(
        currentStreak: 2,
        longestStreak: 5,
        lastActivityDate: DateTime(2026, 10, 22),
        totalSessionsCompleted: 6,
        totalWorkoutsCompleted: 1,
      );
      final nextDay = DateTime(2026, 10, 23, 11);

      final updated = StreakCalculator.calculateOnActivity(
        current: initial,
        now: nextDay,
        completedWorkout: true,
      );

      expect(updated.totalWorkoutsCompleted, 2);
    });
  });
}
