import 'package:game_engine/src/adaptive/adaptive_models.dart';
import 'package:game_engine/src/adaptive/adaptive_rules.dart';
import 'package:game_engine/src/contracts/game_difficulty.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';

/// Transparent, deterministic adaptive difficulty engine for NEUROPLAY.
///
/// Principles:
/// 1. Smooth, damped rating updates preventing single-session wild oscillations.
/// 2. Game-specific bounded evaluations (accuracy vs. robust reaction times).
/// 3. Hysteresis on difficulty tier boundaries to prevent flip-flopping.
/// 4. Full explainability: every adjustment stores human-readable reasoning and metrics.
/// 5. Non-clinical boundary: derived skill estimates are explicitly non-diagnostic.
final class AdaptiveDifficultyEngine {
  AdaptiveDifficultyEngine({
    this.algorithmVersion = '1.0.0',
    Map<String, GameDifficultyRule>? customRules,
  }) : _rules = customRules ?? _defaultRules;

  static const String currentVersion = '1.0.0';

  /// Maximum absolute rating points a single session can alter the user's rating.
  static const double maxDeltaPerSession = 6.0;

  /// Exponential smoothing damping factor (alpha).
  static const double smoothingAlpha = 0.25;

  final String algorithmVersion;
  final Map<String, GameDifficultyRule> _rules;

  static const Map<String, GameDifficultyRule> _defaultRules = {
    'memory-matrix': MemoryMatrixDifficultyRule(),
    'reflex-forge': ReflexForgeDifficultyRule(),
    'focus-reactor': FocusReactorDifficultyRule(),
    'logic-labyrinth': LogicLabyrinthDifficultyRule(),
    'number-pulse': NumberPulseDifficultyRule(),
    'word-weaver': WordWeaverDifficultyRule(),
  };

  /// Singleton default engine instance.
  static final defaultEngine = AdaptiveDifficultyEngine();

  /// Static convenience evaluator using the default rules.
  static ({SkillEstimate updatedEstimate, DifficultyAdjustment adjustment})
      evaluate({
    required GameResult result,
    SkillEstimate? existingEstimate,
    SkillEstimate? currentEstimate,
  }) =>
          defaultEngine.evaluateSession(
            result: result,
            currentEstimate: existingEstimate ?? currentEstimate,
          );

  /// Evaluates an incoming [result] against the user's existing [currentEstimate]
  /// and produces an updated [SkillEstimate] along with an audit [DifficultyAdjustment].
  ({SkillEstimate updatedEstimate, DifficultyAdjustment adjustment})
      evaluateSession({
    required GameResult result,
    SkillEstimate? currentEstimate,
  }) {
    final now = DateTime.now();
    final gameId = result.gameId;
    final estimate = currentEstimate ??
        SkillEstimate.initial(
          gameId,
          algorithmVersion: algorithmVersion,
        );

    // 1. Guard against invalid or un-rateable sessions
    final invalidReason = _checkSessionValidity(result);
    if (invalidReason != null) {
      final noOpAdjustment = DifficultyAdjustment(
        algorithmVersion: algorithmVersion,
        gameId: gameId,
        previousDifficulty: estimate.recommendedDifficulty,
        newDifficulty: estimate.recommendedDifficulty,
        previousRating: estimate.rating,
        newRating: estimate.rating,
        ratingDelta: 0.0,
        reason: invalidReason,
        isDamped: false,
        metricsSnapshot: result.metrics,
        timestamp: now,
      );
      return (updatedEstimate: estimate, adjustment: noOpAdjustment);
    }

    // 2. Compute game-specific performance index [0.0 - 100.0]
    final rule = _rules[gameId] ?? const MemoryMatrixDifficultyRule();
    final performanceIndex = rule.evaluatePerformance(result);

    // 3. Extract accuracy and response metrics
    final accuracy = (result.metrics['accuracy'] as num?)?.toDouble() ??
        (result.metrics['accuracyPercent'] != null
            ? (result.metrics['accuracyPercent'] as num).toDouble() / 100.0
            : 0.5);

    // 4. Update streaks
    var consecutiveStrong = estimate.consecutiveStrongSessions;
    var consecutiveWeak = estimate.consecutiveWeakSessions;
    if (accuracy >= 0.85) {
      consecutiveStrong++;
      consecutiveWeak = 0;
    } else if (accuracy < 0.60) {
      consecutiveWeak++;
      consecutiveStrong = 0;
    } else {
      consecutiveStrong = 0;
      consecutiveWeak = 0;
    }

    // 5. Exponential smoothing and step damping
    final prevRating = estimate.rating;
    final rawDelta = (performanceIndex - prevRating) * smoothingAlpha;
    final isDamped = rawDelta.abs() > maxDeltaPerSession;
    final clampedDelta =
        rawDelta.clamp(-maxDeltaPerSession, maxDeltaPerSession);
    final newRating = (prevRating + clampedDelta).clamp(10.0, 95.0);

    // 6. Map continuous rating to discrete difficulty using hysteresis
    final newDifficulty = _determineDifficultyWithHysteresis(
      previousDifficulty: estimate.recommendedDifficulty,
      newRating: newRating,
      consecutiveStrong: consecutiveStrong,
      consecutiveWeak: consecutiveWeak,
    );

    // 7. Formulate human-readable explanation
    final reason = _generateAdjustmentReason(
      previousDifficulty: estimate.recommendedDifficulty,
      newDifficulty: newDifficulty,
      previousRating: prevRating,
      newRating: newRating,
      accuracy: accuracy,
      performanceIndex: performanceIndex,
      isDamped: isDamped,
    );

    final updatedEstimate = estimate.copyWith(
      rating: double.parse(newRating.toStringAsFixed(1)),
      recommendedDifficulty: newDifficulty,
      sampleCount: estimate.sampleCount + 1,
      consecutiveStrongSessions: consecutiveStrong,
      consecutiveWeakSessions: consecutiveWeak,
      lastAdjustmentReason: reason,
      algorithmVersion: algorithmVersion,
      lastAdjustedAt: now,
    );

    final adjustment = DifficultyAdjustment(
      algorithmVersion: algorithmVersion,
      gameId: gameId,
      previousDifficulty: estimate.recommendedDifficulty,
      newDifficulty: newDifficulty,
      previousRating: prevRating,
      newRating: newRating,
      ratingDelta: double.parse(clampedDelta.toStringAsFixed(1)),
      reason: reason,
      isDamped: isDamped,
      metricsSnapshot: {
        ...result.metrics,
        'performanceIndex': performanceIndex,
      },
      timestamp: now,
    );

    return (updatedEstimate: updatedEstimate, adjustment: adjustment);
  }

  /// Maps continuous rating to bounded discrete difficulty with hysteresis.
  GameDifficulty _determineDifficultyWithHysteresis({
    required GameDifficulty previousDifficulty,
    required double newRating,
    required int consecutiveStrong,
    required int consecutiveWeak,
  }) {
    switch (previousDifficulty) {
      case GameDifficulty.easy:
        // Promote if rating >= 42.0 OR 2 consecutive strong sessions with rating >= 38
        if (newRating >= 42.0 ||
            (consecutiveStrong >= 2 && newRating >= 38.0)) {
          return GameDifficulty.medium;
        }
        return GameDifficulty.easy;

      case GameDifficulty.medium:
        // Demote to easy if rating < 38.0
        if (newRating < 38.0) {
          return GameDifficulty.easy;
        }
        // Promote to hard if rating >= 68.0 OR 2 consecutive strong with rating >= 64
        if (newRating >= 68.0 ||
            (consecutiveStrong >= 2 && newRating >= 64.0)) {
          return GameDifficulty.hard;
        }
        return GameDifficulty.medium;

      case GameDifficulty.hard:
        // Demote to medium if rating < 62.0
        if (newRating < 62.0) {
          return GameDifficulty.medium;
        }
        // Promote to expert if rating >= 87.0 AND at least 2 consecutive strong sessions
        if (newRating >= 87.0 && consecutiveStrong >= 2) {
          return GameDifficulty.expert;
        }
        return GameDifficulty.hard;

      case GameDifficulty.expert:
        // Demote to hard if rating < 82.0 OR 2 consecutive weak sessions
        if (newRating < 82.0 || consecutiveWeak >= 2) {
          return GameDifficulty.hard;
        }
        return GameDifficulty.expert;
      default:
        return previousDifficulty;
    }
  }

  /// Checks if a session should be evaluated or safely ignored.
  String? _checkSessionValidity(GameResult result) {
    if (result.metrics['isPractice'] == true) {
      return 'Practice mode session: skill rating not adjusted';
    }
    if (result.completionPhase != GamePhase.completed) {
      return 'Interrupted or aborted session: skill rating unchanged';
    }
    if (result.totalActiveDuration < const Duration(seconds: 2)) {
      return 'Session duration below minimum valid threshold (<2s)';
    }
    return null;
  }

  /// Formulates human-understandable explanation for why difficulty adjusted.
  String _generateAdjustmentReason({
    required GameDifficulty previousDifficulty,
    required GameDifficulty newDifficulty,
    required double previousRating,
    required double newRating,
    required double accuracy,
    required double performanceIndex,
    required bool isDamped,
  }) {
    final accPct = (accuracy * 100).round();
    final delta = (newRating - previousRating).abs().toStringAsFixed(1);

    if (newDifficulty != previousDifficulty) {
      if (newDifficulty.level > previousDifficulty.level) {
        return 'Consistent strong performance ($accPct% accuracy); graduated from '
            '${previousDifficulty.displayName} to ${newDifficulty.displayName}.';
      } else {
        return 'Struggled on recent trials ($accPct% accuracy); adjusted down from '
            '${previousDifficulty.displayName} to ${newDifficulty.displayName} to rebuild baseline mastery.';
      }
    }

    if (newRating > previousRating) {
      return 'Solid performance ($accPct% accuracy); rating increased by $delta pts '
          '(maintained ${newDifficulty.displayName}).';
    } else if (newRating < previousRating) {
      return 'Inconsistent accuracy ($accPct%); rating decreased by $delta pts '
          '(maintained ${newDifficulty.displayName}).';
    } else {
      return 'Stable performance ($accPct% accuracy); difficulty maintained at '
          '${newDifficulty.displayName}.';
    }
  }
}
