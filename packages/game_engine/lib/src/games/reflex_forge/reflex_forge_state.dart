import 'package:equatable/equatable.dart';
import 'package:game_engine/src/games/reflex_forge/reflex_forge_models.dart';

/// Trial snapshot for Reflex Forge.
final class ReflexForgeTrialState extends Equatable {
  const ReflexForgeTrialState({
    required this.rule,
    required this.stimulus,
    required this.options,
    required this.correctIndex,
    this.ruleShiftedThisRound = false,
    this.lastSelectedCorrect,
    this.lastReactionTimeMs,
  });

  final ReflexRule rule;
  final ReflexSymbol stimulus;
  final List<ReflexSymbol> options;
  final int correctIndex;
  final bool ruleShiftedThisRound;
  final bool? lastSelectedCorrect;
  final int? lastReactionTimeMs;

  Map<String, dynamic> toJson() => {
        'rule': rule.name,
        'stimulus': stimulus.toJson(),
        'options': options.map((o) => o.toJson()).toList(),
        'correctIndex': correctIndex,
        'ruleShiftedThisRound': ruleShiftedThisRound,
        if (lastSelectedCorrect != null)
          'lastSelectedCorrect': lastSelectedCorrect,
        if (lastReactionTimeMs != null)
          'lastReactionTimeMs': lastReactionTimeMs,
      };

  @override
  List<Object?> get props => [
        rule,
        stimulus,
        options,
        correctIndex,
        ruleShiftedThisRound,
        lastSelectedCorrect,
        lastReactionTimeMs,
      ];
}
