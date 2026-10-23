import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Reflex Forge Engine Unit Tests', () {
    late ReflexForgeDefinition definition;

    setUp(() {
      definition = ReflexForgeDefinition();
    });

    test('shifts rules dynamically after designated frequency', () {
      final config = definition.createDefaultConfig(seed: 101);
      final session = GameSession(
        id: 'sess-rule-shift',
        definition: definition,
        config: config,
      );

      session.start();
      final engine = session.engine as ReflexForgeGameEngine;

      // Initial rule is matchShape
      expect(engine.activeRule, equals(ReflexRule.matchShape));

      // Play through trials 1, 2, 3
      for (var round = 1; round <= 3; round++) {
        session.dispatch(
          SelectReflexOptionAction(
            timestamp: Duration(milliseconds: round * 1000),
            selectedIndex: engine.trialState.correctIndex,
          ),
        );
      }

      // After round 3 (frequency = 3), round 4 shifts to matchPattern
      expect(engine.activeRule, equals(ReflexRule.matchPattern));
      expect(engine.trialState.ruleShiftedThisRound, isTrue);

      session.dispose();
    });

    test('reproduces identical score and metrics for seeded replays', () {
      final clockA = TestMonotonicClock();
      final clockB = TestMonotonicClock();

      final configA = definition.createDefaultConfig(seed: 4321);
      final configB = definition.createDefaultConfig(seed: 4321);

      final sessionA = GameSession(
        id: 'sess-a',
        definition: definition,
        config: configA,
        clock: PausableMonotonicClock(baseClock: clockA),
      );
      final sessionB = GameSession(
        id: 'sess-b',
        definition: definition,
        config: configB,
        clock: PausableMonotonicClock(baseClock: clockB),
      );

      sessionA.start();
      sessionB.start();

      for (var round = 1; round <= configA.totalRounds; round++) {
        final engineA = sessionA.engine as ReflexForgeGameEngine;
        final engineB = sessionB.engine as ReflexForgeGameEngine;

        expect(
          engineA.trialState.correctIndex,
          equals(engineB.trialState.correctIndex),
        );

        clockA.advance(const Duration(milliseconds: 650));
        clockB.advance(const Duration(milliseconds: 650));

        sessionA.dispatch(
          SelectReflexOptionAction(
            timestamp: clockA.elapsed,
            selectedIndex: engineA.trialState.correctIndex,
          ),
        );
        sessionB.dispatch(
          SelectReflexOptionAction(
            timestamp: clockB.elapsed,
            selectedIndex: engineB.trialState.correctIndex,
          ),
        );
      }

      expect(sessionA.state.phase, equals(GamePhase.completed));
      expect(sessionB.state.phase, equals(GamePhase.completed));

      final resultA = sessionA.finish(isOffline: true);
      final resultB = sessionB.finish(isOffline: true);

      expect(resultA.finalScore, equals(resultB.finalScore));
      expect(resultA.scoreBreakdown, equals(resultB.scoreBreakdown));
      expect(resultA.metrics['correctCount'], equals(configA.totalRounds));
      expect(resultA.metrics['incorrectCount'], equals(0));
      expect(resultA.metrics['accuracyPercent'], equals(100));

      sessionA.dispose();
      sessionB.dispose();
    });

    test('rejects out of bounds option indices safely', () {
      final config = definition.createDefaultConfig(seed: 7);
      final session = GameSession(
        id: 'sess-invalid',
        definition: definition,
        config: config,
      );

      session.start();

      expect(
        () => session.dispatch(
          SelectReflexOptionAction(
            timestamp: const Duration(seconds: 1),
            selectedIndex: 99,
          ),
        ),
        throwsA(isA<GameValidationException>()),
      );

      session.dispose();
    });
  });
}
