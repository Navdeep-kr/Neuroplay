import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_actions.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_config.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_models.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_scoring.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_state.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Headless deterministic state machine for Focus Reactor.
final class FocusReactorGameEngine extends GameEngineBase {
  FocusReactorGameEngine({
    required FocusReactorConfig super.config,
    this.scoringRules = const FocusReactorScoringRules(),
  }) : reactorConfig = config;

  final FocusReactorConfig reactorConfig;
  final FocusReactorScoringRules scoringRules;

  late FocusReactorTrialState trialState;
  Duration? lastTrialStartedAt;

  int hits = 0;
  int correctRejections = 0;
  int falseAlarms = 0;
  int misses = 0;
  final List<int> responseTimesMs = [];

  @override
  String get gameId => 'focus-reactor';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    _generateTrial(1, baseTimestamp: Duration.zero);
  }

  void _generateTrial(int roundNumber, {required Duration baseTimestamp}) {
    final allShapes = List<FocusShape>.from(FocusShape.values);
    final allMarkers = List<FocusMarker>.from(FocusMarker.values);

    // Pick target specification
    final targetShape = random.choice(allShapes);
    final targetMarker = random.choice(allMarkers);
    final targetItem = FocusItem(shape: targetShape, marker: targetMarker);

    // Determine if target should be present in this trial
    final isPresent = random.nextDouble() < reactorConfig.targetPresenceRatio;

    final displayed = <FocusItem>[];
    int? targetIndex;

    final availableShapes = allShapes.where((s) => s != targetShape).toList();

    if (isPresent) {
      targetIndex = random.nextInt(reactorConfig.displaySlots);
      for (var i = 0; i < reactorConfig.displaySlots; i++) {
        if (i == targetIndex) {
          displayed.add(targetItem);
        } else {
          // Distractor: either different shape or same shape with different marker
          final distractorShape = random.choice(availableShapes);
          final distractorMarker = random.choice(allMarkers);
          displayed
              .add(FocusItem(shape: distractorShape, marker: distractorMarker));
        }
      }
    } else {
      targetIndex = null;
      for (var i = 0; i < reactorConfig.displaySlots; i++) {
        final distractorShape = random.choice(availableShapes);
        final distractorMarker = random.choice(allMarkers);
        displayed
            .add(FocusItem(shape: distractorShape, marker: distractorMarker));
      }
    }

    trialState = FocusReactorTrialState(
      targetItem: targetItem,
      displayedItems: displayed,
      targetSlotIndex: targetIndex,
    );

    lastTrialStartedAt = baseTimestamp;

    state = state.copyWith(
      currentRound: roundNumber,
      customData: {
        'trialState': trialState.toJson(),
      },
    );
  }

  @override
  GameState processAction(GameState currentState, GameAction action) {
    final reactionTimeMs = lastTrialStartedAt != null
        ? math.max(50, (action.timestamp - lastTrialStartedAt!).inMilliseconds)
        : 600;
    responseTimesMs.add(reactionTimeMs);

    final bool isCorrect;
    int pointsEarned = 0;

    if (action is SelectFocusSlotAction) {
      final slot = action.slotIndex;
      if (slot < 0 || slot >= trialState.displayedItems.length) {
        throw GameValidationException('Slot index $slot out of range');
      }

      if (trialState.isTargetPresent) {
        if (slot == trialState.targetSlotIndex) {
          // Hit!
          isCorrect = true;
          hits++;
          pointsEarned = scoringRules.pointsPerHit;
        } else {
          // Selected wrong distractor
          isCorrect = false;
          falseAlarms++;
          pointsEarned = -scoringRules.penaltyPerFalseAlarm;
        }
      } else {
        // Target was absent, but player selected a slot
        isCorrect = false;
        falseAlarms++;
        pointsEarned = -scoringRules.penaltyPerFalseAlarm;
      }
    } else if (action is SelectNoTargetAction) {
      if (!trialState.isTargetPresent) {
        // Correct Rejection!
        isCorrect = true;
        correctRejections++;
        pointsEarned = scoringRules.pointsPerCorrectRejection;
      } else {
        // Target was present, but player claimed it was absent
        isCorrect = false;
        misses++;
        pointsEarned = -scoringRules.penaltyPerMiss;
      }
    } else {
      throw InvalidActionException(
        'Unexpected action in Focus Reactor: ${action.type}',
      );
    }

    final speedBonus = isCorrect &&
            reactionTimeMs < reactorConfig.speedBonusThreshold.inMilliseconds
        ? ((reactorConfig.speedBonusThreshold.inMilliseconds - reactionTimeMs) *
                0.08)
            .round()
        : 0;

    final newScore =
        math.max(0, currentState.score + pointsEarned + speedBonus);
    final nextRound = currentState.currentRound + 1;
    final isCompleted = nextRound > currentState.totalRounds;

    if (isCompleted) {
      trialState = FocusReactorTrialState(
        targetItem: trialState.targetItem,
        displayedItems: trialState.displayedItems,
        targetSlotIndex: trialState.targetSlotIndex,
        lastSelectionCorrect: isCorrect,
        lastReactionTimeMs: reactionTimeMs,
      );
      return currentState.copyWith(
        phase: GamePhase.completed,
        score: newScore,
        streak: isCorrect ? currentState.streak + 1 : 0,
        customData: {
          'trialState': trialState.toJson(),
          'completed': true,
        },
      );
    } else {
      _generateTrial(nextRound, baseTimestamp: action.timestamp);
      return state.copyWith(
        score: newScore,
        streak: isCorrect ? currentState.streak + 1 : 0,
      );
    }
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    final totalDecisions = hits + correctRejections + falseAlarms + misses;
    final totalSuccessful = hits + correctRejections;
    final accuracy = totalDecisions > 0
        ? (totalSuccessful / totalDecisions).clamp(0.0, 1.0)
        : 0.0;
    final avgReactionTime = responseTimesMs.isNotEmpty
        ? (responseTimesMs.reduce((a, b) => a + b) / responseTimesMs.length)
            .round()
        : 800;

    final breakdown = scoringRules.calculateScore(
      rawPoints: state.score,
      activeDuration: totalActiveDuration,
      accuracy: accuracy,
      difficulty: reactorConfig.difficulty,
      streak: state.streak,
      penaltyCount: falseAlarms + misses,
    );

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: reactorConfig.seed,
      difficulty: reactorConfig.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'hitCount': hits,
        'correctRejectionCount': correctRejections,
        'falseAlarmCount': falseAlarms,
        'missCount': misses,
        'averageReactionTimeMs': avgReactionTime,
        'accuracyPercent': (accuracy * 100).round(),
        'isPractice': reactorConfig.isPractice,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
