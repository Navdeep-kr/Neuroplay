import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/core/network/supabase_client.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/progress/domain/progress_models.dart';
import 'package:neuroplay/features/training/data/local_training_repository.dart';
import 'package:neuroplay/features/training/data/supabase_training_repository.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Abstract contract for retrieving training modules, library games, and metrics.
abstract interface class ITrainingRepository {
  Future<DailyWorkout> getTodayWorkout();
  Future<List<CognitiveGame>> getGames({CognitiveDomain? domain});
  Future<List<DomainScore>> getDomainScores();
  Future<List<DailyScorePoint>> getWeeklyPerformanceTrend();
  Future<List<CognitiveChallenge>> getActiveChallenges();
  Future<UserStreak> getUserStreak();
  Future<OverallCognitiveStats> getOverallStats();
  Future<void> recordGameSession(GameResult result, {String? workoutId});
  Future<void> markWorkoutCompleted(String workoutId);
  Future<SkillEstimate> getSkillEstimate(String gameId);
  Future<Map<String, SkillEstimate>> getAllSkillEstimates();
  Future<List<DifficultyAdjustment>> getDifficultyAdjustmentHistory({
    String? gameId,
    int limit = 20,
  });
  Future<List<GameSessionRecord>> getGameSessions({
    String? gameId,
    int limit = 30,
  });
  Future<GamePersonalBest> getGamePersonalBest(String gameId);
  Future<List<ActivityDayRecord>> getMonthlyActivity(DateTime month);
  Future<UserXpState> getUserXpState();
  Future<List<AchievementItem>> getAchievements();
  Future<List<WorkoutSummaryRecord>> getWorkoutSummaries({int limit = 14});
  Future<Map<String, dynamic>> exportUserDataJson();
}

/// Fallback singleton local repository instance for persistent guest sessions.
final _singletonLocalRepo = LocalTrainingRepository();

/// Provider for the active training repository.
final trainingRepositoryProvider = Provider<ITrainingRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (!user.isAuthenticated || !SupabaseConfig.isConfigured) {
    return _singletonLocalRepo;
  }
  return SupabaseTrainingRepository(fallback: _singletonLocalRepo);
});

/// Provider for today's workout.
final todayWorkoutProvider = FutureProvider<DailyWorkout>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getTodayWorkout();
});

/// Provider for user streak.
final userStreakProvider = FutureProvider<UserStreak>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getUserStreak();
});

/// Provider for overall cognitive statistics.
final overallStatsProvider = FutureProvider<OverallCognitiveStats>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getOverallStats();
});

/// Provider for games list.
final gamesListProvider =
    FutureProvider.family<List<CognitiveGame>, CognitiveDomain?>((
  ref,
  domain,
) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getGames(domain: domain);
});

/// Provider for domain performance breakdown.
final domainScoresProvider = FutureProvider<List<DomainScore>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getDomainScores();
});

/// Provider for weekly trend.
final weeklyTrendProvider = FutureProvider<List<DailyScorePoint>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getWeeklyPerformanceTrend();
});

/// Provider for challenges.
final activeChallengesProvider =
    FutureProvider<List<CognitiveChallenge>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getActiveChallenges();
});

/// Provider for user skill estimates across games.
final userSkillEstimatesProvider =
    FutureProvider<Map<String, SkillEstimate>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getAllSkillEstimates();
});

/// Provider for difficulty adjustment audit logs.
final difficultyAdjustmentsProvider =
    FutureProvider.family<List<DifficultyAdjustment>, String?>(
        (ref, gameId) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getDifficultyAdjustmentHistory(gameId: gameId);
});

/// Provider for historical game sessions.
final gameSessionsProvider =
    FutureProvider.family<List<GameSessionRecord>, String?>((ref, gameId) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getGameSessions(gameId: gameId);
});

/// Provider for game personal best metrics.
final gamePersonalBestProvider =
    FutureProvider.family<GamePersonalBest, String>((ref, gameId) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getGamePersonalBest(gameId);
});

/// Provider for monthly training activity calendar.
final monthlyActivityProvider =
    FutureProvider.family<List<ActivityDayRecord>, DateTime>((ref, month) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getMonthlyActivity(month);
});

/// Provider for XP progression state.
final userXpStateProvider = FutureProvider<UserXpState>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getUserXpState();
});

/// Provider for achievements catalog and unlock status.
final achievementsListProvider =
    FutureProvider<List<AchievementItem>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getAchievements();
});

/// Provider for historical workout summaries.
final workoutSummariesProvider =
    FutureProvider<List<WorkoutSummaryRecord>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getWorkoutSummaries();
});
