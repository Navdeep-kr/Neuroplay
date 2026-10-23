import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_actions.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_bank.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_config.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_models.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_scoring.dart';
import 'package:game_engine/src/games/word_weaver/word_weaver_state.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Pure Dart deterministic state machine for Word Weaver.
final class WordWeaverGameEngine extends GameEngineBase {
  WordWeaverGameEngine({
    required WordWeaverConfig super.config,
    this.scoringRules = const WordWeaverScoringRules(),
  }) : weaverConfig = config;

  final WordWeaverConfig weaverConfig;
  final WordWeaverScoringRules scoringRules;

  late WordWeaverTrialState trialState;
  Duration? lastQuestionStartedAt;

  int correctAnswers = 0;
  int incorrectAnswers = 0;
  int currentStreak = 0;
  int maxStreak = 0;
  final List<int> responseTimesMs = [];

  @override
  String get gameId => 'word-weaver';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    _startRound(1, baseTimestamp: Duration.zero);
  }

  void _startRound(int roundNumber, {required Duration baseTimestamp}) {
    lastQuestionStartedAt = baseTimestamp;
    final question = _generateQuestion(roundNumber);

    trialState = WordWeaverTrialState(
      roundIndex: roundNumber,
      question: question,
    );

    state = state.copyWith(
      currentRound: roundNumber,
      customData: {
        'trialState': trialState.toJson(),
      },
    );
  }

  WordWeaverQuestion _generateQuestion(int roundNumber) {
    // 1. Pick target category
    final categories = List<WordCategory>.from(WordCategory.values);
    final targetCategory = random.choice(categories);

    // 2. Get eligible category words
    final categoryItems = WordWeaverBank.items
        .where(
          (i) =>
              i.category == targetCategory &&
              i.difficultyTier <= weaverConfig.maxDifficultyTier,
        )
        .map((i) => i.word)
        .toList();

    // Ensure at least 2 words exist in target category
    final pool = categoryItems.length >= 2
        ? categoryItems
        : WordWeaverBank.items
            .where((i) => i.category == targetCategory)
            .map((i) => i.word)
            .toList();

    final shuffledCategoryWords = random.shuffle(pool);
    final anchorWord = shuffledCategoryWords[0];
    final correctWord = shuffledCategoryWords[1];

    // 3. Pick 3 distractors from other categories
    final otherItems = WordWeaverBank.items
        .where((i) => i.category != targetCategory)
        .map((i) => i.word)
        .toList();

    final shuffledOthers = random.shuffle(otherItems);
    final distractors = <String>{};
    for (final word in shuffledOthers) {
      if (word != anchorWord && word != correctWord) {
        distractors.add(word);
        if (distractors.length == 3) break;
      }
    }

    final options = random.shuffle([correctWord, ...distractors]);

    return WordWeaverQuestion(
      anchorWord: anchorWord,
      category: targetCategory,
      correctAssociatedWord: correctWord,
      options: options,
      relationshipHint:
          'Belongs to ${targetCategory.displayName} (${targetCategory.description})',
    );
  }

  @override
  GameState processAction(GameState currentState, GameAction action) {
    if (action is SelectWordAssociationAction) {
      if (trialState.isAnswered) {
        throw const InvalidActionException('Current question already answered');
      }

      final guess = action.selectedWord;
      final isCorrect = guess == trialState.question.correctAssociatedWord;

      final elapsedMs = lastQuestionStartedAt != null
          ? (action.timestamp - lastQuestionStartedAt!)
              .inMilliseconds
              .clamp(50, 60000)
          : 500;
      responseTimesMs.add(elapsedMs);

      if (isCorrect) {
        correctAnswers++;
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        incorrectAnswers++;
        currentStreak = 0;
      }

      final updatedTrial = trialState.copyWith(
        selectedWord: guess,
        isCorrect: isCorrect,
        isAnswered: true,
        responseTimeMs: elapsedMs,
      );
      trialState = updatedTrial;

      final isLastRound = currentState.currentRound >= currentState.totalRounds;

      if (isLastRound) {
        final breakdown = scoringRules.calculateBreakdown(
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          maxStreak: maxStreak,
          responseTimesMs: responseTimesMs,
          totalDuration: action.timestamp,
          difficulty: weaverConfig.difficulty,
        );

        return currentState.copyWith(
          phase: GamePhase.completed,
          score: breakdown.finalScore,
          streak: currentStreak,
          customData: {
            'trialState': updatedTrial.toJson(),
            'completed': true,
          },
        );
      } else {
        final intermediateBreakdown = scoringRules.calculateBreakdown(
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          maxStreak: maxStreak,
          responseTimesMs: responseTimesMs,
          totalDuration: action.timestamp,
          difficulty: weaverConfig.difficulty,
        );

        final nextRound = currentState.currentRound + 1;
        _startRound(nextRound, baseTimestamp: action.timestamp);

        return state.copyWith(
          score: intermediateBreakdown.finalScore,
          streak: currentStreak,
        );
      }
    }

    throw InvalidActionException('Unknown action type ${action.type}');
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    final total = correctAnswers + incorrectAnswers;
    final accuracy = total > 0 ? (correctAnswers / total).clamp(0.0, 1.0) : 0.0;

    final breakdown = scoringRules.calculateBreakdown(
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      maxStreak: maxStreak,
      responseTimesMs: responseTimesMs,
      totalDuration: totalActiveDuration,
      difficulty: weaverConfig.difficulty,
    );

    final avgResponseTimeMs = responseTimesMs.isNotEmpty
        ? (responseTimesMs.reduce((a, b) => a + b) / responseTimesMs.length)
            .round()
        : 0;

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: weaverConfig.seed,
      difficulty: weaverConfig.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'correctAnswers': correctAnswers,
        'incorrectAnswers': incorrectAnswers,
        'accuracy': accuracy,
        'maxStreak': maxStreak,
        'averageResponseTimeMs': avgResponseTimeMs,
        'isPractice': weaverConfig.isPractice,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
