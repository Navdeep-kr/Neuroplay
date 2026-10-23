import 'package:meta/meta.dart';

/// Abstract monotonic time source.
///
/// Unlike wall-clock time (`DateTime.now()`), a monotonic clock cannot jump
/// backwards or forwards due to system time adjustments, NTP syncs, or daylight savings.
abstract interface class MonotonicClock {
  /// Returns the current monotonic elapsed time relative to when this clock started.
  Duration get elapsed;

  /// Whether the clock is currently running.
  bool get isRunning;
}

/// System-level monotonic clock backed by [Stopwatch].
final class SystemMonotonicClock implements MonotonicClock {
  SystemMonotonicClock() : _stopwatch = Stopwatch();

  final Stopwatch _stopwatch;

  void start() => _stopwatch.start();
  void stop() => _stopwatch.stop();
  void reset() => _stopwatch.reset();

  @override
  Duration get elapsed => _stopwatch.elapsed;

  @override
  bool get isRunning => _stopwatch.isRunning;
}

/// Controllable monotonic clock for reproducible unit tests.
@visibleForTesting
final class TestMonotonicClock implements MonotonicClock {
  TestMonotonicClock({Duration initialElapsed = Duration.zero})
      : _elapsed = initialElapsed,
        _isRunning = false;

  Duration _elapsed;
  bool _isRunning;

  @override
  Duration get elapsed => _elapsed;

  @override
  bool get isRunning => _isRunning;

  void start() => _isRunning = true;
  void stop() => _isRunning = false;
  void reset() => _elapsed = Duration.zero;

  /// Advances the clock by [duration] (only if running or [force] is true).
  void advance(Duration duration, {bool force = false}) {
    if (_isRunning || force) {
      _elapsed += duration;
    }
  }

  void setElapsed(Duration duration) {
    _elapsed = duration;
  }
}

/// A monotonic stopwatch that properly accumulates active game duration
/// while ignoring time spent in paused or background states.
final class PausableMonotonicClock {
  PausableMonotonicClock({MonotonicClock? baseClock})
      : _clock = baseClock ?? SystemMonotonicClock();

  final MonotonicClock _clock;
  Duration _accumulatedActive = Duration.zero;
  Duration? _lastActiveStartedAt;
  bool _isPaused = true;

  /// Total active duration elapsed while running (excluding pause intervals).
  Duration get elapsedActiveTime {
    if (_isPaused || _lastActiveStartedAt == null) {
      return _accumulatedActive;
    }
    final currentSegment = _clock.elapsed - _lastActiveStartedAt!;
    return _accumulatedActive + currentSegment;
  }

  /// Whether the pausable clock is currently actively running.
  bool get isRunning => !_isPaused;

  /// Starts or resumes the clock.
  void start() {
    if (!_isPaused) return;
    final base = _clock;
    if (base is SystemMonotonicClock && !base.isRunning) {
      base.start();
    } else if (base is TestMonotonicClock && !base.isRunning) {
      base.start();
    }
    _isPaused = false;
    _lastActiveStartedAt = _clock.elapsed;
  }

  /// Pauses the clock, freezing elapsed active duration.
  void pause() {
    if (_isPaused) return;
    if (_lastActiveStartedAt != null) {
      _accumulatedActive += _clock.elapsed - _lastActiveStartedAt!;
    }
    _lastActiveStartedAt = null;
    _isPaused = true;
  }

  /// Resets the clock to zero.
  void reset() {
    _accumulatedActive = Duration.zero;
    _lastActiveStartedAt = null;
    _isPaused = true;
  }
}
