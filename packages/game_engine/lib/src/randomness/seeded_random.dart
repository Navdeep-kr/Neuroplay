import 'dart:math' as math;

/// Deterministic pseudo-random number generator backed by a specific integer seed.
///
/// Ensures game sequences (stimuli, distractors, delays, card shuffles)
/// can be replayed and verified with bit-for-bit identical transitions.
final class SeededRandom {
  SeededRandom(this.seed) : _random = math.Random(seed);

  final int seed;
  final math.Random _random;

  /// Generates a non-negative random integer in the range [0, max).
  int nextInt(int max) {
    assert(max > 0, 'max must be positive');
    return _random.nextInt(max);
  }

  /// Generates an integer in the inclusive range [min, max].
  int nextIntInRange(int min, int max) {
    assert(max >= min, 'max must be greater than or equal to min');
    if (min == max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates a random floating-point value in [0.0, 1.0).
  double nextDouble() => _random.nextDouble();

  /// Generates a random double in the range [min, max).
  double nextDoubleInRange(double min, double max) {
    assert(max >= min, 'max must be greater than or equal to min');
    return min + (_random.nextDouble() * (max - min));
  }

  /// Generates a boolean, optionally weighted by [trueProbability] (default 0.5).
  bool nextBool({double trueProbability = 0.5}) {
    assert(trueProbability >= 0.0 && trueProbability <= 1.0);
    return _random.nextDouble() < trueProbability;
  }

  /// Picks a random item from a non-empty list.
  T choice<T>(List<T> items) {
    assert(items.isNotEmpty, 'Cannot pick from an empty list');
    return items[_random.nextInt(items.length)];
  }

  /// Shuffles a copy of [items] deterministically.
  List<T> shuffle<T>(List<T> items) {
    final list = List<T>.from(items);
    for (var i = list.length - 1; i > 0; i--) {
      final n = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[n];
      list[n] = temp;
    }
    return list;
  }
}
