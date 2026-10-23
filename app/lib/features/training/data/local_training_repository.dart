import 'package:game_engine/game_engine.dart';
import 'package:intl/intl.dart';
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
  }

  @override
  Future<DailyWorkout> getTodayWorkout() async {
    final now = DateTime.now();
    return WorkoutGenerator.generateDailyWorkout(
      now,
      completedGameIds: _completedGameIdsToday,
    );
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

    final workout = await getTodayWorkout();
    final isWorkoutDone = workout.isCompleted;

    _streak = StreakCalculator.calculateOnActivity(
      current: _streak,
      now: now,
      completedWorkout: isWorkoutDone,
    );

    // Update domain score if not practice
    final isPractice = (result.metrics['isPractice'] as bool?) ?? false;
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ?? 1.0;
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
    }
  }

  @override
  Future<void> markWorkoutCompleted(String workoutId) async {
    final workout = await getTodayWorkout();
    for (final game in workout.games) {
      _completedGameIdsToday.add(game.id);
    }
    _streak = StreakCalculator.calculateOnActivity(
      current: _streak,
      now: DateTime.now(),
      completedWorkout: true,
    );
  }

  CognitiveDomain _getDomainForGame(String gameId) {
    switch (gameId) {
      case 'memory-matrix':
        return CognitiveDomain.memory;
      case 'reflex-forge':
        return CognitiveDomain.flexibility;
      case 'focus-reactor':
        return CognitiveDomain.attention;
      default:
        return CognitiveDomain.memory;
    }
  }
}
