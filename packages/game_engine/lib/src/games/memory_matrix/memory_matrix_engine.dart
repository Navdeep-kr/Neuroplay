import 'dart:math' as math;
import 'package:game_engine/src/contracts/game_action.dart';
import 'package:game_engine/src/contracts/game_engine_version.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:game_engine/src/contracts/game_result.dart';
import 'package:game_engine/src/contracts/game_state.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_actions.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_config.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_scoring.dart';
import 'package:game_engine/src/games/memory_matrix/memory_matrix_state.dart';
import 'package:game_engine/src/session/game_engine_base.dart';

/// Deterministic state machine engine for Memory Matrix.
final class MemoryMatrixGameEngine extends GameEngineBase {
  MemoryMatrixGameEngine({
    required MemoryMatrixConfig super.config,
    this.scoringRules = const MemoryMatrixScoringRules(),
  }) : matrixConfig = config;

  final MemoryMatrixConfig matrixConfig;
  final MemoryMatrixScoringRules scoringRules;

  late MemoryMatrixRoundState roundState;
  int totalCorrectSelections = 0;
  int totalMistakes = 0;
  int perfectRounds = 0;

  @override
  String get gameId => 'memory-matrix';

  @override
  String get gameVersion => '1.0.0';

  @override
  String get scoringRulesVersion => scoringRules.version;

  @override
  void onGameStarted() {
    _startRound(1);
  }

  void _startRound(int roundNumber) {
    // Deterministically generate unique target indices for this round using SeededRandom
    final totalTiles = matrixConfig.totalTiles;
    final allIndices = List.generate(totalTiles, (i) => i);
    final shuffled = random.shuffle(allIndices);

    // Dynamic targets per difficulty/round: easy starts at 3, increases slightly
    final targetCount = math.min(
      matrixConfig.targetCount + (roundNumber > 3 ? 1 : 0),
      totalTiles - 2,
    );
    final targets = shuffled.take(targetCount).toList()..sort();

    roundState = MemoryMatrixRoundState(
      roundPhase: MemoryMatrixRoundPhase.memorize,
      targetIndices: targets,
      selectedCorrectIndices: const {},
      selectedMistakeIndices: const {},
    );

    state = state.copyWith(
      currentRound: roundNumber,
      customData: {
        'gridSize': matrixConfig.gridSize,
        'roundState': roundState.toJson(),
      },
    );
  }

  @override
  GameState processAction(GameState currentState, GameAction action) {
    if (action is BeginRecallAction) {
      if (!roundState.isMemorizing) {
        throw const InvalidActionException(
          'Cannot begin recall outside of memorize phase',
        );
      }
      roundState = roundState.copyWith(
        roundPhase: MemoryMatrixRoundPhase.recall,
      );
      return currentState.copyWith(
        customData: {
          'gridSize': matrixConfig.gridSize,
          'roundState': roundState.toJson(),
        },
      );
    }

    if (action is SelectTileAction) {
      if (!roundState.isRecalling) {
        throw const InvalidActionException(
          'Cannot select tile when not in recall phase',
        );
      }
      final tileIndex = action.tileIndex;
      if (tileIndex < 0 || tileIndex >= matrixConfig.totalTiles) {
        throw GameValidationException('Tile index $tileIndex out of bounds');
      }

      // Ignore already selected tiles
      if (roundState.selectedCorrectIndices.contains(tileIndex) ||
          roundState.selectedMistakeIndices.contains(tileIndex)) {
        return currentState;
      }

      final isTarget = roundState.targetIndices.contains(tileIndex);

      if (isTarget) {
        final newCorrect = Set<int>.from(roundState.selectedCorrectIndices)
          ..add(tileIndex);
        totalCorrectSelections++;
        final roundDone = newCorrect.length == roundState.targetIndices.length;

        if (roundDone) {
          final isPerfect = roundState.selectedMistakeIndices.isEmpty;
          if (isPerfect) perfectRounds++;

          final roundScore =
              (newCorrect.length * scoringRules.pointsPerCorrectTile) +
                  (isPerfect ? scoringRules.perfectRoundBonus : 0);

          final nextRound = currentState.currentRound + 1;
          final isGameFinished = nextRound > currentState.totalRounds;

          if (isGameFinished) {
            roundState = roundState.copyWith(
              selectedCorrectIndices: newCorrect,
              roundPhase: MemoryMatrixRoundPhase.feedback,
              roundCompletedSuccessfully: true,
            );
            return currentState.copyWith(
              phase: GamePhase.completed,
              score: currentState.score + roundScore,
              streak: currentState.streak + (isPerfect ? 1 : 0),
              customData: {
                'gridSize': matrixConfig.gridSize,
                'roundState': roundState.toJson(),
                'completed': true,
              },
            );
          } else {
            // Advance to next round
            _startRound(nextRound);
            return state.copyWith(
              score: currentState.score + roundScore,
              streak: currentState.streak + (isPerfect ? 1 : 0),
            );
          }
        } else {
          // Correct, but round continues
          roundState = roundState.copyWith(selectedCorrectIndices: newCorrect);
          return currentState.copyWith(
            score: currentState.score + scoringRules.pointsPerCorrectTile,
            customData: {
              'gridSize': matrixConfig.gridSize,
              'roundState': roundState.toJson(),
            },
          );
        }
      } else {
        // Mistake
        totalMistakes++;
        final newMistakes = Set<int>.from(roundState.selectedMistakeIndices)
          ..add(tileIndex);
        roundState = roundState.copyWith(selectedMistakeIndices: newMistakes);

        // Maximum 3 mistakes allowed before advancing to prevent infinite stalls
        final tooManyMistakes = newMistakes.length >= 3;

        if (tooManyMistakes) {
          final nextRound = currentState.currentRound + 1;
          final isGameFinished = nextRound > currentState.totalRounds;

          if (isGameFinished) {
            roundState = roundState.copyWith(
              roundPhase: MemoryMatrixRoundPhase.feedback,
              roundCompletedSuccessfully: false,
            );
            return currentState.copyWith(
              phase: GamePhase.completed,
              streak: 0,
              customData: {
                'gridSize': matrixConfig.gridSize,
                'roundState': roundState.toJson(),
                'completed': true,
              },
            );
          } else {
            _startRound(nextRound);
            return state.copyWith(streak: 0);
          }
        }

        return currentState.copyWith(
          streak: 0,
          customData: {
            'gridSize': matrixConfig.gridSize,
            'roundState': roundState.toJson(),
          },
        );
      }
    }

    return currentState;
  }

  @override
  GameResult computeResult({
    required String sessionId,
    required Duration totalActiveDuration,
    required int totalActions,
    bool isOffline = false,
  }) {
    final totalSelections = totalCorrectSelections + totalMistakes;
    final accuracy = totalSelections > 0
        ? (totalCorrectSelections / totalSelections).clamp(0.0, 1.0)
        : 0.0;

    final breakdown = scoringRules.calculateScore(
      rawPoints: state.score,
      activeDuration: totalActiveDuration,
      accuracy: accuracy,
      difficulty: matrixConfig.difficulty,
      streak: perfectRounds,
      penaltyCount: totalMistakes,
    );

    return GameResult(
      sessionId: sessionId,
      gameId: gameId,
      gameVersion: gameVersion,
      engineVersion: GameEngineVersion.current.toString(),
      scoringRulesVersion: scoringRulesVersion,
      seed: matrixConfig.seed,
      difficulty: matrixConfig.difficulty,
      completionPhase:
          state.phase.isTerminal ? state.phase : GamePhase.completed,
      finalScore: breakdown.finalScore,
      scoreBreakdown: breakdown,
      totalActiveDuration: totalActiveDuration,
      totalActions: totalActions,
      metrics: {
        'gridSize': matrixConfig.gridSize,
        'correctTilesFound': totalCorrectSelections,
        'mistakeCount': totalMistakes,
        'perfectRounds': perfectRounds,
        'accuracyPercent': (accuracy * 100).round(),
        'isPractice': matrixConfig.isPractice,
      },
      completedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }
}
