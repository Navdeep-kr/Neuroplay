import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Word Weaver Engine Unit Tests', () {
    late WordWeaverDefinition definition;

    setUp(() {
      definition = WordWeaverDefinition();
    });

    test('generates deterministic question and options for a given seed', () {
      final configA = definition.createDefaultConfig(
        seed: 71828,
        difficulty: GameDifficulty.medium,
      );
      final configB = definition.createDefaultConfig(
        seed: 71828,
        difficulty: GameDifficulty.medium,
      );

      final engineA =
          definition.createEngine(config: configA) as WordWeaverGameEngine;
      final engineB =
          definition.createEngine(config: configB) as WordWeaverGameEngine;

      engineA.dispatch(const StartGameAction(timestamp: Duration.zero));
      engineB.dispatch(const StartGameAction(timestamp: Duration.zero));

      final qA = engineA.trialState.question;
      final qB = engineB.trialState.question;

      expect(qA.anchorWord, equals(qB.anchorWord));
      expect(qA.category, equals(qB.category));
      expect(qA.correctAssociatedWord, equals(qB.correctAssociatedWord));
      expect(qA.options, equals(qB.options));
    });

    test('options contain 4 unique choices with correct word and 3 distractors',
        () {
      final config = definition.createDefaultConfig(
        seed: 444,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as WordWeaverGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      final q = engine.trialState.question;
      expect(q.options.length, equals(4));
      expect(q.options.toSet().length, equals(4));
      expect(q.options.contains(q.correctAssociatedWord), isTrue);
      expect(q.options.contains(q.anchorWord), isFalse);
    });

    test('correct association awards points and advances rounds', () {
      final config = definition.createDefaultConfig(
        seed: 888,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as WordWeaverGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      final answer = engine.trialState.question.correctAssociatedWord;
      engine.dispatch(
        SelectWordAssociationAction(
          timestamp: const Duration(seconds: 1),
          selectedWord: answer,
        ),
      );

      expect(engine.correctAnswers, equals(1));
      expect(engine.currentStreak, equals(1));
      expect(engine.state.currentRound, equals(2));
    });

    test('incorrect association resets streak and records error', () {
      final config = definition.createDefaultConfig(
        seed: 888,
        difficulty: GameDifficulty.easy,
      );
      final engine =
          definition.createEngine(config: config) as WordWeaverGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      final wrongWord = engine.trialState.question.options.firstWhere(
        (opt) => opt != engine.trialState.question.correctAssociatedWord,
      );

      engine.dispatch(
        SelectWordAssociationAction(
          timestamp: const Duration(seconds: 1),
          selectedWord: wrongWord,
        ),
      );

      expect(engine.correctAnswers, equals(0));
      expect(engine.incorrectAnswers, equals(1));
      expect(engine.currentStreak, equals(0));
    });

    test('completing all rounds generates complete GameResult', () {
      const config = WordWeaverConfig(
        seed: 9999,
        difficulty: GameDifficulty.easy,
        totalRounds: 2,
      );

      final engine =
          definition.createEngine(config: config) as WordWeaverGameEngine;
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      // Round 1
      engine.dispatch(
        SelectWordAssociationAction(
          timestamp: const Duration(seconds: 1),
          selectedWord: engine.trialState.question.correctAssociatedWord,
        ),
      );

      // Round 2
      engine.dispatch(
        SelectWordAssociationAction(
          timestamp: const Duration(seconds: 2),
          selectedWord: engine.trialState.question.correctAssociatedWord,
        ),
      );

      expect(engine.state.phase, equals(GamePhase.completed));
      expect(engine.correctAnswers, equals(2));

      final result = engine.computeResult(
        sessionId: 'weaver-test',
        totalActiveDuration: const Duration(seconds: 3),
        totalActions: 2,
      );

      expect(result.gameId, equals('word-weaver'));
      expect(result.finalScore, isPositive);
      expect(result.metrics['correctAnswers'], equals(2));
      expect(result.metrics['accuracy'], equals(1.0));
      expect(result.metrics['maxStreak'], equals(2));
    });
  });
}
