import 'package:flutter/material.dart';

/// Primary cognitive faculties targeted by NEUROPLAY exercises.
enum CognitiveDomain {
  memory(
    'Memory',
    Icons.grid_view_rounded,
    'Retain and manipulate complex spatial and symbolic patterns',
  ),
  attention(
    'Focus & Attention',
    Icons.center_focus_strong_rounded,
    'Sustain selective focus under distracting visual stimuli',
  ),
  speed(
    'Processing Speed',
    Icons.speed_rounded,
    'Rapid sensory perception and precision motor response',
  ),
  flexibility(
    'Cognitive Flexibility',
    Icons.swap_horiz_rounded,
    'Switch between conflicting rule systems and mental sets',
  ),
  problemSolving(
    'Problem Solving',
    Icons.extension_rounded,
    'Deductive reasoning and optimal spatial planning',
  );

  const CognitiveDomain(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;

  static CognitiveDomain fromString(String val) {
    switch (val.toLowerCase()) {
      case 'memory':
        return CognitiveDomain.memory;
      case 'attention':
        return CognitiveDomain.attention;
      case 'speed':
        return CognitiveDomain.speed;
      case 'flexibility':
        return CognitiveDomain.flexibility;
      case 'problemsolving':
      case 'problem_solving':
        return CognitiveDomain.problemSolving;
      default:
        return CognitiveDomain.memory;
    }
  }
}

/// Metadata and configuration for a cognitive exercise.
class CognitiveGame {
  const CognitiveGame({
    required this.id,
    required this.slug,
    required this.title,
    required this.domain,
    required this.description,
    required this.instructions,
    required this.durationMinutes,
    required this.difficulty,
    this.route = '',
    this.isPreview = false,
  });

  final String id;
  final String slug;
  final String title;
  final CognitiveDomain domain;
  final String description;
  final String instructions;
  final int durationMinutes;
  final String difficulty;
  final String route;
  final bool isPreview;
}

/// A structured daily routine containing curated exercise modules.
class DailyWorkout {
  const DailyWorkout({
    required this.id,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.estimatedMinutes,
    required this.games,
    required this.domains,
    this.completedGameIds = const {},
    this.isCompleted = false,
  });

  final String id;
  final DateTime date;
  final String title;
  final String subtitle;
  final int estimatedMinutes;
  final List<CognitiveGame> games;
  final List<CognitiveDomain> domains;
  final Set<String> completedGameIds;
  final bool isCompleted;

  DailyWorkout copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? subtitle,
    int? estimatedMinutes,
    List<CognitiveGame>? games,
    List<CognitiveDomain>? domains,
    Set<String>? completedGameIds,
    bool? isCompleted,
  }) =>
      DailyWorkout(
        id: id ?? this.id,
        date: date ?? this.date,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        games: games ?? this.games,
        domains: domains ?? this.domains,
        completedGameIds: completedGameIds ?? this.completedGameIds,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

/// User's consecutive daily training streak.
class UserStreak {
  const UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.totalSessionsCompleted = 0,
    this.totalWorkoutsCompleted = 0,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalSessionsCompleted;
  final int totalWorkoutsCompleted;

  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    return lastActivityDate!.year == now.year &&
        lastActivityDate!.month == now.month &&
        lastActivityDate!.day == now.day;
  }

  static const empty = UserStreak(
    currentStreak: 0,
    longestStreak: 0,
  );
}

/// Single data point for longitudinal performance trends.
class DailyScorePoint {
  const DailyScorePoint({
    required this.dayLabel,
    required this.scoreIndex,
    required this.date,
    this.isCompletedDay = false,
  });

  final String dayLabel;
  final int scoreIndex; // 0-100 scale
  final DateTime date;
  final bool isCompletedDay;
}

/// Category-level score breakdown for progress analytics.
class DomainScore {
  const DomainScore({
    required this.domain,
    required this.scoreIndex,
    required this.trendPercentage,
    required this.percentileRank,
    this.sampleCount = 0,
  });

  final CognitiveDomain domain;
  final int scoreIndex; // 0-100
  final int trendPercentage; // e.g. +4%
  final int percentileRank; // e.g. 78th percentile
  final int sampleCount;
}

/// Overall aggregated cognitive statistics for dashboard display.
class OverallCognitiveStats {
  const OverallCognitiveStats({
    required this.overallBrainIndex,
    required this.streak,
    required this.domainScores,
    required this.weeklyTrend,
    required this.totalSessions,
    required this.totalWorkouts,
  });

  final int overallBrainIndex;
  final UserStreak streak;
  final List<DomainScore> domainScores;
  final List<DailyScorePoint> weeklyTrend;
  final int totalSessions;
  final int totalWorkouts;

  DomainScore? get bestFaculty {
    if (domainScores.isEmpty) return null;
    var best = domainScores.first;
    for (final ds in domainScores) {
      if (ds.scoreIndex > best.scoreIndex) best = ds;
    }
    return best;
  }

  static const empty = OverallCognitiveStats(
    overallBrainIndex: 50,
    streak: UserStreak.empty,
    domainScores: [],
    weeklyTrend: [],
    totalSessions: 0,
    totalWorkouts: 0,
  );
}

/// Active cognitive goals or community challenges.
class CognitiveChallenge {
  const CognitiveChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.currentProgress,
    required this.targetProgress,
    required this.unit,
    required this.daysRemaining,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final CognitiveDomain domain;
  final int currentProgress;
  final int targetProgress;
  final String unit;
  final int daysRemaining;
  final bool isCompleted;

  double get progressRatio => targetProgress > 0
      ? (currentProgress / targetProgress).clamp(0.0, 1.0)
      : 0.0;
}
