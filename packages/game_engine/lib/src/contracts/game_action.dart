import 'package:equatable/equatable.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Base contract for all player inputs and lifecycle events dispatched to an engine.
@immutable
abstract class GameAction extends Equatable {
  const GameAction({
    required this.type,
    required this.timestamp,
    this.payload = const {},
  });

  /// Action discriminator (e.g., 'start', 'tap', 'select').
  final String type;

  /// Elapsed active session timestamp when the action was taken.
  final Duration timestamp;

  /// Optional arbitrary payload parameters.
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'type': type,
        'timestampMs': timestamp.inMilliseconds,
        'payload': payload,
      };

  @override
  List<Object?> get props => [type, timestamp, payload];

  @override
  String toString() => '$runtimeType($type @ ${timestamp.inMilliseconds}ms)';
}

/// Dispatched to commence gameplay after countdown or readiness.
final class StartGameAction extends GameAction {
  const StartGameAction({required super.timestamp}) : super(type: 'start');
}

/// Dispatched when the player or application pauses gameplay.
final class PauseGameAction extends GameAction {
  PauseGameAction({
    required super.timestamp,
    String? reason,
  }) : super(
          type: 'pause',
          payload: reason != null ? {'reason': reason} : const {},
        );
}

/// Dispatched when returning from a paused state.
final class ResumeGameAction extends GameAction {
  const ResumeGameAction({required super.timestamp}) : super(type: 'resume');
}

/// Dispatched when a session is aborted early.
final class AbortGameAction extends GameAction {
  AbortGameAction({
    required super.timestamp,
    String? reason,
  }) : super(
          type: 'abort',
          payload: reason != null ? {'reason': reason} : const {},
        );
}

/// Generic stimulus response action.
final class RespondAction extends GameAction {
  RespondAction({
    required super.timestamp,
    required this.responseValue,
    required this.targetId,
  }) : super(
          type: 'respond',
          payload: {
            'responseValue': responseValue,
            'targetId': targetId,
          },
        );

  factory RespondAction.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>?;
    if (payload == null) {
      throw const GameValidationException('Missing payload in RespondAction');
    }
    return RespondAction(
      timestamp: Duration(milliseconds: json['timestampMs'] as int),
      responseValue: payload['responseValue'],
      targetId: payload['targetId'] as String,
    );
  }

  final Object? responseValue;
  final String targetId;

  @override
  List<Object?> get props => [type, timestamp, responseValue, targetId];
}
