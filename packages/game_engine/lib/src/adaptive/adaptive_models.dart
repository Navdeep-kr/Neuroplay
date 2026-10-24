import 'package:equatable/equatable.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:meta/meta.dart';

/// Derived, calibrated user skill rating for a specific cognitive game.
///
/// NOTE: Game-derived skill estimates represent performance in specific
/// computer-based training tasks. They are NOT clinical assessments,
/// medical diagnostics, or measures of general intelligence / IQ.
@immutable
final class SkillEstimate extends Equatable {
  SkillEstimate({
    required this.gameId,
    double? rating,
    double? continuousRating,
    required this.recommendedDifficulty,
    this.sampleCount = 0,
    this.consecutiveStrongSessions = 0,
    this.consecutiveWeakSessions = 0,
    this.lastAdjustmentReason = 'Calibrated rating',
    this.algorithmVersion = '1.0.0',
    DateTime? lastAdjustedAt,
    DateTime? lastUpdatedAt,
  })  : rating = rating ?? continuousRating ?? 50.0,
        lastAdjustedAt = lastAdjustedAt ?? lastUpdatedAt ?? DateTime.now();

  /// Factory for a brand-new user or unplayed game baseline.
  factory SkillEstimate.initial(
    String gameId, {
    GameDifficulty defaultDifficulty = GameDifficulty.medium,
    String algorithmVersion = '1.0.0',
  }) {
    return SkillEstimate(
      gameId: gameId,
      rating: 50.0,
      recommendedDifficulty: defaultDifficulty,
      sampleCount: 0,
      consecutiveStrongSessions: 0,
      consecutiveWeakSessions: 0,
      lastAdjustmentReason: 'Initial baseline calibrated for new player',
      algorithmVersion: algorithmVersion,
      lastAdjustedAt: DateTime.now(),
    );
  }

  factory SkillEstimate.fromJson(Map<String, dynamic> json) {
    return SkillEstimate(
      gameId: json['gameId'] as String,
      rating: (json['rating'] as num).toDouble(),
      recommendedDifficulty:
          GameDifficulty.fromJson(json['recommendedDifficulty']),
      sampleCount: json['sampleCount'] as int? ?? 0,
      consecutiveStrongSessions: json['consecutiveStrongSessions'] as int? ?? 0,
      consecutiveWeakSessions: json['consecutiveWeakSessions'] as int? ?? 0,
      lastAdjustmentReason: json['lastAdjustmentReason'] as String? ?? '',
      algorithmVersion: json['algorithmVersion'] as String? ?? '1.0.0',
      lastAdjustedAt: DateTime.parse(json['lastAdjustedAt'] as String),
    );
  }

  /// Explicit ethical and scientific boundary disclaimer.
  static const String nonClinicalDisclaimer =
      'Skill estimates reflect task-specific calibrated performance in NEUROPLAY '
      'exercises and are strictly non-clinical, non-diagnostic metrics that do not '
      'measure IQ, general intelligence, or clinical cognitive impairment.';

  /// Instance accessor for the non-clinical disclaimer.
  String get disclaimer => nonClinicalDisclaimer;

  final String gameId;

  /// Continuous skill rating from 0.0 to 100.0.
  final double rating;

  /// Alias for continuous skill rating.
  double get continuousRating => rating;

  /// Discrete difficulty level recommended for the next session.
  final GameDifficulty recommendedDifficulty;

  /// Total number of valid sessions factored into this estimate.
  final int sampleCount;

  /// Streak of sessions exceeding target performance (accuracy >= 85%).
  final int consecutiveStrongSessions;

  /// Streak of sessions underperforming target threshold (accuracy < 60%).
  final int consecutiveWeakSessions;

  /// Transparent human-readable explanation of the latest adjustment.
  final String lastAdjustmentReason;

  /// Version of the adaptive difficulty algorithm that produced this rating.
  final String algorithmVersion;

  /// Timestamp of the last adjustment.
  final DateTime lastAdjustedAt;

  /// Alias for last adjustment timestamp.
  DateTime get lastUpdatedAt => lastAdjustedAt;

  SkillEstimate copyWith({
    String? gameId,
    double? rating,
    GameDifficulty? recommendedDifficulty,
    int? sampleCount,
    int? consecutiveStrongSessions,
    int? consecutiveWeakSessions,
    String? lastAdjustmentReason,
    String? algorithmVersion,
    DateTime? lastAdjustedAt,
  }) {
    return SkillEstimate(
      gameId: gameId ?? this.gameId,
      rating: rating ?? this.rating,
      recommendedDifficulty:
          recommendedDifficulty ?? this.recommendedDifficulty,
      sampleCount: sampleCount ?? this.sampleCount,
      consecutiveStrongSessions:
          consecutiveStrongSessions ?? this.consecutiveStrongSessions,
      consecutiveWeakSessions:
          consecutiveWeakSessions ?? this.consecutiveWeakSessions,
      lastAdjustmentReason: lastAdjustmentReason ?? this.lastAdjustmentReason,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      lastAdjustedAt: lastAdjustedAt ?? this.lastAdjustedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'rating': rating,
        'recommendedDifficulty': recommendedDifficulty.name,
        'sampleCount': sampleCount,
        'consecutiveStrongSessions': consecutiveStrongSessions,
        'consecutiveWeakSessions': consecutiveWeakSessions,
        'lastAdjustmentReason': lastAdjustmentReason,
        'algorithmVersion': algorithmVersion,
        'lastAdjustedAt': lastAdjustedAt.toIso8601String(),
        'disclaimer': nonClinicalDisclaimer,
      };

  @override
  List<Object?> get props => [
        gameId,
        rating,
        recommendedDifficulty,
        sampleCount,
        consecutiveStrongSessions,
        consecutiveWeakSessions,
        lastAdjustmentReason,
        algorithmVersion,
        lastAdjustedAt,
      ];
}

/// An audit entry recording a single difficulty evaluation and its rationale.
@immutable
final class DifficultyAdjustment extends Equatable {
  const DifficultyAdjustment({
    required this.algorithmVersion,
    required this.gameId,
    required this.previousDifficulty,
    required this.newDifficulty,
    required this.previousRating,
    required this.newRating,
    required this.ratingDelta,
    required this.reason,
    required this.isDamped,
    required this.metricsSnapshot,
    required this.timestamp,
  });

  factory DifficultyAdjustment.fromJson(Map<String, dynamic> json) {
    return DifficultyAdjustment(
      algorithmVersion: json['algorithmVersion'] as String,
      gameId: json['gameId'] as String,
      previousDifficulty: GameDifficulty.fromJson(json['previousDifficulty']),
      newDifficulty: GameDifficulty.fromJson(json['newDifficulty']),
      previousRating: (json['previousRating'] as num).toDouble(),
      newRating: (json['newRating'] as num).toDouble(),
      ratingDelta: (json['ratingDelta'] as num).toDouble(),
      reason: json['reason'] as String,
      isDamped: json['isDamped'] as bool? ?? false,
      metricsSnapshot:
          (json['metricsSnapshot'] as Map<String, dynamic>?) ?? const {},
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  final String algorithmVersion;
  final String gameId;
  final GameDifficulty previousDifficulty;
  final GameDifficulty newDifficulty;
  final double previousRating;
  final double newRating;
  final double ratingDelta;
  final String reason;
  final bool isDamped;
  final Map<String, dynamic> metricsSnapshot;
  final DateTime timestamp;

  bool get changedDifficulty => previousDifficulty != newDifficulty;

  Map<String, dynamic> toJson() => {
        'algorithmVersion': algorithmVersion,
        'gameId': gameId,
        'previousDifficulty': previousDifficulty.name,
        'newDifficulty': newDifficulty.name,
        'previousRating': previousRating,
        'newRating': newRating,
        'ratingDelta': ratingDelta,
        'reason': reason,
        'isDamped': isDamped,
        'metricsSnapshot': metricsSnapshot,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        algorithmVersion,
        gameId,
        previousDifficulty,
        newDifficulty,
        previousRating,
        newRating,
        ratingDelta,
        reason,
        isDamped,
        metricsSnapshot,
        timestamp,
      ];
}
