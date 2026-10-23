import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('GameResult Serialization & Validation', () {
    final validResult = GameResult(
      sessionId: 'sess-12345',
      gameId: 'reaction-time',
      gameVersion: '1.0.0',
      engineVersion: '1.0.0',
      scoringRulesVersion: '1.0.0',
      seed: 42,
      difficulty: GameDifficulty.hard,
      completionPhase: GamePhase.completed,
      finalScore: 1250,
      scoreBreakdown: const ScoreBreakdown(
        rawScore: 240,
        accuracyBonus: 300,
        speedBonus: 200,
        difficultyBonus: 350,
        finalScore: 1250,
      ),
      totalActiveDuration: const Duration(seconds: 14, milliseconds: 320),
      totalActions: 8,
      metrics: {
        'averageReactionTimeMs': 240,
        'bestReactionTimeMs': 210,
        'accuracyPercent': 100,
      },
      completedAt: DateTime.parse('2026-10-23T12:00:00.000Z'),
      isOffline: true,
    );

    test('serializes and deserializes accurately to JSON', () {
      final json = validResult.toJson();
      final restored = GameResult.fromJson(json);

      expect(restored, equals(validResult));
      expect(restored.sessionId, equals('sess-12345'));
      expect(restored.gameId, equals('reaction-time'));
      expect(restored.difficulty, equals(GameDifficulty.hard));
      expect(restored.finalScore, equals(1250));
      expect(restored.isOffline, isTrue);
      expect(restored.metrics['averageReactionTimeMs'], equals(240));
    });

    test('rejects empty sessionId or gameId', () {
      expect(
        () => GameResult(
          sessionId: '',
          gameId: 'reaction-time',
          gameVersion: '1.0.0',
          engineVersion: '1.0.0',
          scoringRulesVersion: '1.0.0',
          seed: 1,
          difficulty: GameDifficulty.easy,
          completionPhase: GamePhase.completed,
          finalScore: 100,
          scoreBreakdown: const ScoreBreakdown(rawScore: 100, finalScore: 100),
          totalActiveDuration: Duration.zero,
          totalActions: 1,
          metrics: const {},
          completedAt: DateTime.now(),
        ),
        throwsA(isA<GameValidationException>()),
      );
    });

    test('rejects non-terminal completion phase', () {
      expect(
        () => GameResult(
          sessionId: 'test',
          gameId: 'reaction-time',
          gameVersion: '1.0.0',
          engineVersion: '1.0.0',
          scoringRulesVersion: '1.0.0',
          seed: 1,
          difficulty: GameDifficulty.easy,
          completionPhase: GamePhase.playing, // not terminal!
          finalScore: 100,
          scoreBreakdown: const ScoreBreakdown(rawScore: 100, finalScore: 100),
          totalActiveDuration: Duration.zero,
          totalActions: 1,
          metrics: const {},
          completedAt: DateTime.now(),
        ),
        throwsA(isA<GameValidationException>()),
      );
    });

    test('rejects negative final score or duration', () {
      expect(
        () => GameResult(
          sessionId: 'test',
          gameId: 'reaction-time',
          gameVersion: '1.0.0',
          engineVersion: '1.0.0',
          scoringRulesVersion: '1.0.0',
          seed: 1,
          difficulty: GameDifficulty.easy,
          completionPhase: GamePhase.completed,
          finalScore: -50,
          scoreBreakdown: const ScoreBreakdown(rawScore: 0, finalScore: 0),
          totalActiveDuration: Duration.zero,
          totalActions: 0,
          metrics: const {},
          completedAt: DateTime.now(),
        ),
        throwsA(isA<GameValidationException>()),
      );
    });
  });
}
