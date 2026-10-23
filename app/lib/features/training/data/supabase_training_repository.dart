import 'package:game_engine/game_engine.dart';
import 'package:intl/intl.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/network/supabase_client.dart';
import 'package:neuroplay/core/utils/logger.dart';
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

      if (row == null) {
        // Generate and persist today's workout
        final generated = WorkoutGenerator.generateDailyWorkout(today);
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

      return WorkoutGenerator.generateDailyWorkout(
        today,
        completedGameIds: completedList,
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
}
