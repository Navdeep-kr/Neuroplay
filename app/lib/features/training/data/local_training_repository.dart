import 'package:game_engine/game_engine.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/features/progress/domain/progress_models.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/cognitive_index_calculator.dart';
import 'package:neuroplay/features/training/domain/streak_calculator.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';

/// In-memory training repository for guest users and offline execution.
class LocalTrainingRepository implements ITrainingRepository {
  LocalTrainingRepository() {
    _initDefaults();
  }

  final Set<String> _completedGameIdsToday = {};
  final Map<String, SkillEstimate> _skills = {};
  final List<DifficultyAdjustment> _adjustments = [];
  final List<Set<String>> _recentCombinations = [];
  final List<GameSessionRecord> _sessionHistory = [];
  final List<XpEventRecord> _xpEvents = [];
  final List<AchievementItem> _achievements = [];
  final List<WorkoutSummaryRecord> _workoutSummaries = [];

  UserStreak _streak = const UserStreak(
    currentStreak: 1,
    longestStreak: 3,
    totalSessionsCompleted: 2,
  );

  final Map<CognitiveDomain, DomainScore> _domainScores = {};
  final List<DailyScorePoint> _weeklyTrend = [];

  void _initDefaults() {
    _domainScores[CognitiveDomain.memory] = const DomainScore(
      domain: CognitiveDomain.memory,
      scoreIndex: 78,
      trendPercentage: 3,
      percentileRank: 80,
      sampleCount: 5,
    );
    _domainScores[CognitiveDomain.flexibility] = const DomainScore(
      domain: CognitiveDomain.flexibility,
      scoreIndex: 72,
      trendPercentage: 2,
      percentileRank: 74,
      sampleCount: 4,
    );
    _domainScores[CognitiveDomain.attention] = const DomainScore(
      domain: CognitiveDomain.attention,
      scoreIndex: 81,
      trendPercentage: 5,
      percentileRank: 83,
      sampleCount: 6,
    );
    _domainScores[CognitiveDomain.speed] = const DomainScore(
      domain: CognitiveDomain.speed,
      scoreIndex: 75,
      trendPercentage: 0,
      percentileRank: 76,
      sampleCount: 3,
    );
    _domainScores[CognitiveDomain.problemSolving] = const DomainScore(
      domain: CognitiveDomain.problemSolving,
      scoreIndex: 70,
      trendPercentage: 1,
      percentileRank: 72,
      sampleCount: 2,
    );

    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      _weeklyTrend.add(
        DailyScorePoint(
          dayLabel: DateFormat('E').format(date),
          scoreIndex: i == 0 ? 80 : (65 + (i * 2) % 20),
          date: date,
          isCompletedDay: i > 1,
        ),
      );
    }

    // Default sample achievements
    _achievements.addAll([
      const AchievementItem(
        id: 'ach-01',
        code: 'first_workout',
        title: 'First Routine Completed',
        description: 'Complete your first structured daily training playlist.',
        category: 'training',
        badgeIcon: 'fitness_center',
        xpReward: 50,
      ),
      const AchievementItem(
        id: 'ach-02',
        code: 'streak_3',
        title: 'Consistency Pioneer',
        description:
            'Train for 3 consecutive days without missing a calendar day.',
        category: 'streaks',
        badgeIcon: 'local_fire_department',
        xpReward: 100,
        isUnlocked: true,
      ),
      const AchievementItem(
        id: 'ach-03',
        code: 'streak_7',
        title: 'Habit Architect',
        description: 'Train for 7 consecutive days.',
        category: 'streaks',
        badgeIcon: 'calendar_month',
        xpReward: 250,
      ),
      const AchievementItem(
        id: 'ach-04',
        code: 'perfectionist',
        title: 'Flawless Execution',
        description: 'Achieve 100% accuracy on any standard game session.',
        category: 'mastery',
        badgeIcon: 'verified',
        xpReward: 150,
      ),
      const AchievementItem(
        id: 'ach-05',
        code: 'speed_demon',
        title: 'Cognitive Velocity',
        description:
            'Complete Reflex Forge or Focus Reactor with a median RT under 450ms.',
        category: 'speed',
        badgeIcon: 'bolt',
        xpReward: 150,
      ),
      const AchievementItem(
        id: 'ach-06',
        code: 'brain_athlete',
        title: 'All-Rounder',
        description: 'Complete at least one session in every cognitive domain.',
        category: 'mastery',
        badgeIcon: 'psychology',
        xpReward: 200,
      ),
    ]);

    // Initial XP events
    _xpEvents.addAll([
      XpEventRecord(
        id: 'xp-init-1',
        amount: 100,
        source: 'welcome_bonus',
        description: 'Welcome to NEUROPLAY',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      XpEventRecord(
        id: 'xp-init-2',
        amount: 50,
        source: 'streak_3',
        description: 'Achievement Unlocked: Consistency Pioneer',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Initial recent session history for realistic exploration
    _sessionHistory.addAll([
      GameSessionRecord(
        id: 'sess-init-1',
        gameId: 'memory-matrix',
        gameVersion: '1.0.0',
        score: 820,
        accuracy: 0.88,
        durationSeconds: 75,
        errorCount: 2,
        difficulty: 'medium',
        isVerifiedCloud: false,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      GameSessionRecord(
        id: 'sess-init-2',
        gameId: 'reflex-forge',
        gameVersion: '1.0.0',
        score: 910,
        accuracy: 0.94,
        durationSeconds: 60,
        errorCount: 1,
        difficulty: 'medium',
        medianReactionTimeMs: 462,
        isVerifiedCloud: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      GameSessionRecord(
        id: 'sess-init-3',
        gameId: 'focus-reactor',
        gameVersion: '1.0.0',
        score: 790,
        accuracy: 0.85,
        durationSeconds: 65,
        errorCount: 3,
        difficulty: 'easy',
        medianReactionTimeMs: 512,
        isVerifiedCloud: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  DailyWorkout? _cachedTodayWorkout;
  DateTime? _cachedWorkoutDate;

  @override
  Future<DailyWorkout> getTodayWorkout() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_cachedTodayWorkout == null || _cachedWorkoutDate != today) {
      _cachedTodayWorkout = WorkoutGenerator.generateDailyWorkout(
        now,
        completedGameIds: _completedGameIdsToday,
        skillProfiles: _skills,
        recentCombinations: _recentCombinations,
      );
      _cachedWorkoutDate = today;
    } else {
      final isDone = _cachedTodayWorkout!.games.isNotEmpty &&
          _cachedTodayWorkout!.games
              .every((g) => _completedGameIdsToday.contains(g.id));
      _cachedTodayWorkout = _cachedTodayWorkout!.copyWith(
        completedGameIds: _completedGameIdsToday,
        isCompleted: isDone,
      );
    }
    return _cachedTodayWorkout!;
  }

  @override
  Future<List<CognitiveGame>> getGames({CognitiveDomain? domain}) async {
    if (domain == null) return WorkoutGenerator.catalog;
    return WorkoutGenerator.catalog.where((g) => g.domain == domain).toList();
  }

  @override
  Future<List<DomainScore>> getDomainScores() async =>
      _domainScores.values.toList();

  @override
  Future<List<DailyScorePoint>> getWeeklyPerformanceTrend() async =>
      List.unmodifiable(_weeklyTrend);

  @override
  Future<List<CognitiveChallenge>> getActiveChallenges() async => const [
        CognitiveChallenge(
          id: 'c-01',
          title: 'Daily Workout Streak',
          description:
              'Complete your customized daily routine 5 days this week.',
          domain: CognitiveDomain.attention,
          currentProgress: 3,
          targetProgress: 5,
          unit: 'days',
          daysRemaining: 3,
        ),
        CognitiveChallenge(
          id: 'c-02',
          title: 'Working Memory Depth',
          description:
              'Achieve 85% or higher accuracy across 3 Memory Matrix sessions.',
          domain: CognitiveDomain.memory,
          currentProgress: 2,
          targetProgress: 3,
          unit: 'sessions',
          daysRemaining: 2,
        ),
      ];

  @override
  Future<UserStreak> getUserStreak() async => _streak;

  @override
  Future<OverallCognitiveStats> getOverallStats() async {
    final scores = await getDomainScores();
    final overall = CognitiveIndexCalculator.computeOverallIndex(scores);
    return OverallCognitiveStats(
      overallBrainIndex: overall,
      streak: _streak,
      domainScores: scores,
      weeklyTrend: _weeklyTrend,
      totalSessions: _streak.totalSessionsCompleted,
      totalWorkouts: _streak.totalWorkoutsCompleted,
    );
  }

  @override
  Future<void> recordGameSession(GameResult result, {String? workoutId}) async {
    final now = DateTime.now();
    if (workoutId != null) {
      _completedGameIdsToday.add(result.gameId);
    }

    // Adaptive difficulty evaluation
    final currentSkill =
        _skills[result.gameId] ?? SkillEstimate.initial(result.gameId);
    final eval = AdaptiveDifficultyEngine.evaluate(
      existingEstimate: currentSkill,
      result: result,
    );
    _skills[result.gameId] = eval.updatedEstimate;
    _adjustments.insert(0, eval.adjustment);

    final workout = await getTodayWorkout();
    final isWorkoutDone = workout.isCompleted;

    if (isWorkoutDone) {
      _recentCombinations.add(workout.games.map((g) => g.id).toSet());
    }

    _streak = StreakCalculator.calculateOnActivity(
      current: _streak,
      now: now,
      completedWorkout: isWorkoutDone,
    );

    // Update domain score if not practice
    final isPractice = (result.metrics['isPractice'] as bool?) ?? false;
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 1.0;
    final errors = (result.metrics['errors'] as num?)?.toInt() ?? 0;

    int? medianRt;
    if (result.metrics['medianReactionTimeMs'] != null) {
      medianRt = (result.metrics['medianReactionTimeMs'] as num).toInt();
    } else if (result.metrics['medianResponseTimeMs'] != null) {
      medianRt = (result.metrics['medianResponseTimeMs'] as num).toInt();
    } else if (result.metrics['meanResponseTimeMs'] != null) {
      medianRt = (result.metrics['meanResponseTimeMs'] as num).toInt();
    }

    final sessionRecord = GameSessionRecord(
      id: 'sess-${now.millisecondsSinceEpoch}',
      gameId: result.gameId,
      gameVersion: result.gameVersion,
      score: result.finalScore,
      accuracy: accuracy,
      durationSeconds: result.totalActiveDuration.inSeconds,
      errorCount: errors,
      difficulty: eval.updatedEstimate.recommendedDifficulty.name,
      medianReactionTimeMs: medianRt,
      isPractice: isPractice,
      isVerifiedCloud: false,
      createdAt: now,
    );
    _sessionHistory.insert(0, sessionRecord);

    if (!isPractice) {
      final domain = _getDomainForGame(result.gameId);
      final sessionIndex = CognitiveIndexCalculator.computeSessionIndex(
        accuracy: accuracy,
        rawScore: result.finalScore,
      );
      final currentScore = _domainScores[domain] ??
          DomainScore(
            domain: domain,
            scoreIndex: 50,
            trendPercentage: 0,
            percentileRank: 50,
          );
      _domainScores[domain] = CognitiveIndexCalculator.updateDomainScore(
        existing: currentScore,
        sessionIndex: sessionIndex,
      );

      // Award XP
      var earnedXp = 50;
      if (accuracy >= 0.95) earnedXp += 25;
      _xpEvents.insert(
        0,
        XpEventRecord(
          id: 'xp-${now.millisecondsSinceEpoch}',
          amount: earnedXp,
          source: 'game_session',
          description: 'Completed session: ${result.gameId}',
          createdAt: now,
        ),
      );

      // Evaluate achievements
      _evaluateAchievements(result, accuracy, medianRt);
    }
  }

  void _evaluateAchievements(
    GameResult result,
    double accuracy,
    int? medianRt,
  ) {
    final now = DateTime.now();
    for (var i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      if (a.isUnlocked) continue;

      var unlock = false;
      if (a.code == 'perfectionist' && accuracy >= 1.0) {
        unlock = true;
      } else if (a.code == 'speed_demon' &&
          medianRt != null &&
          medianRt < 450 &&
          (result.gameId == 'reflex-forge' ||
              result.gameId == 'focus-reactor')) {
        unlock = true;
      } else if (a.code == 'streak_3' && _streak.currentStreak >= 3) {
        unlock = true;
      } else if (a.code == 'streak_7' && _streak.currentStreak >= 7) {
        unlock = true;
      }

      if (unlock) {
        _achievements[i] = AchievementItem(
          id: a.id,
          code: a.code,
          title: a.title,
          description: a.description,
          category: a.category,
          badgeIcon: a.badgeIcon,
          xpReward: a.xpReward,
          isUnlocked: true,
          unlockedAt: now,
        );
        _xpEvents.insert(
          0,
          XpEventRecord(
            id: 'xp-ach-${now.millisecondsSinceEpoch}',
            amount: a.xpReward,
            source: 'achievement',
            description: 'Unlocked: ${a.title}',
            createdAt: now,
          ),
        );
      }
    }
  }

  @override
  Future<void> markWorkoutCompleted(String workoutId) async {
    final now = DateTime.now();
    final workout = await getTodayWorkout();
    for (final game in workout.games) {
      _completedGameIdsToday.add(game.id);
    }
    _recentCombinations.add(workout.games.map((g) => g.id).toSet());
    _streak = StreakCalculator.calculateOnActivity(
      current: _streak,
      now: now,
      completedWorkout: true,
    );

    _workoutSummaries.insert(
      0,
      WorkoutSummaryRecord(
        id: workoutId,
        date: now,
        title: workout.title,
        gameIds: workout.games.map((g) => g.id).toList(),
        completedGameIds: workout.games.map((g) => g.id).toList(),
        isCompleted: true,
        durationMinutes: workout.estimatedMinutes,
      ),
    );

    // Award workout XP
    _xpEvents.insert(
      0,
      XpEventRecord(
        id: 'xp-workout-${now.millisecondsSinceEpoch}',
        amount: 100,
        source: 'workout_completion',
        description: 'Completed Daily Routine: ${workout.title}',
        createdAt: now,
      ),
    );

    // Unlock first_workout if not already unlocked
    for (var i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      if (a.code == 'first_workout' && !a.isUnlocked) {
        _achievements[i] = AchievementItem(
          id: a.id,
          code: a.code,
          title: a.title,
          description: a.description,
          category: a.category,
          badgeIcon: a.badgeIcon,
          xpReward: a.xpReward,
          isUnlocked: true,
          unlockedAt: now,
        );
      }
    }
  }

  @override
  Future<SkillEstimate> getSkillEstimate(String gameId) async =>
      _skills[gameId] ?? SkillEstimate.initial(gameId);

  @override
  Future<Map<String, SkillEstimate>> getAllSkillEstimates() async =>
      Map.unmodifiable(_skills);

  @override
  Future<List<DifficultyAdjustment>> getDifficultyAdjustmentHistory({
    String? gameId,
    int limit = 20,
  }) async {
    if (gameId != null) {
      return _adjustments.where((a) => a.gameId == gameId).take(limit).toList();
    }
    return _adjustments.take(limit).toList();
  }

  @override
  Future<List<GameSessionRecord>> getGameSessions({
    String? gameId,
    int limit = 30,
  }) async {
    if (gameId != null) {
      return _sessionHistory
          .where((s) => s.gameId == gameId)
          .take(limit)
          .toList();
    }
    return _sessionHistory.take(limit).toList();
  }

  @override
  Future<GamePersonalBest> getGamePersonalBest(String gameId) async {
    final game = WorkoutGenerator.catalog.firstWhere(
      (g) => g.id == gameId,
      orElse: () => WorkoutGenerator.catalog.first,
    );

    final sessions = _sessionHistory
        .where((s) => s.gameId == gameId && !s.isPractice)
        .toList();

    if (sessions.isEmpty) {
      return GamePersonalBest.empty(gameId, game.title);
    }

    var highestScore = 0;
    var highestAccuracy = 0.0;
    int? fastestRt;
    DateTime? lastPlayed;

    for (final s in sessions) {
      if (s.score > highestScore) highestScore = s.score;
      if (s.accuracy > highestAccuracy) highestAccuracy = s.accuracy;
      if (s.medianReactionTimeMs != null) {
        if (fastestRt == null || s.medianReactionTimeMs! < fastestRt) {
          fastestRt = s.medianReactionTimeMs;
        }
      }
      if (lastPlayed == null || s.createdAt.isAfter(lastPlayed)) {
        lastPlayed = s.createdAt;
      }
    }

    return GamePersonalBest(
      gameId: gameId,
      gameTitle: game.title,
      highestScore: highestScore,
      highestAccuracy: highestAccuracy,
      fastestMedianRtMs: fastestRt,
      totalSessions: sessions.length,
      lastPlayedAt: lastPlayed,
    );
  }

  @override
  Future<List<ActivityDayRecord>> getMonthlyActivity(DateTime month) async {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final records = <ActivityDayRecord>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final sessionsOnDay = _sessionHistory.where(
        (s) =>
            s.createdAt.year == date.year &&
            s.createdAt.month == date.month &&
            s.createdAt.day == date.day,
      );

      final totalDuration = sessionsOnDay.fold<int>(
        0,
        (sum, s) => sum + (s.durationSeconds / 60).round(),
      );

      final xpOnDay = _xpEvents
          .where(
            (x) =>
                x.createdAt.year == date.year &&
                x.createdAt.month == date.month &&
                x.createdAt.day == date.day,
          )
          .fold<int>(0, (sum, x) => sum + x.amount);

      final workoutDone = _workoutSummaries.any(
        (w) =>
            w.date.year == date.year &&
            w.date.month == date.month &&
            w.date.day == date.day &&
            w.isCompleted,
      );

      records.add(
        ActivityDayRecord(
          date: date,
          sessionsCount: sessionsOnDay.length,
          durationMinutes: totalDuration,
          xpEarned: xpOnDay,
          workoutCompleted: workoutDone,
        ),
      );
    }

    return records;
  }

  @override
  Future<UserXpState> getUserXpState() async {
    final totalXp = _xpEvents.fold<int>(0, (sum, e) => sum + e.amount);
    return UserXpState.fromSummary(
      totalXp: totalXp,
      recentEvents: _xpEvents.take(10).toList(),
    );
  }

  @override
  Future<List<AchievementItem>> getAchievements() async =>
      List.unmodifiable(_achievements);

  @override
  Future<List<WorkoutSummaryRecord>> getWorkoutSummaries(
          {int limit = 14}) async =>
      _workoutSummaries.take(limit).toList();

  @override
  Future<Map<String, dynamic>> exportUserDataJson() async {
    final xpState = await getUserXpState();
    final domainScores = await getDomainScores();
    final skills = await getAllSkillEstimates();

    return {
      'export_schema_version': '1.0.0',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'mode': 'guest_local_storage',
      'streak': {
        'current_streak': _streak.currentStreak,
        'longest_streak': _streak.longestStreak,
        'last_activity_date': _streak.lastActivityDate?.toIso8601String(),
        'total_sessions': _streak.totalSessionsCompleted,
        'total_workouts': _streak.totalWorkoutsCompleted,
      },
      'xp_progression': xpState.toJson(),
      'achievements': _achievements.map((a) => a.toJson()).toList(),
      'cognitive_indices': domainScores
          .map(
            (d) => {
              'domain': d.domain.name,
              'score_index': d.scoreIndex,
              'trend_percentage': d.trendPercentage,
              'percentile_rank': d.percentileRank,
            },
          )
          .toList(),
      'skill_estimates': skills.map(
        (key, value) => MapEntry(key, {
          'continuous_rating': value.continuousRating,
          'recommended_difficulty': value.recommendedDifficulty.name,
          'sample_count': value.sampleCount,
          'algorithm_version': value.algorithmVersion,
        }),
      ),
      'game_sessions_count': _sessionHistory.length,
      'game_sessions': _sessionHistory.map((s) => s.toJson()).toList(),
      'workout_history': _workoutSummaries.map((w) => w.toJson()).toList(),
    };
  }

  CognitiveDomain _getDomainForGame(String gameId) {
    switch (gameId) {
      case 'memory-matrix':
        return CognitiveDomain.memory;
      case 'reflex-forge':
        return CognitiveDomain.flexibility;
      case 'focus-reactor':
        return CognitiveDomain.attention;
      case 'logic-labyrinth':
        return CognitiveDomain.problemSolving;
      case 'number-pulse':
        return CognitiveDomain.speed;
      case 'word-weaver':
        return CognitiveDomain.memory;
      default:
        return CognitiveDomain.memory;
    }
  }
}
