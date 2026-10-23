import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import 'fixtures/reaction_time_fixture.dart';

void main() {
  group('GameSession Lifecycle & Deterministic Execution', () {
    late ReactionTimeGameDefinition definition;
    late TestMonotonicClock testClock;

    setUp(() {
      definition = ReactionTimeGameDefinition();
      testClock = TestMonotonicClock();
    });

    test('initializes session in ready phase', () {
      final config = definition.createDefaultConfig(seed: 777);
      final session = GameSession(
        id: 'session-001',
        definition: definition,
        config: config,
        clock: PausableMonotonicClock(baseClock: testClock),
      );

      expect(session.state.phase, equals(GamePhase.ready));
      expect(session.state.currentRound, equals(0));
      expect(session.isFinished, isFalse);
      expect(session.actionHistory, isEmpty);

      session.dispose();
    });

    test('starts session and advances to playing phase', () {
      final config = definition.createDefaultConfig(seed: 777);
      final session = GameSession(
        id: 'session-002',
        definition: definition,
        config: config,
        clock: PausableMonotonicClock(baseClock: testClock),
      );

      final stateEvents = <GameState>[];
      final subscription = session.stateStream.listen(stateEvents.add);

      session.start();

      expect(session.state.phase, equals(GamePhase.playing));
      expect(session.state.currentRound, equals(1));
      expect(session.actionHistory.length, equals(1));
      expect(session.actionHistory.first, isA<StartGameAction>());

      subscription.cancel();
      session.dispose();
    });

    test('pauses, freezes monotonic clock, and resumes seamlessly', () {
      final config = definition.createDefaultConfig(seed: 777);
      final session = GameSession(
        id: 'session-pause',
        definition: definition,
        config: config,
        clock: PausableMonotonicClock(baseClock: testClock),
      );

      session.start();

      testClock.advance(const Duration(milliseconds: 1000));
      expect(
        session.activeDuration,
        equals(const Duration(milliseconds: 1000)),
      );

      // User pauses
      session.pause(reason: 'user_pause_menu');
      expect(session.state.phase, equals(GamePhase.paused));

      // 4000ms passes in background or pause menu
      testClock.advance(const Duration(milliseconds: 4000));
      expect(
        session.activeDuration,
        equals(const Duration(milliseconds: 1000)),
      );

      // Resume
      session.resume();
      expect(session.state.phase, equals(GamePhase.playing));

      testClock.advance(const Duration(milliseconds: 500));
      expect(
        session.activeDuration,
        equals(const Duration(milliseconds: 1500)),
      );

      session.dispose();
    });

    test('aborts session and prevents subsequent gameplay actions', () {
      final config = definition.createDefaultConfig(seed: 100);
      final session = GameSession(
        id: 'session-abort',
        definition: definition,
        config: config,
        clock: PausableMonotonicClock(baseClock: testClock),
      );

      session.start();
      session.abort(reason: 'user_exit');

      expect(session.state.phase, equals(GamePhase.aborted));
      expect(session.isFinished, isTrue);

      expect(
        () => session.dispatch(
          RespondAction(
            timestamp: const Duration(seconds: 2),
            responseValue: true,
            targetId: 'stimulus-1',
          ),
        ),
        throwsA(isA<InvalidActionException>()),
      );

      session.dispose();
    });

    test('safely penalizes early taps without crashing', () {
      final config = definition.createDefaultConfig(seed: 42);
      final session = GameSession(
        id: 'session-early',
        definition: definition,
        config: config,
        clock: PausableMonotonicClock(baseClock: testClock),
      );

      session.start();

      // Tap immediately (at 100ms), before stimulus delay (which is > 1000ms)
      testClock.advance(const Duration(milliseconds: 100));
      final applied = session.dispatch(
        RespondAction(
          timestamp: testClock.elapsed,
          responseValue: 'tap',
          targetId: 'screen',
        ),
      );

      expect(applied, isTrue);
      expect(session.state.customData['earlyTap'], isTrue);
      expect(session.state.customData['penaltyCount'], equals(1));
      expect(session.state.currentRound, equals(1)); // Did not advance round

      session.dispose();
    });

    test('determines identical states and results across two seeded runs', () {
      // Run Session A
      final clockA = TestMonotonicClock();
      final configA = definition.createDefaultConfig(seed: 9999);
      final sessionA = GameSession(
        id: 'sess-A',
        definition: definition,
        config: configA,
        clock: PausableMonotonicClock(baseClock: clockA),
      );

      // Run Session B
      final clockB = TestMonotonicClock();
      final configB = definition.createDefaultConfig(seed: 9999);
      final sessionB = GameSession(
        id: 'sess-B',
        definition: definition,
        config: configB,
        clock: PausableMonotonicClock(baseClock: clockB),
      );

      sessionA.start();
      sessionB.start();

      // Find first stimulus delay (identical for both)
      final engineA = sessionA.engine as ReactionTimeGameEngine;
      final engineB = sessionB.engine as ReactionTimeGameEngine;
      expect(
        engineA.currentStimulusShownAt,
        equals(engineB.currentStimulusShownAt),
      );

      // Advance clock past stimulus for round 1
      final delay1 =
          engineA.currentStimulusShownAt! + const Duration(milliseconds: 250);
      clockA.setElapsed(delay1);
      clockB.setElapsed(delay1);

      sessionA.dispatch(
        RespondAction(timestamp: delay1, responseValue: 'tap', targetId: '1'),
      );
      sessionB.dispatch(
        RespondAction(timestamp: delay1, responseValue: 'tap', targetId: '1'),
      );

      expect(sessionA.state.currentRound, equals(2));
      expect(sessionB.state.currentRound, equals(2));
      expect(
        engineA.currentStimulusShownAt,
        equals(engineB.currentStimulusShownAt),
      );

      // Advance clock past stimulus for round 2
      final delay2 =
          engineA.currentStimulusShownAt! + const Duration(milliseconds: 300);
      clockA.setElapsed(delay2);
      clockB.setElapsed(delay2);

      sessionA.dispatch(
        RespondAction(timestamp: delay2, responseValue: 'tap', targetId: '2'),
      );
      sessionB.dispatch(
        RespondAction(timestamp: delay2, responseValue: 'tap', targetId: '2'),
      );

      // Advance clock past stimulus for round 3 (final)
      final delay3 =
          engineA.currentStimulusShownAt! + const Duration(milliseconds: 220);
      clockA.setElapsed(delay3);
      clockB.setElapsed(delay3);

      sessionA.dispatch(
        RespondAction(timestamp: delay3, responseValue: 'tap', targetId: '3'),
      );
      sessionB.dispatch(
        RespondAction(timestamp: delay3, responseValue: 'tap', targetId: '3'),
      );

      expect(sessionA.state.phase, equals(GamePhase.completed));
      expect(sessionB.state.phase, equals(GamePhase.completed));

      final resultA = sessionA.finish(isOffline: true);
      final resultB = sessionB.finish(isOffline: true);

      // Verify bit-for-bit identical scores, metrics, and breakdowns
      expect(resultA.finalScore, equals(resultB.finalScore));
      expect(resultA.scoreBreakdown, equals(resultB.scoreBreakdown));
      expect(
        resultA.metrics['averageReactionTimeMs'],
        equals(resultB.metrics['averageReactionTimeMs']),
      );
      expect(
        resultA.metrics['bestReactionTimeMs'],
        equals(resultB.metrics['bestReactionTimeMs']),
      );
      expect(resultA.totalActions, equals(resultB.totalActions));

      sessionA.dispose();
      sessionB.dispose();
    });
  });
}
