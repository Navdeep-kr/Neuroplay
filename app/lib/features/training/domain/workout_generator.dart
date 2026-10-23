import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Pure domain generator for structured daily workout routines.
abstract final class WorkoutGenerator {
  /// Available playable games catalog.
  static const List<CognitiveGame> catalog = [
    CognitiveGame(
      id: 'memory-matrix',
      slug: 'memory-matrix',
      title: 'Memory Matrix',
      domain: CognitiveDomain.memory,
      description:
          'Memorize briefly illuminated spatial grid patterns and reproduce their positions.',
      instructions:
          'Observe the illuminated tiles on the grid. Reproduce the exact positions after the pattern clears.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.memoryMatrix,
    ),
    CognitiveGame(
      id: 'reflex-forge',
      slug: 'reflex-forge',
      title: 'Reflex Forge',
      domain: CognitiveDomain.flexibility,
      description:
          'Match geometric symbols to dynamically shifting rules with speed and precision.',
      instructions:
          'Match symbols by shape or pattern depending on the active rule. Adapt swiftly when the rule shifts.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.reflexForge,
    ),
    CognitiveGame(
      id: 'focus-reactor',
      slug: 'focus-reactor',
      title: 'Focus Reactor',
      domain: CognitiveDomain.attention,
      description:
          'Identify designated target symbols amidst visual distractors or signal absence.',
      instructions:
          'Scan the array for the target item. Select the matching slot or declare absence when missing.',
      durationMinutes: 3,
      difficulty: 'Advanced',
      route: AppRoutes.focusReactor,
    ),
  ];

  static const List<String> _workoutTitles = [
    'Cognitive Agility Circuit',
    'Executive Working Memory Routine',
    'Focus & Neural Flexibility Sprint',
    'Working Memory & Selective Attention',
    'Comprehensive Neural Activation',
  ];

  static const List<String> _workoutSubtitles = [
    'Targeting spatial pattern recall, executive control, and distractor suppression.',
    'Strengthen working memory bandwidth and rapid task-switching precision.',
    'Sharpen selective visual search and cognitive flexibility under time pressure.',
    'Balanced tripartite protocol engaging memory, attention, and mental flexibility.',
  ];

  /// Generates a deterministic daily workout for the specified [date].
  static DailyWorkout generateDailyWorkout(
    DateTime date, {
    Set<String> completedGameIds = const {},
  }) {
    final daySeed = date.year * 10000 + date.month * 100 + date.day;
    final titleIndex = daySeed % _workoutTitles.length;
    final subtitleIndex = daySeed % _workoutSubtitles.length;

    // Deterministically order the 3 games based on date
    final permutationIndex = daySeed % 3;
    final List<CognitiveGame> orderedGames;
    switch (permutationIndex) {
      case 0:
        orderedGames = [catalog[0], catalog[1], catalog[2]];
        break;
      case 1:
        orderedGames = [catalog[2], catalog[0], catalog[1]];
        break;
      case 2:
      default:
        orderedGames = [catalog[1], catalog[2], catalog[0]];
        break;
    }

    final domains = orderedGames.map((g) => g.domain).toSet().toList();
    final isFullyCompleted =
        orderedGames.every((g) => completedGameIds.contains(g.id));

    return DailyWorkout(
      id: 'workout-${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      date: DateTime(date.year, date.month, date.day),
      title: _workoutTitles[titleIndex],
      subtitle: _workoutSubtitles[subtitleIndex],
      estimatedMinutes: 9,
      games: orderedGames,
      domains: domains,
      completedGameIds: completedGameIds,
      isCompleted: isFullyCompleted,
    );
  }
}
