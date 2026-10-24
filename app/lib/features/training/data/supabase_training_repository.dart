import 'package:game_engine/game_engine.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/network/supabase_client.dart';
import 'package:neuroplay/core/utils/logger.dart';
import 'package:neuroplay/features/progress/domain/progress_models.dart';
import 'package:neuroplay/features/training/data/local_training_repository.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/cognitive_index_calculator.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real Supabase-backed training repository for authenticated users.
class SupabaseTrainingRepository implements ITrainingRepository {
  SupabaseTrainingRepository({
    SupabaseClient? client,
    LocalTrainingRepository? fallback,
  })  : _client = client,
        _fallback = fallback ?? LocalTrainingRepository();

  final SupabaseClient? _client;
  final LocalTrainingRepository _fallback;

  SupabaseClient? get client => _client ?? SupabaseConfig.clientOrNull;

  String? get _userId => client?.auth.currentUser?.id;

  @override
  Future<DailyWorkout> getTodayWorkout() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getTodayWorkout();

    try {
      final today = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(today);

      final row = await c
          .from(Tables.dailyWorkouts)
          .select()
          .eq('user_id', uid)
          .eq('workout_date', dateStr)
          .maybeSingle();

      // Fetch user's skill profiles for adaptive difficulty
      final skillProfiles = await getAllSkillEstimates();

      // Fetch recent workout history to prevent repetitive combinations
      final recentRows = await c
          .from(Tables.dailyWorkouts)
          .select('game_ids')
          .eq('user_id', uid)
          .order('workout_date', ascending: false)
          .limit(4);

      final recentCombos = <Set<String>>[];
      for (final r in recentRows) {
        final gIds =
            (r['game_ids'] as List<dynamic>?)?.map((e) => e.toString()).toSet();
        if (gIds != null && gIds.isNotEmpty) {
          recentCombos.add(gIds);
        }
      }

      if (row == null) {
        // Generate and persist today's workout
        final generated = WorkoutGenerator.generateDailyWorkout(
          today,
          skillProfiles: skillProfiles,
          recentCombinations: recentCombos,
        );
        await c.from(Tables.dailyWorkouts).insert({
          'user_id': uid,
          'workout_date': dateStr,
          'title': generated.title,
          'subtitle': generated.subtitle,
          'estimated_minutes': generated.estimatedMinutes,
          'game_ids': generated.games.map((g) => g.id).toList(),
          'completed_game_ids': <String>[],
          'is_completed': false,
        });
        return generated;
      }

      final completedList = (row['completed_game_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};

      final savedGameIds = (row['game_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      if (savedGameIds.isNotEmpty) {
        final games = savedGameIds
            .map(
              (id) => WorkoutGenerator.catalog.firstWhere(
                (g) => g.id == id,
                orElse: () => WorkoutGenerator.catalog.first,
              ),
            )
            .toList();
        final domains = games.map((g) => g.domain).toSet().toList();
        final assignments = games
            .map(
              (g) => WorkoutGameAssignment(
                game: g,
                assignedDifficulty:
                    skillProfiles[g.id]?.recommendedDifficulty ??
                        GameDifficulty.medium,
                selectionReason: 'Scheduled routine activity',
                isCompleted: completedList.contains(g.id),
              ),
            )
            .toList();

        final isFullyCompleted = games.isNotEmpty &&
            games.every((g) => completedList.contains(g.id));

        return DailyWorkout(
          id: row['id'] as String? ?? 'workout-$dateStr',
          date: today,
          title: row['title'] as String? ?? 'Daily Cognitive Routine',
          subtitle: row['subtitle'] as String? ?? '',
          estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt() ?? 9,
          games: games,
          domains: domains,
          assignments: assignments,
          completedGameIds: completedList,
          isCompleted: isFullyCompleted,
        );
      }

      return WorkoutGenerator.generateDailyWorkout(
        today,
        completedGameIds: completedList,
        skillProfiles: skillProfiles,
        recentCombinations: recentCombos,
      );
    } on Object catch (e) {
      AppLogger.warning(
        'Failed to load daily workout from Supabase: $e',
        error: e,
      );
      return _fallback.getTodayWorkout();
    }
  }

  @override
  Future<List<CognitiveGame>> getGames({CognitiveDomain? domain}) async {
    if (domain == null) return WorkoutGenerator.catalog;
    return WorkoutGenerator.catalog.where((g) => g.domain == domain).toList();
  }

  @override
  Future<List<DomainScore>> getDomainScores() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getDomainScores();

    try {
      final rows =
          await c.from(Tables.cognitiveIndices).select().eq('user_id', uid);

      if (rows.isEmpty) return await _fallback.getDomainScores();

      return rows
          .map(
            (r) => DomainScore(
              domain: CognitiveDomain.fromString(r['domain'] as String),
              scoreIndex: (r['score_index'] as num).toInt(),
              trendPercentage: (r['trend_percentage'] as num).toInt(),
              percentileRank: (r['percentile_rank'] as num).toInt(),
              sampleCount: (r['sample_count'] as num).toInt(),
            ),
          )
          .toList();
    } on Object catch (e) {
      AppLogger.warning('Failed to fetch cognitive indices: $e');
      return _fallback.getDomainScores();
    }
  }

  @override
  Future<List<DailyScorePoint>> getWeeklyPerformanceTrend() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getWeeklyPerformanceTrend();

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final rows = await c
          .from(Tables.gameSessions)
          .select('score, created_at, is_practice')
          .eq('user_id', uid)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at');

      final trend = <DailyScorePoint>[];
      for (var i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final datePrefix = DateFormat('yyyy-MM-dd').format(d);
        final daySessions = rows
            .where(
              (r) =>
                  (r['created_at'] as String).startsWith(datePrefix) &&
                  (r['is_practice'] as bool? ?? false) == false,
            )
            .toList();

        final isDone = daySessions.isNotEmpty;
        final score = isDone
            ? (daySessions.fold<num>(
                      0,
                      (sum, item) => sum + (item['score'] as num),
                    ) /
                    daySessions.length /
                    20)
                .round()
                .clamp(10, 100)
            : 0;

        trend.add(
          DailyScorePoint(
            dayLabel: DateFormat('E').format(d),
            scoreIndex: score,
            date: d,
            isCompletedDay: isDone,
          ),
        );
      }
      return trend;
    } on Object catch (e) {
      AppLogger.warning('Failed to load performance trend: $e');
      return _fallback.getWeeklyPerformanceTrend();
    }
  }

  @override
  Future<List<CognitiveChallenge>> getActiveChallenges() async =>
      _fallback.getActiveChallenges();

  @override
  Future<UserStreak> getUserStreak() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getUserStreak();

    try {
      final row = await c
          .from(Tables.userStreaks)
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) return UserStreak.empty;

      return UserStreak(
        currentStreak: (row['current_streak'] as num).toInt(),
        longestStreak: (row['longest_streak'] as num).toInt(),
        lastActivityDate: row['last_activity_date'] != null
            ? DateTime.parse(row['last_activity_date'] as String)
            : null,
        totalSessionsCompleted:
            (row['total_sessions_completed'] as num).toInt(),
        totalWorkoutsCompleted:
            (row['total_workouts_completed'] as num).toInt(),
      );
    } on Object catch (e) {
      AppLogger.warning('Failed to load user streak: $e');
      return _fallback.getUserStreak();
    }
  }

  @override
  Future<OverallCognitiveStats> getOverallStats() async {
    final uid = _userId;
    if (uid == null) return _fallback.getOverallStats();

    final streak = await getUserStreak();
    final domainScores = await getDomainScores();
    final weeklyTrend = await getWeeklyPerformanceTrend();
    final overallIndex =
        CognitiveIndexCalculator.computeOverallIndex(domainScores);

    return OverallCognitiveStats(
      overallBrainIndex: overallIndex,
      streak: streak,
      domainScores: domainScores,
      weeklyTrend: weeklyTrend,
      totalSessions: streak.totalSessionsCompleted,
      totalWorkouts: streak.totalWorkoutsCompleted,
    );
  }

  @override
  Future<void> recordGameSession(GameResult result, {String? workoutId}) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      await _fallback.recordGameSession(result, workoutId: workoutId);
      return;
    }

    // Adaptive difficulty calculation
    final currentSkill = await getSkillEstimate(result.gameId);
    final eval = AdaptiveDifficultyEngine.evaluate(
      existingEstimate: currentSkill,
      result: result,
    );

    try {
      // Upsert updated skill estimate
      await c.from(Tables.userGameSkills).upsert({
        'user_id': uid,
        'game_id': result.gameId,
        'continuous_rating': eval.updatedEstimate.continuousRating,
        'recommended_difficulty':
            eval.updatedEstimate.recommendedDifficulty.name,
        'sample_count': eval.updatedEstimate.sampleCount,
        'consecutive_strong_sessions':
            eval.updatedEstimate.consecutiveStrongSessions,
        'consecutive_weak_sessions':
            eval.updatedEstimate.consecutiveWeakSessions,
        'last_adjustment_reason': eval.updatedEstimate.lastAdjustmentReason,
        'algorithm_version': eval.updatedEstimate.algorithmVersion,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Insert difficulty adjustment audit entry
      await c.from(Tables.difficultyAdjustments).insert({
        'user_id': uid,
        'game_id': result.gameId,
        'previous_difficulty': eval.adjustment.previousDifficulty.name,
        'new_difficulty': eval.adjustment.newDifficulty.name,
        'previous_rating': eval.adjustment.previousRating,
        'new_rating': eval.adjustment.newRating,
        'rating_delta': eval.adjustment.ratingDelta,
        'is_damped': eval.adjustment.isDamped,
        'reason': eval.adjustment.reason,
        'algorithm_version': eval.adjustment.algorithmVersion,
        'metrics_snapshot': eval.adjustment.metricsSnapshot,
      });
    } on Object catch (e) {
      AppLogger.warning('Failed to persist adaptive skill estimate: $e');
    }

    try {
      final isPractice = (result.metrics['isPractice'] as bool?) ?? false;
      final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 1.0;
      final errors = (result.metrics['errors'] as num?)?.toInt() ?? 0;

      // Call server RPC record_game_session
      await c.rpc(
        'record_game_session',
        params: {
          'p_game_id': result.gameId,
          'p_game_version': result.gameVersion,
          'p_score': result.finalScore,
          'p_accuracy': accuracy,
          'p_duration_seconds': result.totalActiveDuration.inSeconds,
          'p_error_count': errors,
          'p_is_practice': isPractice,
          'p_metrics': result.metrics,
          'p_score_breakdown': result.scoreBreakdown.toJson(),
          if (workoutId != null) 'p_workout_id': workoutId,
        },
      );
    } on Object catch (e) {
      AppLogger.warning(
        'Direct RPC failed, inserting session directly to table: $e',
      );
      // Direct fallback insert
      try {
        final isPractice = (result.metrics['isPractice'] as bool?) ?? false;
        final accuracy =
            (result.metrics['accuracy'] as num?)?.toDouble() ?? 1.0;
        final errors = (result.metrics['errors'] as num?)?.toInt() ?? 0;

        await c.from(Tables.gameSessions).insert({
          'user_id': uid,
          'game_id': result.gameId,
          'game_version': result.gameVersion,
          'score': result.finalScore,
          'accuracy': accuracy,
          'duration_seconds': result.totalActiveDuration.inSeconds,
          'error_count': errors,
          'is_practice': isPractice,
          'metrics': result.metrics,
          'score_breakdown': result.scoreBreakdown.toJson(),
          if (workoutId != null) 'workout_id': workoutId,
        });
      } on Object catch (insertError) {
        AppLogger.error('Failed to persist session to Supabase: $insertError');
        await _fallback.recordGameSession(result, workoutId: workoutId);
      }
    }
  }

  @override
  Future<void> markWorkoutCompleted(String workoutId) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      await _fallback.markWorkoutCompleted(workoutId);
      return;
    }

    try {
      await c
          .from(Tables.dailyWorkouts)
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', workoutId)
          .eq('user_id', uid);
    } on Object catch (e) {
      AppLogger.warning('Failed to mark workout complete in Supabase: $e');
      await _fallback.markWorkoutCompleted(workoutId);
    }
  }

  @override
  Future<SkillEstimate> getSkillEstimate(String gameId) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getSkillEstimate(gameId);

    try {
      final row = await c
          .from(Tables.userGameSkills)
          .select()
          .eq('user_id', uid)
          .eq('game_id', gameId)
          .maybeSingle();

      if (row == null) {
        return SkillEstimate.initial(gameId);
      }

      return SkillEstimate(
        gameId: row['game_id'] as String,
        continuousRating: (row['continuous_rating'] as num).toDouble(),
        recommendedDifficulty: GameDifficulty.fromJson(
          row['recommended_difficulty'] as String,
        ),
        sampleCount: (row['sample_count'] as num).toInt(),
        consecutiveStrongSessions:
            (row['consecutive_strong_sessions'] as num).toInt(),
        consecutiveWeakSessions:
            (row['consecutive_weak_sessions'] as num).toInt(),
        lastAdjustmentReason:
            (row['last_adjustment_reason'] as String?) ?? 'Calibrated rating',
        algorithmVersion: row['algorithm_version'] as String? ?? '1.0.0',
        lastUpdatedAt: row['last_updated_at'] != null
            ? DateTime.parse(row['last_updated_at'] as String)
            : null,
      );
    } on Object catch (e) {
      AppLogger.warning('Failed to load skill estimate for $gameId: $e');
      return _fallback.getSkillEstimate(gameId);
    }
  }

  @override
  Future<Map<String, SkillEstimate>> getAllSkillEstimates() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getAllSkillEstimates();

    try {
      final rows =
          await c.from(Tables.userGameSkills).select().eq('user_id', uid);

      final result = <String, SkillEstimate>{};
      for (final row in rows) {
        final gId = row['game_id'] as String;
        result[gId] = SkillEstimate(
          gameId: gId,
          continuousRating: (row['continuous_rating'] as num).toDouble(),
          recommendedDifficulty: GameDifficulty.fromJson(
            row['recommended_difficulty'] as String,
          ),
          sampleCount: (row['sample_count'] as num).toInt(),
          consecutiveStrongSessions:
              (row['consecutive_strong_sessions'] as num).toInt(),
          consecutiveWeakSessions:
              (row['consecutive_weak_sessions'] as num).toInt(),
          lastAdjustmentReason:
              (row['last_adjustment_reason'] as String?) ?? 'Calibrated rating',
          algorithmVersion: row['algorithm_version'] as String? ?? '1.0.0',
          lastUpdatedAt: row['last_updated_at'] != null
              ? DateTime.parse(row['last_updated_at'] as String)
              : null,
        );
      }
      return result;
    } on Object catch (e) {
      AppLogger.warning('Failed to load all skill estimates: $e');
      return _fallback.getAllSkillEstimates();
    }
  }

  @override
  Future<List<DifficultyAdjustment>> getDifficultyAdjustmentHistory({
    String? gameId,
    int limit = 20,
  }) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      return _fallback.getDifficultyAdjustmentHistory(
        gameId: gameId,
        limit: limit,
      );
    }

    try {
      var query =
          c.from(Tables.difficultyAdjustments).select().eq('user_id', uid);

      if (gameId != null) {
        query = query.eq('game_id', gameId);
      }

      final rows =
          await query.order('created_at', ascending: false).limit(limit);

      return rows
          .map(
            (r) => DifficultyAdjustment(
              gameId: r['game_id'] as String,
              previousDifficulty:
                  GameDifficulty.fromJson(r['previous_difficulty'] as String),
              newDifficulty:
                  GameDifficulty.fromJson(r['new_difficulty'] as String),
              previousRating: (r['previous_rating'] as num).toDouble(),
              newRating: (r['new_rating'] as num).toDouble(),
              ratingDelta: (r['rating_delta'] as num).toDouble(),
              isDamped: r['is_damped'] as bool? ?? false,
              reason: r['reason'] as String,
              algorithmVersion: r['algorithm_version'] as String? ?? '1.0.0',
              metricsSnapshot:
                  (r['metrics_snapshot'] as Map<String, dynamic>?) ?? const {},
              timestamp: DateTime.parse(r['created_at'] as String),
            ),
          )
          .toList();
    } on Object catch (e) {
      AppLogger.warning('Failed to load difficulty adjustments: $e');
      return _fallback.getDifficultyAdjustmentHistory(
        gameId: gameId,
        limit: limit,
      );
    }
  }

  @override
  Future<List<GameSessionRecord>> getGameSessions({
    String? gameId,
    int limit = 30,
  }) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      return _fallback.getGameSessions(gameId: gameId, limit: limit);
    }

    try {
      var query = c.from(Tables.gameSessions).select().eq('user_id', uid);

      if (gameId != null) {
        query = query.eq('game_id', gameId);
      }

      final rows =
          await query.order('created_at', ascending: false).limit(limit);

      if (rows.isEmpty) {
        return await _fallback.getGameSessions(gameId: gameId, limit: limit);
      }

      return rows.map(GameSessionRecord.fromJson).toList();
    } on Object catch (e) {
      AppLogger.warning('Failed to load game sessions: $e');
      return _fallback.getGameSessions(gameId: gameId, limit: limit);
    }
  }

  @override
  Future<GamePersonalBest> getGamePersonalBest(String gameId) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      return _fallback.getGamePersonalBest(gameId);
    }

    try {
      final rows = await c
          .from(Tables.gameSessions)
          .select()
          .eq('user_id', uid)
          .eq('game_id', gameId)
          .eq('is_practice', false)
          .order('score', ascending: false)
          .limit(100);

      if (rows.isEmpty) {
        return await _fallback.getGamePersonalBest(gameId);
      }

      final game = WorkoutGenerator.catalog.firstWhere(
        (g) => g.id == gameId,
        orElse: () => WorkoutGenerator.catalog.first,
      );

      var highestScore = 0;
      var highestAccuracy = 0.0;
      int? fastestRt;
      DateTime? lastPlayed;

      for (final r in rows) {
        final score = (r['score'] as num?)?.toInt() ?? 0;
        final accuracy = (r['accuracy'] as num?)?.toDouble() ?? 0.0;
        final metrics = (r['metrics'] as Map<String, dynamic>?) ?? {};
        final createdAt = r['created_at'] != null
            ? DateTime.parse(r['created_at'] as String)
            : null;

        if (score > highestScore) highestScore = score;
        if (accuracy > highestAccuracy) highestAccuracy = accuracy;

        int? rt;
        if (metrics['medianReactionTimeMs'] != null) {
          rt = (metrics['medianReactionTimeMs'] as num).toInt();
        } else if (metrics['medianResponseTimeMs'] != null) {
          rt = (metrics['medianResponseTimeMs'] as num).toInt();
        }

        if (rt != null && (fastestRt == null || rt < fastestRt)) {
          fastestRt = rt;
        }

        if (createdAt != null) {
          if (lastPlayed == null || createdAt.isAfter(lastPlayed)) {
            lastPlayed = createdAt;
          }
        }
      }

      return GamePersonalBest(
        gameId: gameId,
        gameTitle: game.title,
        highestScore: highestScore,
        highestAccuracy: highestAccuracy,
        fastestMedianRtMs: fastestRt,
        totalSessions: rows.length,
        lastPlayedAt: lastPlayed,
      );
    } on Object catch (e) {
      AppLogger.warning('Failed to load personal best for $gameId: $e');
      return _fallback.getGamePersonalBest(gameId);
    }
  }

  @override
  Future<List<ActivityDayRecord>> getMonthlyActivity(DateTime month) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      return _fallback.getMonthlyActivity(month);
    }

    try {
      final startStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final endStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final rows = await c
          .from(Tables.userDailyActivity)
          .select()
          .eq('user_id', uid)
          .gte('activity_date', startStr)
          .lte('activity_date', endStr);

      if (rows.isEmpty) {
        return await _fallback.getMonthlyActivity(month);
      }

      final map = <int, ActivityDayRecord>{};
      for (final r in rows) {
        final rec = ActivityDayRecord.fromJson(r);
        map[rec.date.day] = rec;
      }

      final result = <ActivityDayRecord>[];
      for (var d = 1; d <= lastDay; d++) {
        result.add(
          map[d] ??
              ActivityDayRecord(
                date: DateTime(month.year, month.month, d),
                sessionsCount: 0,
                durationMinutes: 0,
                xpEarned: 0,
              ),
        );
      }
      return result;
    } on Object catch (e) {
      AppLogger.warning('Failed to load monthly activity: $e');
      return _fallback.getMonthlyActivity(month);
    }
  }

  @override
  Future<UserXpState> getUserXpState() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getUserXpState();

    try {
      final summaryRow = await c
          .from(Tables.userXpSummary)
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      final totalXp = (summaryRow?['total_xp'] as num?)?.toInt() ?? 0;

      final eventRows = await c
          .from(Tables.userXpEvents)
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(10);

      final events = eventRows.map(XpEventRecord.fromJson).toList();

      return UserXpState.fromSummary(
        totalXp: totalXp,
        recentEvents: events,
      );
    } on Object catch (e) {
      AppLogger.warning('Failed to load XP state from Supabase: $e');
      return _fallback.getUserXpState();
    }
  }

  @override
  Future<List<AchievementItem>> getAchievements() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) return _fallback.getAchievements();

    try {
      final allAchievements =
          await c.from(Tables.achievements).select().order('sort_order');

      final userUnlocked =
          await c.from(Tables.userAchievements).select().eq('user_id', uid);

      final unlockedMap = <String, DateTime>{};
      for (final u in userUnlocked) {
        final code = u['achievement_code'] as String;
        final date = u['unlocked_at'] != null
            ? DateTime.parse(u['unlocked_at'] as String)
            : DateTime.now();
        unlockedMap[code] = date;
      }

      return allAchievements.map((a) {
        final code = a['code'] as String;
        final isUnlocked = unlockedMap.containsKey(code);
        return AchievementItem.fromJson(
          a,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedMap[code],
        );
      }).toList();
    } on Object catch (e) {
      AppLogger.warning('Failed to load achievements from Supabase: $e');
      return _fallback.getAchievements();
    }
  }

  @override
  Future<List<WorkoutSummaryRecord>> getWorkoutSummaries({
    int limit = 14,
  }) async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      return _fallback.getWorkoutSummaries(limit: limit);
    }

    try {
      final rows = await c
          .from(Tables.dailyWorkouts)
          .select()
          .eq('user_id', uid)
          .order('workout_date', ascending: false)
          .limit(limit);

      if (rows.isEmpty) {
        return await _fallback.getWorkoutSummaries(limit: limit);
      }

      return rows.map(WorkoutSummaryRecord.fromJson).toList();
    } on Object catch (e) {
      AppLogger.warning('Failed to load workout summaries: $e');
      return _fallback.getWorkoutSummaries(limit: limit);
    }
  }

  @override
  Future<Map<String, dynamic>> exportUserDataJson() async {
    final uid = _userId;
    final c = client;
    if (uid == null || c == null) {
      return _fallback.exportUserDataJson();
    }

    try {
      final profile =
          await c.from(Tables.profiles).select().eq('id', uid).maybeSingle();
      final preferences = await c
          .from(Tables.userPreferences)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      final streak = await c
          .from(Tables.userStreaks)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      final cognitiveIndices =
          await c.from(Tables.cognitiveIndices).select().eq('user_id', uid);
      final skills =
          await c.from(Tables.userGameSkills).select().eq('user_id', uid);
      final workouts = await c
          .from(Tables.dailyWorkouts)
          .select()
          .eq('user_id', uid)
          .order('workout_date', ascending: false);
      final sessions = await c
          .from(Tables.gameSessions)
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final xpSummary = await c
          .from(Tables.userXpSummary)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      final xpEvents = await c
          .from(Tables.userXpEvents)
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final achievements = await getAchievements();

      return {
        'export_schema_version': '1.0.0',
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'mode': 'authenticated_cloud_account',
        'user_profile': profile,
        'user_preferences': preferences,
        'user_streak': streak,
        'cognitive_indices': cognitiveIndices,
        'skill_estimates': skills,
        'workout_history': workouts,
        'game_sessions_count': sessions.length,
        'game_sessions': sessions,
        'xp_summary': xpSummary,
        'xp_events': xpEvents,
        'achievements': achievements.map((a) => a.toJson()).toList(),
      };
    } on Object catch (e) {
      AppLogger.warning('Failed cloud export, falling back to local: $e');
      return _fallback.exportUserDataJson();
    }
  }
}
