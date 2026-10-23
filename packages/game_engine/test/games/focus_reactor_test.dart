import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Focus Reactor Engine Unit Tests', () {
    late FocusReactorDefinition definition;

    setUp(() {
      definition = FocusReactorDefinition();
    });

    test('distinguishes hits from correct rejections and false alarms', () {
      final config = definition.createDefaultConfig(seed: 999);
      final session = GameSession(
        id: 'sess-focus-trials',
        definition: definition,
        config: config,
      );

      session.start();
      final engine = session.engine as FocusReactorGameEngine;

      if (engine.trialState.isTargetPresent) {
        // Correct Hit
        session.dispatch(
          SelectFocusSlotAction(
            timestamp: const Duration(seconds: 1),
            slotIndex: engine.trialState.targetSlotIndex!,
          ),
        );
        expect(engine.hits, equals(1));
        expect(engine.falseAlarms, equals(0));
      } else {
        // Correct Rejection
        session.dispatch(
          SelectNoTargetAction(timestamp: const Duration(seconds: 1)),
        );
        expect(engine.correctRejections, equals(1));
        expect(engine.misses, equals(0));
      }

      session.dispose();
    });

    test('reproduces deterministic game run for same seed', () {
      final clockA = TestMonotonicClock();
      final clockB = TestMonotonicClock();

      final configA = definition.createDefaultConfig(seed: 7777);
      final configB = definition.createDefaultConfig(seed: 7777);

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

      for (var r = 1; r <= configA.totalRounds; r++) {
        final engineA = sessionA.engine as FocusReactorGameEngine;
        final engineB = sessionB.engine as FocusReactorGameEngine;

        expect(
          engineA.trialState.targetSlotIndex,
          equals(engineB.trialState.targetSlotIndex),
        );

        clockA.advance(const Duration(milliseconds: 700));
        clockB.advance(const Duration(milliseconds: 700));

        final actionA = engineA.trialState.isTargetPresent
            ? SelectFocusSlotAction(
                timestamp: clockA.elapsed,
                slotIndex: engineA.trialState.targetSlotIndex!,
              )
            : SelectNoTargetAction(timestamp: clockA.elapsed);

        final actionB = engineB.trialState.isTargetPresent
            ? SelectFocusSlotAction(
                timestamp: clockB.elapsed,
                slotIndex: engineB.trialState.targetSlotIndex!,
              )
            : SelectNoTargetAction(timestamp: clockB.elapsed);

        sessionA.dispatch(actionA);
        sessionB.dispatch(actionB);
      }

      expect(sessionA.state.phase, equals(GamePhase.completed));
      expect(sessionB.state.phase, equals(GamePhase.completed));

      final resultA = sessionA.finish(isOffline: true);
      final resultB = sessionB.finish(isOffline: true);

      expect(resultA.finalScore, equals(resultB.finalScore));
      expect(resultA.scoreBreakdown, equals(resultB.scoreBreakdown));
      expect(resultA.metrics['hitCount'], equals(resultB.metrics['hitCount']));
      expect(
        resultA.metrics['correctRejectionCount'],
        equals(resultB.metrics['correctRejectionCount']),
      );

      sessionA.dispose();
      sessionB.dispose();
    });

    test('rejects invalid slot selection out of bounds', () {
      final config = definition.createDefaultConfig(seed: 12);
      final session = GameSession(
        id: 'sess-bounds',
        definition: definition,
        config: config,
      );

      session.start();

      expect(
        () => session.dispatch(
          SelectFocusSlotAction(
            timestamp: const Duration(seconds: 1),
            slotIndex: 50,
          ),
        ),
        throwsA(isA<GameValidationException>()),
      );

      session.dispose();
    });
  });
}
