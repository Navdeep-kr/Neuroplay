import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';

/// Test fixture definition inside app test.
final class DummyCognitiveGameDefinition extends GameDefinition {
  DummyCognitiveGameDefinition()
      : super(
          id: 'dummy-attention',
          name: 'Dummy Attention Game',
          description:
              'A mock attention cognitive game for app-layer contract verification.',
          category: 'attention',
          version: GameEngineVersion.current,
          scoringRules: const StandardScoringRules(),
        );

  @override
  GameConfig createDefaultConfig({
    GameDifficulty difficulty = GameDifficulty.medium,
    int? seed,
  }) =>
      GameConfig(
        seed: seed ?? 1234,
        difficulty: difficulty,
        totalRounds: 2,
      );

  @override
  GameEngineBase createEngine({required GameConfig config}) =>
      _DummyEngine(config: config);
}

final class _DummyEngine extends GameEngineBase {
  _DummyEngine({required super.config});

  @override
  String get gameId => 'dummy-attention';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => '1.0.0';

  @override
  GameState processAction(GameState currentState, GameAction action) {
    if (action is RespondAction) {
      final isCorrect = action.responseValue == true;
      final nextRound = currentState.currentRound + 1;
      final isCompleted = nextRound > currentState.totalRounds;

      return currentState.copyWith(
        phase: isCompleted ? GamePhase.completed : GamePhase.playing,
        currentRound: isCompleted ? currentState.totalRounds : nextRound,
        score: isCorrect ? currentState.score + 100 : currentState.score,
        streak: isCorrect ? currentState.streak + 1 : 0,
      );
    }
    return currentState;
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    const rules = StandardScoringRules();
    final breakdown = rules.calculateScore(
      rawPoints: state.score,
      activeDuration: totalActiveDuration,
      accuracy: 1,
      difficulty: config.difficulty,
      streak: state.streak,
    );

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: config.seed,
      difficulty: config.difficulty,
      completionPhase: state.phase,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {'correctRounds': state.score ~/ 100},
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}

void main() {
  group('App-level Game Contracts Integration Tests', () {
    test('game runs headlessly without Flutter widgets or UI frame pumps', () {
      final definition = DummyCognitiveGameDefinition();
      final config = definition.createDefaultConfig(seed: 99);
      final clock = TestMonotonicClock();
      final session = GameSession(
        id: 'app-integration-session',
        definition: definition,
        config: config,
        clock: PausableMonotonicClock(baseClock: clock),
      );

      expect(session.state.phase, equals(GamePhase.ready));

      session.start();
      expect(session.state.phase, equals(GamePhase.playing));
      expect(session.state.currentRound, equals(1));

      // Round 1 answer
      clock.advance(const Duration(milliseconds: 300));
      session.dispatch(
        RespondAction(
          timestamp: clock.elapsed,
          responseValue: true,
          targetId: 'target-1',
        ),
      );
      expect(session.state.currentRound, equals(2));
      expect(session.state.score, equals(100));

      // Round 2 answer (final)
      clock.advance(const Duration(milliseconds: 350));
      session.dispatch(
        RespondAction(
          timestamp: clock.elapsed,
          responseValue: true,
          targetId: 'target-2',
        ),
      );
      expect(session.state.phase, equals(GamePhase.completed));

      final result = session.finish(isOffline: true);
      expect(result.finalScore, greaterThan(200));
      expect(result.metrics['correctRounds'], equals(2));
      expect(result.isOffline, isTrue);

      session.dispose();
    });
  });
}
