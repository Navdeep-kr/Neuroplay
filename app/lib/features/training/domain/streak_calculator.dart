import 'package:neuroplay/features/training/domain/training_models.dart';

/// Pure logic for calculating user consecutive daily training streaks.
///
/// Rules:
/// 1. A streak increments by exactly 1 when an activity occurs on the immediate next calendar day.
/// 2. Multiple activities on the same calendar day maintain the streak without multi-incrementing.
/// 3. If one or more full calendar days elapse without an activity, the streak resets to 1 upon the next activity.
/// 4. When viewing current status without activity, if more than 1 calendar day has elapsed since
///    the last activity, the current active streak is 0.
abstract final class StreakCalculator {
  /// Computes the difference in calendar days between two dates, using UTC normalization
  /// to eliminate daylight saving time (DST) shifts or fractional day anomalies.
  static int calendarDaysBetween(DateTime from, DateTime to) {
    final fromUtc = DateTime.utc(from.year, from.month, from.day);
    final toUtc = DateTime.utc(to.year, to.month, to.day);
    return toUtc.difference(fromUtc).inDays;
  }

  /// Evaluates and produces an updated [UserStreak] given a new activity on [now].
  static UserStreak calculateOnActivity({
    required UserStreak current,
    required DateTime now,
    bool completedWorkout = false,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final last = current.lastActivityDate;

    int newCurrent;
    if (last == null) {
      newCurrent = 1;
    } else {
      final days = calendarDaysBetween(last, today);
      if (days <= 0) {
        // Same calendar day or retroactive replay — preserve streak
        newCurrent = current.currentStreak > 0 ? current.currentStreak : 1;
      } else if (days == 1) {
        // Consecutive calendar day
        newCurrent = current.currentStreak + 1;
      } else {
        // Lapsed day(s) — reset streak to 1 on this new activity
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

  /// Calculates the effective displayed streak when passively viewing the dashboard on [now].
  ///
  /// If the user trained yesterday, the streak is pending continuation today (not broken).
  /// If two or more calendar days have passed, the active streak has lapsed to 0.
  static int effectiveStreakAt({
    required UserStreak streak,
    required DateTime now,
  }) {
    if (streak.lastActivityDate == null) return 0;
    final days = calendarDaysBetween(streak.lastActivityDate!, now);
    if (days <= 1) {
      // Trained today (0) or yesterday (1)
      return streak.currentStreak;
    }
    // Lapsed
    return 0;
  }
}
