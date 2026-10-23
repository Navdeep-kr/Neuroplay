import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('GameEngineVersion', () {
    test('parses standard semver strings correctly', () {
      final v = GameEngineVersion.parse('1.4.2');
      expect(v.major, equals(1));
      expect(v.minor, equals(4));
      expect(v.patch, equals(2));
      expect(v.preRelease, isNull);
      expect(v.toString(), equals('1.4.2'));
    });

    test('parses pre-release semver string', () {
      final v = GameEngineVersion.parse('2.0.0-beta.1');
      expect(v.major, equals(2));
      expect(v.minor, equals(0));
      expect(v.patch, equals(0));
      expect(v.preRelease, equals('beta.1'));
      expect(v.toString(), equals('2.0.0-beta.1'));
    });

    test('throws GameValidationException on malformed strings', () {
      expect(
        () => GameEngineVersion.parse('1.0'),
        throwsA(isA<GameValidationException>()),
      );
      expect(
        () => GameEngineVersion.parse('invalid'),
        throwsA(isA<GameValidationException>()),
      );
      expect(
        () => GameEngineVersion.parse('1.a.3'),
        throwsA(isA<GameValidationException>()),
      );
    });

    test('correctly evaluates compatibility rules', () {
      const required = GameEngineVersion(1, 2, 0);
      expect(
        const GameEngineVersion(1, 2, 0).isCompatibleWith(required),
        isTrue,
      );
      expect(
        const GameEngineVersion(1, 3, 0).isCompatibleWith(required),
        isTrue,
      );
      expect(
        const GameEngineVersion(1, 2, 5).isCompatibleWith(required),
        isTrue,
      );
      // Older minor or different major
      expect(
        const GameEngineVersion(1, 1, 9).isCompatibleWith(required),
        isFalse,
      );
      expect(
        const GameEngineVersion(2, 0, 0).isCompatibleWith(required),
        isFalse,
      );
    });

    test('implements Comparable and equality', () {
      const v1 = GameEngineVersion(1, 0, 0);
      const v2 = GameEngineVersion(1, 1, 0);
      const v3 = GameEngineVersion(2, 0, 0);

      expect(v1 < v2, isTrue);
      expect(v2 < v3, isTrue);
      expect(v1 == const GameEngineVersion(1, 0, 0), isTrue);
    });

    test('serializes and deserializes to JSON', () {
      const v = GameEngineVersion(1, 2, 3, preRelease: 'rc1');
      final json = v.toJson();
      final restored = GameEngineVersion.fromJson(json);
      expect(restored, equals(v));
    });
  });

  group('GameDifficulty', () {
    test('provides preset difficulty multipliers', () {
      expect(GameDifficulty.easy.multiplier, equals(1.0));
      expect(GameDifficulty.medium.multiplier, equals(1.25));
      expect(GameDifficulty.hard.multiplier, equals(1.5));
      expect(GameDifficulty.expert.multiplier, equals(2.0));
    });

    test('serializes and parses by string name', () {
      final parsed = GameDifficulty.fromJson('hard');
      expect(parsed, equals(GameDifficulty.hard));
    });

    test('throws on unknown difficulty name', () {
      expect(
        () => GameDifficulty.fromJson('legendary'),
        throwsA(isA<GameValidationException>()),
      );
    });
  });

  group('GamePhase', () {
    test('enforces legal lifecycle transitions', () {
      expect(GamePhase.ready.canTransitionTo(GamePhase.playing), isTrue);
      expect(GamePhase.ready.canTransitionTo(GamePhase.countdown), isTrue);
      expect(GamePhase.playing.canTransitionTo(GamePhase.paused), isTrue);
      expect(GamePhase.paused.canTransitionTo(GamePhase.playing), isTrue);
      expect(GamePhase.playing.canTransitionTo(GamePhase.completed), isTrue);
      expect(GamePhase.playing.canTransitionTo(GamePhase.aborted), isTrue);
    });

    test('blocks illegal transitions and terminal state changes', () {
      expect(GamePhase.ready.canTransitionTo(GamePhase.completed), isFalse);
      expect(GamePhase.completed.canTransitionTo(GamePhase.playing), isFalse);
      expect(GamePhase.aborted.canTransitionTo(GamePhase.ready), isFalse);

      expect(
        () => GamePhase.completed.assertCanTransitionTo(GamePhase.playing),
        throwsA(isA<GamePhaseException>()),
      );
    });
  });

  group('GameConfig', () {
    test('validates valid configuration', () {
      const config = GameConfig(
        seed: 12345,
        totalRounds: 5,
        timeLimit: Duration(seconds: 30),
      );
      expect(config.validate, returnsNormally);
    });

    test('throws validation exception on zero or negative rounds', () {
      expect(
        () => GameConfig(seed: 1, totalRounds: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
