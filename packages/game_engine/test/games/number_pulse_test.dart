import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Number Pulse Engine Unit Tests', () {
    late NumberPulseDefinition definition;

    setUp(() {
      definition = NumberPulseDefinition();
    });

    test('generates deterministic sequence and options for a given seed', () {
      final configA = definition.createDefaultConfig(
        seed: 31415,
        difficulty: GameDifficulty.medium,
      );
      final configB = definition.createDefaultConfig(
        seed: 31415,
        difficulty: GameDifficulty.medium,
      );

      final engineA =
          definition.createEngine(config: configA) as NumberPulseGameEngine;
      final engineB =
          definition.createEngine(config: configB) as NumberPulseGameEngine;

      engineA.dispatch(const StartGameAction(timestamp: Duration.zero));
      engineB.dispatch(const StartGameAction(timestamp: Duration.zero));

      expect(
        engineA.trialState.question.sequence,
        equals(engineB.trialState.question.sequence),
      );
      expect(
        engineA.trialState.question.missingIndex,
        equals(engineB.trialState.question.missingIndex),
      );
      expect(
        engineA.trialState.question.correctAnswer,
        equals(engineB.trialState.question.correctAnswer),
      );
      expect(
        engineA.trialState.question.options,
        equals(engineB.trialState.question.options),
      );
    });

    test(
        'options contain exactly 4 unique choices with correct answer included',
        () {
      final config = definition.createDefaultConfig(
        seed: 999,
        difficulty: GameDifficulty.hard,
      );
      final engine =
          definition.createEngine(config: config) as NumberPulseGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      final q = engine.trialState.question;
      expect(q.options.length, equals(4));
      expect(q.options.toSet().length, equals(4)); // all 4 distinct
      expect(q.options.contains(q.correctAnswer), isTrue);
    });

    test('correct guess increments score and streak, advancing rounds', () {
      final config = definition.createDefaultConfig(
        seed: 123,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as NumberPulseGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      final round1Answer = engine.trialState.question.correctAnswer;
      engine.dispatch(
        SelectNumberPulseAnswerAction(
          timestamp: const Duration(seconds: 2),
          selectedAnswer: round1Answer,
        ),
      );

      expect(engine.correctAnswers, equals(1));
      expect(engine.currentStreak, equals(1));
      expect(engine.state.currentRound, equals(2));
    });

    test('incorrect guess resets streak and counts mistake', () {
      final config = definition.createDefaultConfig(
        seed: 555,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as NumberPulseGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      final wrongAnswer = engine.trialState.question.options.firstWhere(
        (opt) => opt != engine.trialState.question.correctAnswer,
      );

      engine.dispatch(
        SelectNumberPulseAnswerAction(
          timestamp: const Duration(seconds: 2),
          selectedAnswer: wrongAnswer,
        ),
      );

      expect(engine.correctAnswers, equals(0));
      expect(engine.incorrectAnswers, equals(1));
      expect(engine.currentStreak, equals(0));
    });

    test('completing all rounds generates complete GameResult', () {
      const config = NumberPulseConfig(
        seed: 42,
        difficulty: GameDifficulty.easy,
        totalRounds: 2,
        sequenceLength: 4,
      );

      final engine =
          definition.createEngine(config: config) as NumberPulseGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      // Round 1
      engine.dispatch(
        SelectNumberPulseAnswerAction(
          timestamp: const Duration(seconds: 1),
          selectedAnswer: engine.trialState.question.correctAnswer,
        ),
      );

      // Round 2
      engine.dispatch(
        SelectNumberPulseAnswerAction(
          timestamp: const Duration(seconds: 2),
          selectedAnswer: engine.trialState.question.correctAnswer,
        ),
      );

      expect(engine.state.phase, equals(GamePhase.completed));
      expect(engine.correctAnswers, equals(2));

      final result = engine.computeResult(
        sessionId: 'pulse-test',
        totalActiveDuration: const Duration(seconds: 3),
        totalActions: 2,
      );

      expect(result.gameId, equals('number-pulse'));
      expect(result.finalScore, isPositive);
      expect(result.metrics['correctAnswers'], equals(2));
      expect(result.metrics['accuracy'], equals(1.0));
      expect(result.metrics['maxStreak'], equals(2));
    });
  });
}
