import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Abstract contract for retrieving training modules, library games, and metrics.
abstract interface class ITrainingRepository {
  Future<DailyWorkout> getTodayWorkout();
  Future<List<CognitiveGame>> getGames({CognitiveDomain? domain});
  Future<List<DomainScore>> getDomainScores();
  Future<List<DailyScorePoint>> getWeeklyPerformanceTrend();
  Future<List<CognitiveChallenge>> getActiveChallenges();
}

/// Demonstration repository returning structured preview data.
///
/// Note: All returned datasets are designed for architecture and UI validation.
/// They do NOT represent real user historical data or production backend state.
class MockTrainingRepository implements ITrainingRepository {
  const MockTrainingRepository({this.simulatedLatency = Duration.zero});

  final Duration simulatedLatency;

  static const List<CognitiveGame> _gamesCatalog = [
    CognitiveGame(
      id: 'g-001',
      slug: 'reaction-time',
      title: 'Reaction Pulse',
      domain: CognitiveDomain.speed,
      description: 'Measure milliseconds between visual stimulus and response.',
      instructions:
          'Wait for the central circle to shift color. Tap as rapidly as possible without anticipating early.',
      durationMinutes: 2,
      difficulty: 'Introductory',
    ),
    CognitiveGame(
      id: 'g-002',
      slug: 'memory-matrix',
      title: 'Memory Matrix',
      domain: CognitiveDomain.memory,
      description:
          'Memorize briefly illuminated spatial grid patterns and reproduce their positions.',
      instructions:
          'Observe the illuminated tiles on the grid. Reproduce the exact positions after the pattern clears.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
    ),
    CognitiveGame(
      id: 'g-003',
      slug: 'focus-reactor',
      title: 'Focus Reactor',
      domain: CognitiveDomain.attention,
      description:
          'Identify designated target symbols amidst visual distractors or signal absence.',
      instructions:
          'Scan the array for the target item. Select the matching slot or declare absence when missing.',
      durationMinutes: 3,
      difficulty: 'Advanced',
    ),
    CognitiveGame(
      id: 'g-004',
      slug: 'reflex-forge',
      title: 'Reflex Forge',
      domain: CognitiveDomain.flexibility,
      description:
          'Match geometric symbols to dynamically shifting rules with speed and precision.',
      instructions:
          'Match symbols by shape or pattern depending on the active rule. Adapt swiftly when the rule shifts.',
      durationMinutes: 4,
      difficulty: 'Intermediate',
    ),
    CognitiveGame(
      id: 'g-005',
      slug: 'logic-path',
      title: 'Route Optimizer',
      domain: CognitiveDomain.problemSolving,
      description:
          'Plan obstacle-free connection routes with the minimal moves.',
      instructions:
          'Connect origin nodes to targets without crossing previously laid neural conduits.',
      durationMinutes: 4,
      difficulty: 'Advanced',
    ),
  ];

  @override
  Future<DailyWorkout> getTodayWorkout() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    return DailyWorkout(
      id: 'workout-today',
      date: DateTime.now(),
      title: "Today's Cognitive Routine",
      subtitle: 'Focused on processing speed and working memory retention',
      estimatedMinutes: 8,
      domains: const [
        CognitiveDomain.speed,
        CognitiveDomain.memory,
        CognitiveDomain.attention,
      ],
      games: [
        _gamesCatalog[0], // Reaction Pulse
        _gamesCatalog[1], // Matrix Recall
        _gamesCatalog[2], // Distractor Filter
      ],
    );
  }

  @override
  Future<List<CognitiveGame>> getGames({CognitiveDomain? domain}) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    if (domain == null) return _gamesCatalog;
    return _gamesCatalog.where((g) => g.domain == domain).toList();
  }

  @override
  Future<List<DomainScore>> getDomainScores() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    return const [
      DomainScore(
        domain: CognitiveDomain.speed,
        scoreIndex: 82,
        trendPercentage: 6,
        percentileRank: 84,
      ),
      DomainScore(
        domain: CognitiveDomain.memory,
        scoreIndex: 76,
        trendPercentage: 3,
        percentileRank: 78,
      ),
      DomainScore(
        domain: CognitiveDomain.attention,
        scoreIndex: 79,
        trendPercentage: 5,
        percentileRank: 81,
      ),
      DomainScore(
        domain: CognitiveDomain.flexibility,
        scoreIndex: 68,
        trendPercentage: -2,
        percentileRank: 65,
      ),
      DomainScore(
        domain: CognitiveDomain.problemSolving,
        scoreIndex: 74,
        trendPercentage: 4,
        percentileRank: 73,
      ),
    ];
  }

  @override
  Future<List<DailyScorePoint>> getWeeklyPerformanceTrend() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final now = DateTime.now();
    return [
      DailyScorePoint(
        dayLabel: 'Mon',
        scoreIndex: 70,
        date: now.subtract(const Duration(days: 6)),
        isCompletedDay: true,
      ),
      DailyScorePoint(
        dayLabel: 'Tue',
        scoreIndex: 74,
        date: now.subtract(const Duration(days: 5)),
        isCompletedDay: true,
      ),
      DailyScorePoint(
        dayLabel: 'Wed',
        scoreIndex: 72,
        date: now.subtract(const Duration(days: 4)),
        isCompletedDay: true,
      ),
      DailyScorePoint(
        dayLabel: 'Thu',
        scoreIndex: 79,
        date: now.subtract(const Duration(days: 3)),
        isCompletedDay: true,
      ),
      DailyScorePoint(
        dayLabel: 'Fri',
        scoreIndex: 81,
        date: now.subtract(const Duration(days: 2)),
        isCompletedDay: true,
      ),
      DailyScorePoint(
        dayLabel: 'Sat',
        scoreIndex: 83,
        date: now.subtract(const Duration(days: 1)),
        isCompletedDay: true,
      ),
      DailyScorePoint(
        dayLabel: 'Sun',
        scoreIndex: 84,
        date: now,
      ),
    ];
  }

  @override
  Future<List<CognitiveChallenge>> getActiveChallenges() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    return const [
      CognitiveChallenge(
        id: 'c-01',
        title: 'Weekly Consistency Streak',
        description:
            'Complete your customized 8-minute daily routine 5 days this week.',
        domain: CognitiveDomain.attention,
        currentProgress: 4,
        targetProgress: 5,
        unit: 'days',
        daysRemaining: 2,
      ),
      CognitiveChallenge(
        id: 'c-02',
        title: 'Reaction Velocity Sprint',
        description:
            'Log 3 sessions of Reaction Pulse maintaining under 260ms response latency.',
        domain: CognitiveDomain.speed,
        currentProgress: 2,
        targetProgress: 3,
        unit: 'sessions',
        daysRemaining: 4,
      ),
      CognitiveChallenge(
        id: 'c-03',
        title: 'Working Memory Depth',
        description: 'Achieve 7 consecutive flawless rounds in Matrix Recall.',
        domain: CognitiveDomain.memory,
        currentProgress: 7,
        targetProgress: 7,
        unit: 'rounds',
        daysRemaining: 1,
        isCompleted: true,
      ),
    ];
  }
}

/// Provider for the training repository.
final trainingRepositoryProvider = Provider<ITrainingRepository>(
  (ref) => const MockTrainingRepository(),
);

/// Provider for today's workout.
final todayWorkoutProvider = FutureProvider<DailyWorkout>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getTodayWorkout();
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
