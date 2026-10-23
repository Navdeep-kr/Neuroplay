import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Memory Matrix Engine Unit Tests', () {
    late MemoryMatrixDefinition definition;

    setUp(() {
      definition = MemoryMatrixDefinition();
    });

    test('generates deterministic target tiles for a given seed', () {
      final configA = definition.createDefaultConfig(seed: 12345);
      final configB = definition.createDefaultConfig(seed: 12345);

      final engineA =
          definition.createEngine(config: configA) as MemoryMatrixGameEngine;
      final engineB =
          definition.createEngine(config: configB) as MemoryMatrixGameEngine;

      engineA.dispatch(const StartGameAction(timestamp: Duration.zero));
      engineB.dispatch(const StartGameAction(timestamp: Duration.zero));

      expect(
        engineA.roundState.targetIndices,
        equals(engineB.roundState.targetIndices),
      );
      expect(engineA.roundState.targetIndices.length, equals(4));
    });

    test('rejects tile selections during memorize phase', () {
      final config = definition.createDefaultConfig(seed: 99);
      final engine = definition.createEngine(config: config);
      engine.dispatch(const StartGameAction(timestamp: Duration.zero));

      expect(
        () => engine.dispatch(
          SelectTileAction(
            timestamp: const Duration(milliseconds: 200),
            tileIndex: 0,
          ),
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('reproduces full game session deterministically', () {
      final clockA = TestMonotonicClock();
      final clockB = TestMonotonicClock();

      final configA = definition.createDefaultConfig(seed: 8888);
      final configB = definition.createDefaultConfig(seed: 8888);

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

      // For all 5 rounds, transition to recall and tap all targets
      for (var r = 1; r <= 5; r++) {
        final engineA = sessionA.engine as MemoryMatrixGameEngine;
        final engineB = sessionB.engine as MemoryMatrixGameEngine;

        expect(
          engineA.roundState.targetIndices,
          equals(engineB.roundState.targetIndices),
        );

        // Advance past memorize phase
        clockA.advance(const Duration(milliseconds: 1500));
        clockB.advance(const Duration(milliseconds: 1500));

        sessionA.dispatch(BeginRecallAction(timestamp: clockA.elapsed));
        sessionB.dispatch(BeginRecallAction(timestamp: clockB.elapsed));

        // Tap all targets in order
        for (final target in engineA.roundState.targetIndices) {
          clockA.advance(const Duration(milliseconds: 200));
          clockB.advance(const Duration(milliseconds: 200));

          sessionA.dispatch(
            SelectTileAction(timestamp: clockA.elapsed, tileIndex: target),
          );
          sessionB.dispatch(
            SelectTileAction(timestamp: clockB.elapsed, tileIndex: target),
          );
        }
      }

      expect(sessionA.state.phase, equals(GamePhase.completed));
      expect(sessionB.state.phase, equals(GamePhase.completed));

      final resultA = sessionA.finish(isOffline: true);
      final resultB = sessionB.finish(isOffline: true);

      expect(resultA.finalScore, equals(resultB.finalScore));
      expect(resultA.scoreBreakdown, equals(resultB.scoreBreakdown));
      expect(
        resultA.metrics['correctTilesFound'],
        equals(resultB.metrics['correctTilesFound']),
      );
      expect(resultA.metrics['mistakeCount'], equals(0));
      expect(resultA.metrics['accuracyPercent'], equals(100));

      sessionA.dispose();
      sessionB.dispose();
    });

    test('penalizes incorrect tile taps and limits mistakes', () {
      final config = definition.createDefaultConfig(seed: 555);
      final session = GameSession(
        id: 'sess-mistakes',
        definition: definition,
        config: config,
      );

      session.start();
      session
          .dispatch(BeginRecallAction(timestamp: const Duration(seconds: 2)));

      final engine = session.engine as MemoryMatrixGameEngine;
      final targetSet = engine.roundState.targetIndices.toSet();
      final nonTarget =
          List.generate(16, (i) => i).firstWhere((i) => !targetSet.contains(i));

      // Tap non-target
      session.dispatch(
        SelectTileAction(
          timestamp: const Duration(seconds: 3),
          tileIndex: nonTarget,
        ),
      );

      expect(
        engine.roundState.selectedMistakeIndices.contains(nonTarget),
        isTrue,
      );
      expect(engine.totalMistakes, equals(1));

      session.dispose();
    });

    test('practice mode generates smaller grid and fewer rounds', () {
      final config = definition.createDefaultConfig(isPractice: true);
      expect(config.gridSize, equals(3));
      expect(config.targetCount, equals(3));
      expect(config.totalRounds, equals(2));
      expect(config.isPractice, isTrue);
    });
  });
}
