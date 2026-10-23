import 'package:equatable/equatable.dart';
import 'package:game_engine/src/games/focus_reactor/focus_reactor_models.dart';

/// Trial snapshot for Focus Reactor.
final class FocusReactorTrialState extends Equatable {
  const FocusReactorTrialState({
    required this.targetItem,
    required this.displayedItems,
    required this.targetSlotIndex,
    this.lastSelectionCorrect,
    this.lastReactionTimeMs,
  });

  /// The item the player is seeking.
  final FocusItem targetItem;

  /// The array of items shown in this trial.
  final List<FocusItem> displayedItems;

  /// Index of the slot containing [targetItem], or null if target is absent.
  final int? targetSlotIndex;

  /// Whether target was present in this trial.
  bool get isTargetPresent => targetSlotIndex != null;

  final bool? lastSelectionCorrect;
  final int? lastReactionTimeMs;

  Map<String, dynamic> toJson() => {
        'targetItem': targetItem.toJson(),
        'displayedItems': displayedItems.map((i) => i.toJson()).toList(),
        'targetSlotIndex': targetSlotIndex,
        'isTargetPresent': isTargetPresent,
        if (lastSelectionCorrect != null)
          'lastSelectionCorrect': lastSelectionCorrect,
        if (lastReactionTimeMs != null)
          'lastReactionTimeMs': lastReactionTimeMs,
      };

  @override
  List<Object?> get props => [
        targetItem,
        displayedItems,
        targetSlotIndex,
        lastSelectionCorrect,
        lastReactionTimeMs,
      ];
}
