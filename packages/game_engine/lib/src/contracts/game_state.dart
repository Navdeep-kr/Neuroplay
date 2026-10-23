import 'package:equatable/equatable.dart';
import 'package:game_engine/src/contracts/game_phase.dart';
import 'package:meta/meta.dart';

/// Immutable snapshot of a game session at an exact point in time.
@immutable
class GameState extends Equatable {
  const GameState({
    required this.phase,
    required this.currentRound,
    required this.totalRounds,
    required this.score,
    required this.elapsedActiveTime,
    this.streak = 0,
    this.customData = const {},
  })  : assert(currentRound >= 0, 'currentRound must be non-negative'),
        assert(totalRounds > 0, 'totalRounds must be positive'),
        assert(score >= 0, 'score must be non-negative'),
        assert(streak >= 0, 'streak must be non-negative');

  /// Current game lifecycle phase.
  final GamePhase phase;

  /// Current round number (1-based, 0 before round 1).
  final int currentRound;

  /// Total rounds configured for this session.
  final int totalRounds;

  /// Cumulative score accumulated so far.
  final int score;

  /// Active monotonic time spent playing.
  final Duration elapsedActiveTime;

  /// Current consecutive correct answers / stimulus streak.
  final int streak;

  /// Game-specific state parameters.
  final Map<String, dynamic> customData;

  /// Whether the session has arrived at a completion phase.
  bool get isCompleted => phase == GamePhase.completed;

  /// Whether the session was aborted.
  bool get isAborted => phase == GamePhase.aborted;

  /// Whether this state is in a terminal phase.
  bool get isTerminal => phase.isTerminal;

  /// Progress ratio from 0.0 to 1.0 based on completed rounds.
  double get progress {
    if (totalRounds == 0) return 0.0;
    if (isCompleted) return 1.0;
    return (currentRound - 1).clamp(0, totalRounds) / totalRounds;
  }

  GameState copyWith({
    GamePhase? phase,
    int? currentRound,
    int? totalRounds,
    int? score,
    Duration? elapsedActiveTime,
    int? streak,
    Map<String, dynamic>? customData,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      score: score ?? this.score,
      elapsedActiveTime: elapsedActiveTime ?? this.elapsedActiveTime,
      streak: streak ?? this.streak,
      customData: customData ?? this.customData,
    );
  }

  Map<String, dynamic> toJson() => {
        'phase': phase.toJson(),
        'currentRound': currentRound,
        'totalRounds': totalRounds,
        'score': score,
        'elapsedActiveTimeMs': elapsedActiveTime.inMilliseconds,
        'streak': streak,
        'customData': customData,
      };

  @override
  List<Object?> get props => [
        phase,
        currentRound,
        totalRounds,
        score,
        elapsedActiveTime,
        streak,
        customData,
      ];
}
