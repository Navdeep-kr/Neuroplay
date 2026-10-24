import 'package:equatable/equatable.dart';

/// Single historical game session outcome with accuracy, duration, and latency.
class GameSessionRecord extends Equatable {
  const GameSessionRecord({
    required this.id,
    required this.gameId,
    required this.gameVersion,
    required this.score,
    required this.accuracy,
    required this.durationSeconds,
    required this.errorCount,
    required this.difficulty,
    required this.createdAt,
    this.medianReactionTimeMs,
    this.isPractice = false,
    this.isVerifiedCloud = true,
  });

  factory GameSessionRecord.fromJson(
    Map<String, dynamic> json, {
    bool isVerifiedCloud = true,
  }) {
    final metrics = (json['metrics'] as Map<String, dynamic>?) ?? {};
    int? medianRt;
    if (metrics['medianReactionTimeMs'] != null) {
      medianRt = (metrics['medianReactionTimeMs'] as num).toInt();
    } else if (metrics['medianResponseTimeMs'] != null) {
      medianRt = (metrics['medianResponseTimeMs'] as num).toInt();
    } else if (metrics['meanResponseTimeMs'] != null) {
      medianRt = (metrics['meanResponseTimeMs'] as num).toInt();
    }

    return GameSessionRecord(
      id: json['id'] as String? ??
          'session-${DateTime.now().millisecondsSinceEpoch}',
      gameId: json['game_id'] as String,
      gameVersion: json['game_version'] as String? ?? '1.0.0',
      score: (json['score'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 1.0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty'] as String? ??
          (metrics['difficulty'] as String?) ??
          'medium',
      medianReactionTimeMs: medianRt,
      isPractice: (json['is_practice'] as bool?) ?? false,
      isVerifiedCloud: isVerifiedCloud,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final String gameId;
  final String gameVersion;
  final int score;
  final double accuracy;
  final int durationSeconds;
  final int errorCount;
  final String difficulty;
  final int? medianReactionTimeMs;
  final bool isPractice;
  final bool isVerifiedCloud;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'game_id': gameId,
        'game_version': gameVersion,
        'score': score,
        'accuracy': accuracy,
        'duration_seconds': durationSeconds,
        'error_count': errorCount,
        'difficulty': difficulty,
        'median_reaction_time_ms': medianReactionTimeMs,
        'is_practice': isPractice,
        'is_verified_cloud': isVerifiedCloud,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        gameId,
        gameVersion,
        score,
        accuracy,
        durationSeconds,
        errorCount,
        difficulty,
        medianReactionTimeMs,
        isPractice,
        isVerifiedCloud,
        createdAt,
      ];
}

/// Aggregated personal best metrics for a specific game.
class GamePersonalBest extends Equatable {
  const GamePersonalBest({
    required this.gameId,
    required this.gameTitle,
    required this.highestScore,
    required this.highestAccuracy,
    required this.totalSessions,
    this.fastestMedianRtMs,
    this.lastPlayedAt,
  });

  factory GamePersonalBest.empty(String gameId, String gameTitle) =>
      GamePersonalBest(
        gameId: gameId,
        gameTitle: gameTitle,
        highestScore: 0,
        highestAccuracy: 0,
        totalSessions: 0,
      );

  final String gameId;
  final String gameTitle;
  final int highestScore;
  final double highestAccuracy;
  final int? fastestMedianRtMs;
  final int totalSessions;
  final DateTime? lastPlayedAt;

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'game_title': gameTitle,
        'highest_score': highestScore,
        'highest_accuracy': highestAccuracy,
        'fastest_median_rt_ms': fastestMedianRtMs,
        'total_sessions': totalSessions,
        'last_played_at': lastPlayedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        gameId,
        gameTitle,
        highestScore,
        highestAccuracy,
        fastestMedianRtMs,
        totalSessions,
        lastPlayedAt,
      ];
}

/// Calendar record for a single day of training.
class ActivityDayRecord extends Equatable {
  const ActivityDayRecord({
    required this.date,
    required this.sessionsCount,
    required this.durationMinutes,
    required this.xpEarned,
    this.workoutCompleted = false,
  });

  factory ActivityDayRecord.fromJson(Map<String, dynamic> json) =>
      ActivityDayRecord(
        date: DateTime.parse(json['activity_date'] as String),
        sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
        xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
        workoutCompleted: (json['workout_completed'] as bool?) ?? false,
      );

  final DateTime date;
  final int sessionsCount;
  final int durationMinutes;
  final int xpEarned;
  final bool workoutCompleted;

  bool get hasActivity => sessionsCount > 0 || workoutCompleted;

  Map<String, dynamic> toJson() => {
        'activity_date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'sessions_count': sessionsCount,
        'duration_minutes': durationMinutes,
        'xp_earned': xpEarned,
        'workout_completed': workoutCompleted,
      };

  @override
  List<Object?> get props => [
        date,
        sessionsCount,
        durationMinutes,
        xpEarned,
        workoutCompleted,
      ];
}

/// Log of an individual XP granting event.
class XpEventRecord extends Equatable {
  const XpEventRecord({
    required this.id,
    required this.amount,
    required this.source,
    required this.description,
    required this.createdAt,
  });

  factory XpEventRecord.fromJson(Map<String, dynamic> json) => XpEventRecord(
        id: json['id'] as String? ?? '',
        amount: (json['xp_amount'] as num?)?.toInt() ?? 0,
        source: json['source'] as String? ?? 'general',
        description: json['description'] as String? ?? 'Training activity',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  final String id;
  final int amount;
  final String source;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'xp_amount': amount,
        'source': source,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, amount, source, description, createdAt];
}

/// High-level XP progression and tier state.
class UserXpState extends Equatable {
  const UserXpState({
    required this.totalXp,
    required this.currentLevel,
    required this.levelTitle,
    required this.xpForCurrentLevel,
    required this.xpToNextLevel,
    required this.progressPercent,
    this.recentEvents = const [],
  });

  factory UserXpState.initial() => const UserXpState(
        totalXp: 0,
        currentLevel: 1,
        levelTitle: 'Initiate',
        xpForCurrentLevel: 0,
        xpToNextLevel: 200,
        progressPercent: 0,
      );

  factory UserXpState.fromSummary({
    required int totalXp,
    List<XpEventRecord> recentEvents = const [],
  }) {
    // Standard progression curve: Level = 1 + floor(sqrt(totalXp / 100))
    // Each level requires: nextThreshold = (Level)^2 * 100
    // Current base threshold = (Level - 1)^2 * 100
    var level = 1;
    var baseThreshold = 0;
    var nextThreshold = 200;

    while (totalXp >= nextThreshold) {
      level++;
      baseThreshold = nextThreshold;
      nextThreshold = level * level * 100 + 100;
    }

    final span = nextThreshold - baseThreshold;
    final progressInLevel = (totalXp - baseThreshold).clamp(0, span);
    final percent = span > 0 ? (progressInLevel / span).clamp(0.0, 1.0) : 0.0;

    final title = switch (level) {
      1 => 'Novice Practitioner',
      2 => 'Focused Explorer',
      3 => 'Cognitive Adept',
      4 => 'Mental Strategist',
      5 => 'Synapse Master',
      _ => 'Grandmaster ($level)',
    };

    return UserXpState(
      totalXp: totalXp,
      currentLevel: level,
      levelTitle: title,
      xpForCurrentLevel: totalXp - baseThreshold,
      xpToNextLevel: nextThreshold - totalXp,
      progressPercent: percent,
      recentEvents: recentEvents,
    );
  }

  final int totalXp;
  final int currentLevel;
  final String levelTitle;
  final int xpForCurrentLevel;
  final int xpToNextLevel;
  final double progressPercent;
  final List<XpEventRecord> recentEvents;

  Map<String, dynamic> toJson() => {
        'total_xp': totalXp,
        'current_level': currentLevel,
        'level_title': levelTitle,
        'xp_for_current_level': xpForCurrentLevel,
        'xp_to_next_level': xpToNextLevel,
        'progress_percent': progressPercent,
        'recent_events': recentEvents.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        totalXp,
        currentLevel,
        levelTitle,
        xpForCurrentLevel,
        xpToNextLevel,
        progressPercent,
        recentEvents,
      ];
}

/// Achievement catalog item with unlock state.
class AchievementItem extends Equatable {
  const AchievementItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.badgeIcon,
    required this.xpReward,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory AchievementItem.fromJson(
    Map<String, dynamic> json, {
    bool isUnlocked = false,
    DateTime? unlockedAt,
  }) =>
      AchievementItem(
        id: json['id'] as String? ?? json['code'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String? ?? 'general',
        badgeIcon: json['badge_icon'] as String? ?? 'military_tech',
        xpReward: (json['xp_reward'] as num?)?.toInt() ?? 50,
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAt,
      );

  final String id;
  final String code;
  final String title;
  final String description;
  final String category;
  final String badgeIcon;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'category': category,
        'badge_icon': badgeIcon,
        'xp_reward': xpReward,
        'is_unlocked': isUnlocked,
        'unlocked_at': unlockedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        code,
        title,
        description,
        category,
        badgeIcon,
        xpReward,
        isUnlocked,
        unlockedAt,
      ];
}

/// Historical summary of a completed or scheduled workout.
class WorkoutSummaryRecord extends Equatable {
  const WorkoutSummaryRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.gameIds,
    required this.completedGameIds,
    required this.isCompleted,
    required this.durationMinutes,
  });

  factory WorkoutSummaryRecord.fromJson(Map<String, dynamic> json) {
    final gIds = (json['game_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final cIds = (json['completed_game_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return WorkoutSummaryRecord(
      id: json['id'] as String? ?? '',
      date: json['workout_date'] != null
          ? DateTime.parse(json['workout_date'] as String)
          : DateTime.now(),
      title: json['title'] as String? ?? 'Daily Workout',
      gameIds: gIds,
      completedGameIds: cIds,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      durationMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 9,
    );
  }

  final String id;
  final DateTime date;
  final String title;
  final List<String> gameIds;
  final List<String> completedGameIds;
  final bool isCompleted;
  final int durationMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'game_ids': gameIds,
        'completed_game_ids': completedGameIds,
        'is_completed': isCompleted,
        'duration_minutes': durationMinutes,
      };

  @override
  List<Object?> get props => [
        id,
        date,
        title,
        gameIds,
        completedGameIds,
        isCompleted,
        durationMinutes,
      ];
}
