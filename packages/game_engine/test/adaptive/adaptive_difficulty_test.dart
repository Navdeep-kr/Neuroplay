import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Adaptive Difficulty Engine Unit Tests', () {
    late AdaptiveDifficultyEngine engine;

    setUp(() {
      engine = AdaptiveDifficultyEngine();
    });

    GameResult createMockResult({
      required String gameId,
      required double accuracy,
      int avgRtMs = 600,
      bool isPractice = false,
      GamePhase phase = GamePhase.completed,
      Duration duration = const Duration(seconds: 45),
      Map<String, dynamic>? extraMetrics,
    }) {
      final breakdown = ScoreBreakdown(
        rawScore: (accuracy * 500).round(),
        accuracyBonus: (accuracy * 200).round(),
        speedBonus: 50,
        finalScore: (accuracy * 750).round(),
      );

      return GameResult(
        sessionId: 'sess-${DateTime.now().millisecondsSinceEpoch}',
        gameId: gameId,
        gameVersion: '1.0.0',
        engineVersion: '1.0.0',
        scoringRulesVersion: '1.0.0',
        seed: 42,
        difficulty: GameDifficulty.medium,
        completionPhase: phase,
        finalScore: breakdown.finalScore,
        scoreBreakdown: breakdown,
        totalActiveDuration: duration,
        totalActions: 20,
        metrics: {
          'accuracy': accuracy,
          'averageResponseTimeMs': avgRtMs,
          'isPractice': isPractice,
          ...?extraMetrics,
        },
        completedAt: DateTime.now(),
      );
    }

    test('new user / missing history creates sensible baseline estimate', () {
      final estimate = SkillEstimate.initial('memory-matrix');

      expect(estimate.gameId, equals('memory-matrix'));
      expect(estimate.rating, equals(50.0));
      expect(estimate.recommendedDifficulty, equals(GameDifficulty.medium));
      expect(estimate.sampleCount, equals(0));
      expect(
        estimate.lastAdjustmentReason,
        contains('Initial baseline calibrated for new player'),
      );
      expect(SkillEstimate.nonClinicalDisclaimer, contains('non-clinical'));
      expect(SkillEstimate.nonClinicalDisclaimer, contains('IQ'));
    });

    test('high accuracy increases rating and graduates difficulty smoothly',
        () {
      var profile = SkillEstimate.initial(
        'reflex-forge',
        defaultDifficulty: GameDifficulty.medium,
      );

      // Session 1: High accuracy
      final result1 = createMockResult(
        gameId: 'reflex-forge',
        accuracy: 0.95,
        avgRtMs: 450,
      );
      final eval1 = engine.evaluateSession(
        result: result1,
        currentEstimate: profile,
      );
      profile = eval1.updatedEstimate;

      expect(profile.rating, greaterThan(50.0));
      expect(profile.consecutiveStrongSessions, equals(1));
      expect(profile.sampleCount, equals(1));

      // Session 2: Another strong session advances toward graduation
      final result2 = createMockResult(
        gameId: 'reflex-forge',
        accuracy: 0.96,
        avgRtMs: 420,
      );
      final eval2 = engine.evaluateSession(
        result: result2,
        currentEstimate: profile,
      );
      profile = eval2.updatedEstimate;

      expect(profile.consecutiveStrongSessions, equals(2));
      expect(eval2.adjustment.reason, contains('performance'));
    });

    test('step damping strictly bounds maximum rating delta per single session',
        () {
      final baseline = SkillEstimate.initial('memory-matrix');

      // Even a 100% perfect score cannot exceed maxDeltaPerSession
      final perfectResult = createMockResult(
        gameId: 'memory-matrix',
        accuracy: 1.0,
        extraMetrics: {'perfectRounds': 5, 'mistakeCount': 0},
      );

      final eval = engine.evaluateSession(
        result: perfectResult,
        currentEstimate: baseline,
      );

      final delta = (eval.updatedEstimate.rating - baseline.rating).abs();
      expect(
        delta,
        lessThanOrEqualTo(AdaptiveDifficultyEngine.maxDeltaPerSession),
      );
    });

    test('repeated failures decrease rating smoothly without cliff drops', () {
      var profile = SkillEstimate.initial(
        'focus-reactor',
        defaultDifficulty: GameDifficulty.hard,
      ).copyWith(rating: 70.0, recommendedDifficulty: GameDifficulty.hard);

      // Session 1: low accuracy
      final result1 = createMockResult(
        gameId: 'focus-reactor',
        accuracy: 0.40,
        avgRtMs: 1400,
        extraMetrics: {'falseAlarms': 4},
      );
      final eval1 = engine.evaluateSession(
        result: result1,
        currentEstimate: profile,
      );
      profile = eval1.updatedEstimate;

      expect(profile.rating, lessThan(70.0));
      expect(
        profile.rating,
        greaterThanOrEqualTo(
          70.0 - AdaptiveDifficultyEngine.maxDeltaPerSession,
        ),
      );
      expect(profile.consecutiveWeakSessions, equals(1));

      // Session 2: repeated low accuracy
      final result2 = createMockResult(
        gameId: 'focus-reactor',
        accuracy: 0.35,
        avgRtMs: 1600,
        extraMetrics: {'falseAlarms': 5},
      );
      final eval2 = engine.evaluateSession(
        result: result2,
        currentEstimate: profile,
      );
      profile = eval2.updatedEstimate;

      expect(profile.consecutiveWeakSessions, equals(2));
      expect(profile.recommendedDifficulty, equals(GameDifficulty.medium));
      expect(eval2.adjustment.reason, contains('adjusted down'));
    });

    test('handles extreme response times safely (button mashing vs afk idle)',
        () {
      const rule = ReflexForgeDifficultyRule();

      // Case A: 50ms (inhuman button mashing)
      final mashingRt = rule.computeRobustMedianRt([50, 60, 45, 55]);
      expect(mashingRt, isNull); // Filtered out as anticipatory noise

      // Case B: normal RTs mixed with 50ms and 15000ms afk pause
      final mixed = rule.computeRobustMedianRt([60, 450, 480, 520, 20000]);
      expect(
        mixed,
        equals(480.0),
      ); // Median cleanly picks true representative RT
    });

    test('practice mode sessions do not alter durable skill rating', () {
      final baseline = SkillEstimate.initial('number-pulse');

      final practiceResult = createMockResult(
        gameId: 'number-pulse',
        accuracy: 1.0,
        isPractice: true,
      );

      final eval = engine.evaluateSession(
        result: practiceResult,
        currentEstimate: baseline,
      );

      expect(eval.updatedEstimate.rating, equals(baseline.rating));
      expect(eval.updatedEstimate.sampleCount, equals(baseline.sampleCount));
      expect(eval.adjustment.ratingDelta, equals(0.0));
      expect(eval.adjustment.reason, contains('Practice mode'));
    });

    test('aborted or ultra-short (<2s) sessions do not alter skill rating', () {
      final baseline = SkillEstimate.initial('logic-labyrinth');

      // Aborted session
      final abortedResult = createMockResult(
        gameId: 'logic-labyrinth',
        accuracy: 0.1,
        phase: GamePhase.aborted,
      );
      final evalAborted = engine.evaluateSession(
        result: abortedResult,
        currentEstimate: baseline,
      );
      expect(evalAborted.updatedEstimate.rating, equals(baseline.rating));

      // Too short (< 2s)
      final tooShortResult = createMockResult(
        gameId: 'logic-labyrinth',
        accuracy: 0.1,
        duration: const Duration(milliseconds: 900),
      );
      final evalShort = engine.evaluateSession(
        result: tooShortResult,
        currentEstimate: baseline,
      );
      expect(evalShort.updatedEstimate.rating, equals(baseline.rating));
      expect(evalShort.adjustment.reason, contains('minimum valid threshold'));
    });

    test('records algorithm version and supports algorithm version changes',
        () {
      final engineV2 = AdaptiveDifficultyEngine(algorithmVersion: '2.0.0');
      final baseline = SkillEstimate.initial(
        'word-weaver',
        algorithmVersion: '1.0.0',
      );

      final result = createMockResult(
        gameId: 'word-weaver',
        accuracy: 0.85,
        avgRtMs: 1400,
      );

      final eval = engineV2.evaluateSession(
        result: result,
        currentEstimate: baseline,
      );

      expect(eval.updatedEstimate.algorithmVersion, equals('2.0.0'));
      expect(eval.adjustment.algorithmVersion, equals('2.0.0'));
    });
  });
}
