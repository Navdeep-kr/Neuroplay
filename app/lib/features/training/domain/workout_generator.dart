import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';
import 'package:neuroplay/features/training/domain/workout_selection_policy.dart';

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
    CognitiveGame(
      id: 'logic-labyrinth',
      slug: 'logic-labyrinth',
      title: 'Logic Labyrinth',
      domain: CognitiveDomain.problemSolving,
      description:
          'Plan and navigate optimal paths through spatial mazes with obstacles and checkpoints.',
      instructions:
          'Determine the shortest route to the exit. Collect the key checkpoint if present and reach the goal.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.logicLabyrinth,
    ),
    CognitiveGame(
      id: 'number-pulse',
      slug: 'number-pulse',
      title: 'Number Pulse',
      domain: CognitiveDomain.speed,
      description:
          'Rapid mental arithmetic and numerical sequence recognition under time pressure.',
      instructions:
          'Observe the numerical sequence. Calculate the missing number and choose the correct answer swiftly.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.numberPulse,
    ),
    CognitiveGame(
      id: 'word-weaver',
      slug: 'word-weaver',
      title: 'Word Weaver',
      domain: CognitiveDomain.memory,
      description:
          'Rapid semantic association and vocabulary organization under cognitive load.',
      instructions:
          'Inspect the anchor word. Identify the matching term from the same conceptual category.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.wordWeaver,
    ),
    CognitiveGame(
      id: 'echo-sequence',
      slug: 'echo-sequence',
      title: 'Echo Sequence',
      domain: CognitiveDomain.memory,
      description:
          'Dual N-Back working memory: recall positions and cues presented N steps back.',
      instructions:
          'Watch the sequence of flashing tiles. Tap Match when the current tile matches the one shown N steps earlier.',
      durationMinutes: 3,
      difficulty: 'Advanced',
      route: AppRoutes.echoSequence,
    ),
    CognitiveGame(
      id: 'constellation-recall',
      slug: 'constellation-recall',
      title: 'Constellation Recall',
      domain: CognitiveDomain.memory,
      description:
          'Memorize celestial star configurations and identify relocated star coordinates.',
      instructions:
          'Observe the star pattern for 3 seconds. Tap the exact star that shifted after the screen resets.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.constellationRecall,
    ),
    CognitiveGame(
      id: 'trailblazer',
      slug: 'trailblazer',
      title: 'Trailblazer',
      domain: CognitiveDomain.flexibility,
      description:
          'Connect alternating number and letter nodes (1 -> A -> 2 -> B) with rapid precision.',
      instructions:
          'Tap scattered nodes in alternating order: 1, then A, then 2, then B, and so forth.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.trailblazer,
    ),
    CognitiveGame(
      id: 'prism-shift',
      slug: 'prism-shift',
      title: 'Prism Shift',
      domain: CognitiveDomain.flexibility,
      description:
          'Stroop-effect executive conflict: switch between matching ink color and printed word.',
      instructions:
          'Look at the rule header. Select either the written word or the font ink color depending on active rule.',
      durationMinutes: 3,
      difficulty: 'Advanced',
      route: AppRoutes.prismShift,
    ),
    CognitiveGame(
      id: 'tracker-horizon',
      slug: 'tracker-horizon',
      title: 'Tracker Horizon',
      domain: CognitiveDomain.attention,
      description:
          'Multiple Object Tracking: follow designated moving targets across dynamic trajectories.',
      instructions:
          'Observe the highlighted spheres before they move. Keep your eye on them and tap them when movement stops.',
      durationMinutes: 3,
      difficulty: 'Advanced',
      route: AppRoutes.trackerHorizon,
    ),
    CognitiveGame(
      id: 'flanker-strike',
      slug: 'flanker-strike',
      title: 'Flanker Strike',
      domain: CognitiveDomain.attention,
      description:
          'Eriksen Flanker task: indicate center arrow direction while ignoring distractor arrows.',
      instructions:
          'Look solely at the central arrow in the row. Swipe or tap left/right to match its orientation.',
      durationMinutes: 2,
      difficulty: 'Intermediate',
      route: AppRoutes.flankerStrike,
    ),
    CognitiveGame(
      id: 'scale-balance',
      slug: 'scale-balance',
      title: 'Scale Balance',
      domain: CognitiveDomain.speed,
      description:
          'Quantitative magnitude comparison: evaluate arithmetic scales under rapid time pressure.',
      instructions:
          'Assess the math expressions on left and right pans. Tap the heavier side or Equal.',
      durationMinutes: 2,
      difficulty: 'Intermediate',
      route: AppRoutes.scaleBalance,
    ),
    CognitiveGame(
      id: 'flow-math',
      slug: 'flow-math',
      title: 'Flow Math',
      domain: CognitiveDomain.speed,
      description:
          'Mental arithmetic constraint satisfaction: deduce missing operators to balance equations.',
      instructions:
          'Identify which mathematical operation (+, -, *, /) makes the equation true before time expires.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.flowMath,
    ),
    CognitiveGame(
      id: 'origami-unfold',
      slug: 'origami-unfold',
      title: 'Origami Unfold',
      domain: CognitiveDomain.problemSolving,
      description:
          'Spatial rotation & mental paper folding: predict hole locations when unfolded.',
      instructions:
          'Observe the folded sheet and hole punch. Choose which unfolded sheet matches the opened paper.',
      durationMinutes: 3,
      difficulty: 'Advanced',
      route: AppRoutes.origamiUnfold,
    ),
    CognitiveGame(
      id: 'tower-of-chronos',
      slug: 'tower-of-chronos',
      title: 'Tower of Chronos',
      domain: CognitiveDomain.problemSolving,
      description:
          'Sequential planning: transfer disc stacks across three pegs to match the target goal.',
      instructions:
          'Tap source and destination pegs to move discs. Match the target tower using the fewest moves possible.',
      durationMinutes: 3,
      difficulty: 'Advanced',
      route: AppRoutes.towerOfChronos,
    ),
    CognitiveGame(
      id: 'semantic-bridge',
      slug: 'semantic-bridge',
      title: 'Semantic Bridge',
      domain: CognitiveDomain.memory,
      description:
          'Remote association: discover the single unifying term connecting three disparate word cues.',
      instructions:
          'Read the three prompt words. Determine the single word that connects all three concepts.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.semanticBridge,
    ),
    CognitiveGame(
      id: 'word-rapids',
      slug: 'word-rapids',
      title: 'Word Rapids',
      domain: CognitiveDomain.speed,
      description:
          'Lexical agility: construct valid English words from incoming letter streams under time pressure.',
      instructions:
          'Select scrolling letter tiles to spell valid words. Submit longer words for massive bonus multipliers.',
      durationMinutes: 3,
      difficulty: 'Intermediate',
      route: AppRoutes.wordRapids,
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
    Map<String, SkillEstimate> skillProfiles = const {},
    List<Set<String>> recentCombinations = const [],
    Set<CognitiveDomain> preferredDomains = const {},
  }) {
    final daySeed = date.year * 10000 + date.month * 100 + date.day;
    final titleIndex = daySeed % _workoutTitles.length;
    final subtitleIndex = daySeed % _workoutSubtitles.length;

    final assignments = WorkoutSelectionPolicy.selectWorkoutGames(
      catalog: catalog,
      date: date,
      skillProfiles: skillProfiles,
      recentCombinations: recentCombinations,
      preferredDomains: preferredDomains,
      completedGameIds: completedGameIds,
    );

    final orderedGames = assignments.map((a) => a.game).toList();
    final domains = orderedGames.map((g) => g.domain).toSet().toList();
    final isFullyCompleted = orderedGames.isNotEmpty &&
        orderedGames.every((g) => completedGameIds.contains(g.id));

    return DailyWorkout(
      id: 'workout-${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      date: DateTime(date.year, date.month, date.day),
      title: _workoutTitles[titleIndex],
      subtitle: _workoutSubtitles[subtitleIndex],
      estimatedMinutes: 9,
      games: orderedGames,
      domains: domains,
      assignments: assignments,
      completedGameIds: completedGameIds,
      isCompleted: isFullyCompleted,
    );
  }
}
