import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_actions.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_config.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_models.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_scoring.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_state.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Headless deterministic state machine for Reflex Forge.
final class ReflexForgeGameEngine extends GameEngineBase {
  ReflexForgeGameEngine({
    required ReflexForgeConfig super.config,
    this.scoringRules = const ReflexForgeScoringRules(),
  }) : forgeConfig = config;

  final ReflexForgeConfig forgeConfig;
  final ReflexForgeScoringRules scoringRules;

  late ReflexRule activeRule;
  late ReflexForgeTrialState trialState;
  Duration? lastTrialStartedAt;

  int correctResponses = 0;
  int incorrectResponses = 0;
  int ruleShiftErrors = 0;
  final List<int> responseTimesMs = [];

  @override
  String get gameId => 'reflex-forge';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    activeRule = ReflexRule.matchShape;
    _generateTrial(1, activeRule, isShift: false, baseTimestamp: Duration.zero);
  }

  void _generateTrial(
    int roundNumber,
    ReflexRule rule, {
    required bool isShift,
    required Duration baseTimestamp,
  }) {
    // Generate deterministic target stimulus
    final shapes = List<ReflexShape>.from(ReflexShape.values);
    final patterns = List<ReflexPattern>.from(ReflexPattern.values);

    final targetShape = random.choice(shapes);
    final targetPattern = random.choice(patterns);
    final targetStimulus =
        ReflexSymbol(shape: targetShape, pattern: targetPattern);

    // Generate options:
    // 1. Correct Match according to active rule
    // 2. Foil matching the OTHER (inactive) attribute
    // 3. Complete distractor
    final otherShapes = shapes.where((s) => s != targetShape).toList();
    final otherPatterns = patterns.where((p) => p != targetPattern).toList();

    final ReflexSymbol correctOption;
    final ReflexSymbol foilOption;
    final ReflexSymbol distractorOption;

    if (rule == ReflexRule.matchShape) {
      // Must match shape, pattern is different
      correctOption = ReflexSymbol(
        shape: targetShape,
        pattern: random.choice(otherPatterns),
      );
      // Foil matches pattern, shape is different
      foilOption = ReflexSymbol(
        shape: random.choice(otherShapes),
        pattern: targetPattern,
      );
    } else {
      // Must match pattern, shape is different
      correctOption = ReflexSymbol(
        shape: random.choice(otherShapes),
        pattern: targetPattern,
      );
      // Foil matches shape, pattern is different
      foilOption = ReflexSymbol(
        shape: targetShape,
        pattern: random.choice(otherPatterns),
      );
    }

    distractorOption = ReflexSymbol(
      shape: random.choice(otherShapes),
      pattern: random.choice(otherPatterns),
    );

    final rawOptions = [correctOption, foilOption, distractorOption];
    final shuffledOptions = random.shuffle(rawOptions);
    final correctIndex = shuffledOptions.indexOf(correctOption);

    trialState = ReflexForgeTrialState(
      rule: rule,
      stimulus: targetStimulus,
      options: shuffledOptions,
      correctIndex: correctIndex,
      ruleShiftedThisRound: isShift,
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
    if (action is! SelectReflexOptionAction) {
      throw InvalidActionException(
        'Unexpected action in Reflex Forge: ${action.type}',
      );
    }

    final selected = action.selectedIndex;
    if (selected < 0 || selected >= trialState.options.length) {
      throw GameValidationException('Option index $selected out of range');
    }

    final isCorrect = selected == trialState.correctIndex;
    final reactionTimeMs = lastTrialStartedAt != null
        ? math.max(50, (action.timestamp - lastTrialStartedAt!).inMilliseconds)
        : 500;
    responseTimesMs.add(reactionTimeMs);

    if (isCorrect) {
      correctResponses++;
    } else {
      incorrectResponses++;
      if (trialState.ruleShiftedThisRound) {
        ruleShiftErrors++;
      }
    }

    final nextRound = currentState.currentRound + 1;
    final isCompleted = nextRound > currentState.totalRounds;

    // Check if next round will shift rules
    final shouldShiftRule =
        !isCompleted && (nextRound - 1) % forgeConfig.ruleShiftFrequency == 0;
    if (shouldShiftRule) {
      activeRule = activeRule.opposite;
    }

    final speedBonus =
        isCorrect && reactionTimeMs < forgeConfig.speedTarget.inMilliseconds
            ? ((forgeConfig.speedTarget.inMilliseconds - reactionTimeMs) * 0.1)
                .round()
            : 0;

    final roundScore = isCorrect
        ? scoringRules.pointsPerCorrectMatch + speedBonus
        : -scoringRules.penaltyPerError;
    final newScore = math.max(0, currentState.score + roundScore);

    if (isCompleted) {
      trialState = ReflexForgeTrialState(
        rule: trialState.rule,
        stimulus: trialState.stimulus,
        options: trialState.options,
        correctIndex: trialState.correctIndex,
        lastSelectedCorrect: isCorrect,
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
      _generateTrial(
        nextRound,
        activeRule,
        isShift: shouldShiftRule,
        baseTimestamp: action.timestamp,
      );
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
    final totalTrials = correctResponses + incorrectResponses;
    final accuracy = totalTrials > 0
        ? (correctResponses / totalTrials).clamp(0.0, 1.0)
        : 0.0;
    final avgReactionTime = responseTimesMs.isNotEmpty
        ? (responseTimesMs.reduce((a, b) => a + b) / responseTimesMs.length)
            .round()
        : 1000;

    final breakdown = scoringRules.calculateScore(
      rawPoints: state.score,
      activeDuration: totalActiveDuration,
      accuracy: accuracy,
      difficulty: forgeConfig.difficulty,
      streak: state.streak,
      penaltyCount: incorrectResponses,
    );

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: forgeConfig.seed,
      difficulty: forgeConfig.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'correctCount': correctResponses,
        'incorrectCount': incorrectResponses,
        'ruleShiftErrorCount': ruleShiftErrors,
        'averageReactionTimeMs': avgReactionTime,
        'accuracyPercent': (accuracy * 100).round(),
        'isPractice': forgeConfig.isPractice,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
