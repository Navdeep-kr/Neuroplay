import 'package:neuroplay/features/training/domain/training_models.dart';

/// Pure logic for calculating user consecutive daily training streaks.
abstract final class StreakCalculator {
  /// Evaluates and produces an updated [UserStreak] given a new activity on [now].
  static UserStreak calculateOnActivity({
    required UserStreak current,
    required DateTime now,
    bool completedWorkout = false,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final last = current.lastActivityDate != null
        ? DateTime(
            current.lastActivityDate!.year,
            current.lastActivityDate!.month,
            current.lastActivityDate!.day,
          )
        : null;

    int newCurrent;
    if (last == null) {
      newCurrent = 1;
    } else if (last.isAtSameMomentAs(today)) {
      // Already trained today — preserve current streak count
      newCurrent = current.currentStreak > 0 ? current.currentStreak : 1;
    } else {
      final differenceInDays = today.difference(last).inDays;
      if (differenceInDays == 1) {
        // Consecutive calendar day
        newCurrent = current.currentStreak + 1;
      } else {
        // Lapsed day(s) — reset streak to 1
        newCurrent = 1;
      }
    }

    final newLongest =
        newCurrent > current.longestStreak ? newCurrent : current.longestStreak;

    return UserStreak(
      currentStreak: newCurrent,
      longestStreak: newLongest,
      lastActivityDate: today,
      totalSessionsCompleted: current.totalSessionsCompleted + 1,
      totalWorkoutsCompleted:
          current.totalWorkoutsCompleted + (completedWorkout ? 1 : 0),
    );
  }
}
