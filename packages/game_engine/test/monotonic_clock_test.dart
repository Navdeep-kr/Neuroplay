import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Monotonic Timing & PausableClock', () {
    test('TestMonotonicClock advances deterministically', () {
      final clock = TestMonotonicClock();
      expect(clock.elapsed, equals(Duration.zero));
      expect(clock.isRunning, isFalse);

      clock.start();
      expect(clock.isRunning, isTrue);

      clock.advance(const Duration(milliseconds: 500));
      expect(clock.elapsed, equals(const Duration(milliseconds: 500)));

      clock.stop();
      expect(clock.isRunning, isFalse);

      // advancing while stopped does not increase elapsed unless forced
      clock.advance(const Duration(milliseconds: 500));
      expect(clock.elapsed, equals(const Duration(milliseconds: 500)));
    });

    test('PausableMonotonicClock ignores elapsed time while paused', () {
      final baseClock = TestMonotonicClock();
      final pausable = PausableMonotonicClock(baseClock: baseClock);

      // Initially paused
      expect(pausable.elapsedActiveTime, equals(Duration.zero));
      expect(pausable.isRunning, isFalse);

      // Start game
      pausable.start();
      expect(pausable.isRunning, isTrue);

      // 1000ms active gameplay
      baseClock.advance(const Duration(milliseconds: 1000));
      expect(
        pausable.elapsedActiveTime,
        equals(const Duration(milliseconds: 1000)),
      );

      // User pauses or app interrupted
      pausable.pause();
      expect(pausable.isRunning, isFalse);

      // 5000ms spent in background or pause menu
      baseClock.advance(const Duration(milliseconds: 5000));
      expect(
        pausable.elapsedActiveTime,
        equals(const Duration(milliseconds: 1000)),
      );

      // Resume gameplay
      pausable.resume();
      expect(pausable.isRunning, isTrue);

      // Another 500ms active gameplay
      baseClock.advance(const Duration(milliseconds: 500));
      expect(
        pausable.elapsedActiveTime,
        equals(const Duration(milliseconds: 1500)),
      );
    });
  });
}

extension on PausableMonotonicClock {
  void resume() => start();
}
