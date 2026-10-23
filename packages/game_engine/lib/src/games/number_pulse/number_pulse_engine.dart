import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_actions.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_config.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_models.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_scoring.dart';
import 'package:game_engine/src/games/number_pulse/number_pulse_state.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Pure Dart deterministic state machine for Number Pulse.
final class NumberPulseGameEngine extends GameEngineBase {
  NumberPulseGameEngine({
    required NumberPulseConfig super.config,
    this.scoringRules = const NumberPulseScoringRules(),
  }) : pulseConfig = config;

  final NumberPulseConfig pulseConfig;
  final NumberPulseScoringRules scoringRules;

  late NumberPulseTrialState trialState;
  Duration? lastQuestionStartedAt;

  int correctAnswers = 0;
  int incorrectAnswers = 0;
  int currentStreak = 0;
  int maxStreak = 0;
  final List<int> responseTimesMs = [];

  @override
  String get gameId => 'number-pulse';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    _startRound(1, baseTimestamp: Duration.zero);
  }

  void _startRound(int roundNumber, {required Duration baseTimestamp}) {
    lastQuestionStartedAt = baseTimestamp;
    final question = _generateQuestion(roundNumber);

    trialState = NumberPulseTrialState(
      roundIndex: roundNumber,
      question: question,
    );

    state = state.copyWith(
      currentRound: roundNumber,
      customData: {
        'trialState': trialState.toJson(),
      },
    );
  }

  NumberPulseQuestion _generateQuestion(int roundNumber) {
    final length = pulseConfig.sequenceLength;
    final patternName = random.choice(pulseConfig.allowedPatterns);

    final List<int> seq = [];
    String explanation;
    SequencePatternType patternType;

    switch (patternName) {
      case 'geometric':
        patternType = SequencePatternType.geometric;
        final start = random.nextIntInRange(1, 4);
        final ratio = random.nextIntInRange(2, 3);
        var curr = start;
        for (var i = 0; i < length; i++) {
          seq.add(curr);
          curr *= ratio;
        }
        explanation = 'Multiply by $ratio each step';
        break;

      case 'alternating':
        patternType = SequencePatternType.alternating;
        final start = random.nextIntInRange(5, 30);
        final addStep = random.nextIntInRange(3, 8);
        final subStep = random.nextIntInRange(1, 4);
        var curr = start;
        for (var i = 0; i < length; i++) {
          seq.add(curr);
          curr = (i % 2 == 0) ? (curr + addStep) : (curr - subStep);
        }
        explanation = 'Alternating pattern: +$addStep, -$subStep';
        break;

      case 'fibonacci':
        patternType = SequencePatternType.fibonacci;
        final a0 = random.nextIntInRange(1, 4);
        final a1 = random.nextIntInRange(2, 5);
        seq.add(a0);
        seq.add(a1);
        for (var i = 2; i < length; i++) {
          seq.add(seq[i - 1] + seq[i - 2]);
        }
        explanation = 'Each term is the sum of the two preceding terms';
        break;

      case 'arithmetic':
      default:
        patternType = SequencePatternType.arithmetic;
        final start = random.nextIntInRange(2, 25);
        final step = random.nextIntInRange(2, 9);
        for (var i = 0; i < length; i++) {
          seq.add(start + (i * step));
        }
        explanation = 'Add $step each step';
        break;
    }

    // Pick missing index between 1 and length - 1 so the user has initial context
    final missingIndex = random.nextIntInRange(1, length - 1);
    final correct = seq[missingIndex];

    // Generate 3 unique distractors
    final distractors = <int>{};
    final candidates = [
      correct + 1,
      correct - 1,
      correct + 2,
      correct - 2,
      correct + 3,
      correct - 3,
      correct + 5,
      correct - 5,
      (correct * 1.5).round(),
      (correct * 0.8).round(),
    ];

    for (final cand in random.shuffle(candidates)) {
      if (cand != correct && !distractors.contains(cand)) {
        distractors.add(cand);
        if (distractors.length == 3) break;
      }
    }

    // Fallback if needed
    var fallbackDelta = 4;
    while (distractors.length < 3) {
      final cand = correct + fallbackDelta;
      if (cand != correct && !distractors.contains(cand)) {
        distractors.add(cand);
      }
      fallbackDelta++;
    }

    final options = random.shuffle([correct, ...distractors]);

    return NumberPulseQuestion(
      sequence: seq,
      missingIndex: missingIndex,
      correctAnswer: correct,
      options: options,
      patternType: patternType,
      explanation: explanation,
    );
  }

  @override
  GameState processAction(GameState currentState, GameAction action) {
    if (action is SelectNumberPulseAnswerAction) {
      if (trialState.isAnswered) {
        throw const InvalidActionException('Current question already answered');
      }

      final guess = action.selectedAnswer;
      final isCorrect = guess == trialState.question.correctAnswer;

      final elapsedMs = lastQuestionStartedAt != null
          ? (action.timestamp - lastQuestionStartedAt!)
              .inMilliseconds
              .clamp(50, 60000)
          : 500;
      responseTimesMs.add(elapsedMs);

      if (isCorrect) {
        correctAnswers++;
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        incorrectAnswers++;
        currentStreak = 0;
      }

      final updatedTrial = trialState.copyWith(
        selectedAnswer: guess,
        isCorrect: isCorrect,
        isAnswered: true,
        responseTimeMs: elapsedMs,
      );
      trialState = updatedTrial;

      final isLastRound = currentState.currentRound >= currentState.totalRounds;

      if (isLastRound) {
        final breakdown = scoringRules.calculateBreakdown(
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          maxStreak: maxStreak,
          responseTimesMs: responseTimesMs,
          totalDuration: action.timestamp,
          difficulty: pulseConfig.difficulty,
        );

        return currentState.copyWith(
          phase: GamePhase.completed,
          score: breakdown.finalScore,
          streak: currentStreak,
          customData: {
            'trialState': updatedTrial.toJson(),
            'completed': true,
          },
        );
      } else {
        final intermediateBreakdown = scoringRules.calculateBreakdown(
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          maxStreak: maxStreak,
          responseTimesMs: responseTimesMs,
          totalDuration: action.timestamp,
          difficulty: pulseConfig.difficulty,
        );

        final nextRound = currentState.currentRound + 1;
        _startRound(nextRound, baseTimestamp: action.timestamp);

        return state.copyWith(
          score: intermediateBreakdown.finalScore,
          streak: currentStreak,
        );
      }
    }

    throw InvalidActionException('Unknown action type ${action.type}');
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    final total = correctAnswers + incorrectAnswers;
    final accuracy = total > 0 ? (correctAnswers / total).clamp(0.0, 1.0) : 0.0;

    final breakdown = scoringRules.calculateBreakdown(
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      maxStreak: maxStreak,
      responseTimesMs: responseTimesMs,
      totalDuration: totalActiveDuration,
      difficulty: pulseConfig.difficulty,
    );

    final avgResponseTimeMs = responseTimesMs.isNotEmpty
        ? (responseTimesMs.reduce((a, b) => a + b) / responseTimesMs.length)
            .round()
        : 0;

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: pulseConfig.seed,
      difficulty: pulseConfig.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'correctAnswers': correctAnswers,
        'incorrectAnswers': incorrectAnswers,
        'accuracy': accuracy,
        'maxStreak': maxStreak,
        'averageResponseTimeMs': avgResponseTimeMs,
        'isPractice': pulseConfig.isPractice,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
