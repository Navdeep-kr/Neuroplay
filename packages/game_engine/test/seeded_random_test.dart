import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('SeededRandom Determinism', () {
    test('identical seeds generate identical integer sequences', () {
      final rngA = SeededRandom(98765);
      final rngB = SeededRandom(98765);

      final sequenceA = List.generate(50, (_) => rngA.nextInt(1000));
      final sequenceB = List.generate(50, (_) => rngB.nextInt(1000));

      expect(sequenceA, equals(sequenceB));
    });

    test('identical seeds generate identical range ints and doubles', () {
      final rngA = SeededRandom(42);
      final rngB = SeededRandom(42);

      for (var i = 0; i < 20; i++) {
        expect(
          rngA.nextIntInRange(50, 150),
          equals(rngB.nextIntInRange(50, 150)),
        );
        expect(
          rngA.nextDoubleInRange(1.5, 9.5),
          equals(rngB.nextDoubleInRange(1.5, 9.5)),
        );
        expect(
          rngA.nextBool(trueProbability: 0.3),
          equals(rngB.nextBool(trueProbability: 0.3)),
        );
      }
    });

    test('shuffle and choice are deterministic for same seed', () {
      final rngA = SeededRandom(1337);
      final rngB = SeededRandom(1337);

      final items = ['alpha', 'bravo', 'charlie', 'delta', 'echo'];

      expect(rngA.choice(items), equals(rngB.choice(items)));
      expect(rngA.shuffle(items), equals(rngB.shuffle(items)));
    });

    test('different seeds produce different sequences', () {
      final rng1 = SeededRandom(1111);
      final rng2 = SeededRandom(2222);

      final seq1 = List.generate(20, (_) => rng1.nextInt(10000));
      final seq2 = List.generate(20, (_) => rng2.nextInt(10000));

      expect(seq1, isNot(equals(seq2)));
    });
  });
}
