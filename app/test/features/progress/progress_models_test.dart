import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/progress/domain/progress_models.dart';
import 'package:neuroplay/features/training/domain/streak_calculator.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

void main() {
  group('Progress Models Unit Tests', () {
    test(
        'GameSessionRecord correctly parses JSON metrics and cloud verification',
        () {
      final json = {
        'id': 'sess-123',
        'game_id': 'reflex-forge',
        'game_version': '1.0.0',
        'score': 850,
        'accuracy': 0.92,
        'duration_seconds': 60,
        'error_count': 1,
        'difficulty': 'hard',
        'is_practice': false,
        'metrics': {
          'medianReactionTimeMs': 415,
        },
        'created_at': '2026-10-24T10:00:00.000Z',
      };

      final record = GameSessionRecord.fromJson(json);

      expect(record.id, equals('sess-123'));
      expect(record.gameId, equals('reflex-forge'));
      expect(record.score, equals(850));
      expect(record.accuracy, equals(0.92));
      expect(record.durationSeconds, equals(60));
      expect(record.errorCount, equals(1));
      expect(record.difficulty, equals('hard'));
      expect(record.medianReactionTimeMs, equals(415));
      expect(record.isPractice, isFalse);
      expect(record.isVerifiedCloud, isTrue);

      final serialized = record.toJson();
      expect(serialized['game_id'], equals('reflex-forge'));
      expect(serialized['median_reaction_time_ms'], equals(415));
      expect(serialized['is_verified_cloud'], isTrue);
    });

    test('GamePersonalBest handles empty and populated states', () {
      final emptyPb = GamePersonalBest.empty('memory-matrix', 'Memory Matrix');
      expect(emptyPb.highestScore, equals(0));
      expect(emptyPb.highestAccuracy, equals(0.0));
      expect(emptyPb.totalSessions, equals(0));
      expect(emptyPb.lastPlayedAt, isNull);

      final pb = GamePersonalBest(
        gameId: 'memory-matrix',
        gameTitle: 'Memory Matrix',
        highestScore: 950,
        highestAccuracy: 1,
        totalSessions: 12,
        lastPlayedAt: DateTime.utc(2026, 10, 24, 8, 30),
      );

      expect(pb.highestScore, equals(950));
      expect(pb.highestAccuracy, equals(1.0));
      expect(pb.totalSessions, equals(12));
      expect(pb.toJson()['highest_score'], equals(950));
    });

    test('UserXpState calculates levels, thresholds, and titles accurately',
        () {
      // 0 XP -> Level 1 Novice
      final initial = UserXpState.fromSummary(totalXp: 0);
      expect(initial.currentLevel, equals(1));
      expect(initial.levelTitle, equals('Novice Practitioner'));
      expect(initial.progressPercent, equals(0.0));
      expect(initial.xpToNextLevel, equals(200));

      // 250 XP -> Level 2 Focused Explorer
      final level2 = UserXpState.fromSummary(totalXp: 250);
      expect(level2.currentLevel, equals(2));
      expect(level2.levelTitle, equals('Focused Explorer'));
      expect(level2.progressPercent, greaterThan(0.0));

      // 600 XP -> Level 3 Cognitive Adept
      final level3 = UserXpState.fromSummary(totalXp: 600);
      expect(level3.currentLevel, equals(3));
      expect(level3.levelTitle, equals('Cognitive Adept'));
    });

    test('ActivityDayRecord serialization roundtrip', () {
      final date = DateTime.utc(2026, 10, 24);
      final record = ActivityDayRecord(
        date: date,
        sessionsCount: 3,
        durationMinutes: 15,
        xpEarned: 175,
        workoutCompleted: true,
      );

      expect(record.hasActivity, isTrue);
      final json = record.toJson();
      expect(json['sessions_count'], equals(3));
      expect(json['xp_earned'], equals(175));
      expect(json['workout_completed'], isTrue);

      final restored = ActivityDayRecord.fromJson(json);
      expect(restored.sessionsCount, equals(3));
      expect(restored.durationMinutes, equals(15));
      expect(restored.workoutCompleted, isTrue);
    });
  });

  group('StreakCalculator Strict Rules & Timezone Tests', () {
    test('initial activity sets streak to 1', () {
      const current = UserStreak.empty;
      final now = DateTime.utc(2026, 10, 20, 14);

      final updated = StreakCalculator.calculateOnActivity(
        current: current,
        now: now,
      );

      expect(updated.currentStreak, equals(1));
      expect(updated.longestStreak, equals(1));
      expect(updated.totalSessionsCompleted, equals(1));
    });

    test(
        'activity on the same calendar day preserves streak count without double-incrementing',
        () {
      final nowMorning = DateTime.utc(2026, 10, 20, 8, 30);
      final nowEvening = DateTime.utc(2026, 10, 20, 20, 45);

      final streakMorning = StreakCalculator.calculateOnActivity(
        current: UserStreak.empty,
        now: nowMorning,
      );
      expect(streakMorning.currentStreak, equals(1));
      expect(streakMorning.totalSessionsCompleted, equals(1));

      final streakEvening = StreakCalculator.calculateOnActivity(
        current: streakMorning,
        now: nowEvening,
      );
      expect(
        streakEvening.currentStreak,
        equals(1),
        reason: 'Multiple sessions same day must not inflate streak',
      );
      expect(streakEvening.totalSessionsCompleted, equals(2));
    });

    test('consecutive calendar day increments streak by exactly 1', () {
      final day1 = DateTime.utc(2026, 10, 20, 10);
      final day2 = DateTime.utc(2026, 10, 21, 15);

      final streak1 = StreakCalculator.calculateOnActivity(
        current: UserStreak.empty,
        now: day1,
      );
      final streak2 = StreakCalculator.calculateOnActivity(
        current: streak1,
        now: day2,
      );

      expect(streak2.currentStreak, equals(2));
      expect(streak2.longestStreak, equals(2));
    });

    test('lapsed calendar day resets streak to 1 on next session', () {
      final day1 = DateTime.utc(2026, 10, 20, 10);

      final streak1 = StreakCalculator.calculateOnActivity(
        current: const UserStreak(currentStreak: 5, longestStreak: 7),
        now: day1,
      );
      expect(streak1.currentStreak, equals(1));

      // Train on day 2
      final day2 = DateTime.utc(2026, 10, 21, 10);
      final streak2 = StreakCalculator.calculateOnActivity(
        current: streak1,
        now: day2,
      );
      expect(streak2.currentStreak, equals(2));

      // Now miss day 3 (Oct 22) and train on Oct 23
      final day4 = DateTime.utc(2026, 10, 23, 11);
      final streak4 = StreakCalculator.calculateOnActivity(
        current: streak2,
        now: day4,
      );

      expect(
        streak4.currentStreak,
        equals(1),
        reason: 'Missed day must reset current streak to 1',
      );
      expect(
        streak4.longestStreak,
        equals(7),
        reason: 'Longest streak record must be preserved',
      );
    });

    test(
        'effectiveStreakAt correctly reports 0 when passive view has lapsed >= 2 days',
        () {
      final lastDate = DateTime.utc(2026, 10, 20);
      final streak = UserStreak(
        currentStreak: 4,
        longestStreak: 8,
        lastActivityDate: lastDate,
      );

      // Viewed same day (Oct 20) -> intact
      expect(
        StreakCalculator.effectiveStreakAt(
          streak: streak,
          now: DateTime.utc(2026, 10, 20, 18),
        ),
        equals(4),
      );

      // Viewed next day (Oct 21) -> pending continuation (still 4)
      expect(
        StreakCalculator.effectiveStreakAt(
          streak: streak,
          now: DateTime.utc(2026, 10, 21, 14),
        ),
        equals(4),
      );

      // Viewed 2 days later (Oct 22) -> lapsed!
      expect(
        StreakCalculator.effectiveStreakAt(
          streak: streak,
          now: DateTime.utc(2026, 10, 22, 10),
        ),
        equals(0),
        reason:
            'Passive view after full missed calendar day must not show false continuity',
      );
    });

    test(
        'calendarDaysBetween handles daylight saving time 23h and 25h boundaries accurately',
        () {
      // 23-hour DST transition day
      final preDst = DateTime(2026, 3, 28, 14);
      final postDst = DateTime(2026, 3, 29, 14);
      expect(StreakCalculator.calendarDaysBetween(preDst, postDst), equals(1));

      // 25-hour DST fall-back transition day
      final preFall = DateTime(2026, 10, 24, 10);
      final postFall = DateTime(2026, 10, 25, 10);
      expect(
        StreakCalculator.calendarDaysBetween(preFall, postFall),
        equals(1),
      );
    });
  });
}
