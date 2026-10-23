import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// State of an in-progress guided daily workout.
class WorkoutSessionState {
  const WorkoutSessionState({
    required this.workout,
    this.currentGameIndex = 0,
    this.completedResults = const [],
    this.isCompleted = false,
  });

  final DailyWorkout workout;
  final int currentGameIndex;
  final List<GameResult> completedResults;
  final bool isCompleted;

  CognitiveGame? get currentGame => currentGameIndex < workout.games.length
      ? workout.games[currentGameIndex]
      : null;

  CognitiveGame? get nextGame => (currentGameIndex + 1) < workout.games.length
      ? workout.games[currentGameIndex + 1]
      : null;

  int get totalGames => workout.games.length;
  int get currentStep => currentGameIndex + 1;
  double get progressRatio => totalGames > 0
      ? (completedResults.length / totalGames).clamp(0.0, 1.0)
      : 0.0;
}

/// Controller managing sequential progression through the daily workout playlist.
class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState?> {
  WorkoutSessionNotifier(this._ref) : super(null);

  final Ref _ref;

  /// Begins a new guided daily workout session.
  void startWorkout(DailyWorkout workout) {
    state = WorkoutSessionState(workout: workout);
  }

  /// Records a completed game result within the workout playlist.
  Future<void> recordGameResult(GameResult result) async {
    final current = state;
    if (current == null) return;

    final repo = _ref.read(trainingRepositoryProvider);
    await repo.recordGameSession(result, workoutId: current.workout.id);

    final updatedResults = [...current.completedResults, result];
    final isDone = updatedResults.length >= current.totalGames;

    if (isDone) {
      await repo.markWorkoutCompleted(current.workout.id);
      _ref
        ..invalidate(todayWorkoutProvider)
        ..invalidate(userStreakProvider)
        ..invalidate(overallStatsProvider);
    }

    state = WorkoutSessionState(
      workout: current.workout,
      currentGameIndex: current.currentGameIndex,
      completedResults: updatedResults,
      isCompleted: isDone,
    );
  }

  /// Steps forward to the next game in the sequence.
  CognitiveGame? advanceToNextGame() {
    final current = state;
    if (current == null) return null;

    final nextIndex = current.currentGameIndex + 1;
    if (nextIndex < current.totalGames) {
      state = WorkoutSessionState(
        workout: current.workout,
        currentGameIndex: nextIndex,
        completedResults: current.completedResults,
      );
      return state!.currentGame;
    }
    return null;
  }

  /// Exits or resets the active workout flow.
  void endWorkout() {
    state = null;
  }
}

/// Global provider for active guided workout session.
final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?>(
  WorkoutSessionNotifier.new,
);
