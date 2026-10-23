import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('ScoringRules & ScoreBreakdown', () {
    const rules = StandardScoringRules(
      version: '1.0.0',
      basePoints: 100,
      accuracyWeight: 500,
      penaltyPerMistake: 20,
    );

    test('calculates transparent score breakdown', () {
      final breakdown = rules.calculateScore(
        rawPoints: 200,
        activeDuration: const Duration(milliseconds: 400),
        accuracy: 0.9,
        difficulty: GameDifficulty.medium, // 1.25 multiplier
        streak: 3,
        penaltyCount: 1,
      );

      expect(breakdown.rawScore, equals(200));
      expect(breakdown.accuracyBonus, equals(450)); // 0.9 * 500
      expect(breakdown.streakBonus, equals(30)); // 3 * 10
      expect(breakdown.penalties, equals(20)); // 1 * 20
      expect(breakdown.finalScore, greaterThan(breakdown.rawScore));
    });

    test('validates accuracy bounds and rejects invalid values', () {
      expect(
        () => rules.calculateScore(
          rawPoints: 100,
          activeDuration: Duration.zero,
          accuracy: 1.5, // invalid
          difficulty: GameDifficulty.easy,
        ),
        throwsA(isA<GameValidationException>()),
      );

      expect(
        () => rules.calculateScore(
          rawPoints: -10, // negative raw points
          activeDuration: Duration.zero,
          accuracy: 0.8,
          difficulty: GameDifficulty.easy,
        ),
        throwsA(isA<GameValidationException>()),
      );
    });

    test('ScoreBreakdown round-trips via JSON serialization', () {
      const original = ScoreBreakdown(
        rawScore: 350,
        accuracyBonus: 400,
        speedBonus: 100,
        difficultyBonus: 125,
        streakBonus: 50,
        penalties: 20,
        finalScore: 1005,
      );

      final json = original.toJson();
      final restored = ScoreBreakdown.fromJson(json);

      expect(restored, equals(original));
    });
  });
}
