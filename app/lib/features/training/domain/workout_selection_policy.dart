import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Pure domain selection policy for generating daily 3-game workout playlists.
///
/// Features:
/// 1. Deterministic and explainable: output is completely reproducible given date,
///    catalog, training history, and algorithm version.
/// 2. Bounded adaptive difficulty: uses game-specific skill estimates.
/// 3. Anti-repetition: tracks recent combination signatures and rotates content.
/// 4. Domain balancing: ensures multi-domain cognitive stimulation.
/// 5. Sensible defaults: graceful fallback for new users and guest players.
abstract final class WorkoutSelectionPolicy {
  /// Current active algorithm version.
  static const String algorithmVersion = '1.0.0';

  /// Selects 3 balanced games for the given [date], catalog, and user history.
  static List<WorkoutGameAssignment> selectWorkoutGames({
    required List<CognitiveGame> catalog,
    required DateTime date,
    Map<String, SkillEstimate> skillProfiles = const {},
    List<Set<String>> recentCombinations = const [],
    Set<CognitiveDomain> preferredDomains = const {},
    Set<String> completedGameIds = const {},
  }) {
    if (catalog.isEmpty) return const [];
    if (catalog.length < 3) {
      // Degenerate fallback if catalog has fewer than 3 games
      return catalog
          .map(
            (g) => WorkoutGameAssignment(
              game: g,
              assignedDifficulty: skillProfiles[g.id]?.recommendedDifficulty ??
                  GameDifficulty.medium,
              selectionReason: 'Catalog baseline exercise',
              isCompleted: completedGameIds.contains(g.id),
            ),
          )
          .toList();
    }

    final daySeed = date.year * 10000 + date.month * 100 + date.day;
    final isNewOrGuest = skillProfiles.isEmpty;

    // --- Slot 1: Primary Focus Game ---
    final (game1, reason1) = _selectPrimaryGame(
      catalog: catalog,
      daySeed: daySeed,
      skillProfiles: skillProfiles,
      preferredDomains: preferredDomains,
      isNewUser: isNewOrGuest,
    );

    // --- Slot 2: Complementary Domain Game ---
    final (game2, reason2) = _selectComplementaryGame(
      catalog: catalog,
      daySeed: daySeed,
      primaryGame: game1,
      skillProfiles: skillProfiles,
      isNewUser: isNewOrGuest,
    );

    // --- Slot 3: Variety & Anti-Repetition Rotation Game ---
    final (game3, reason3) = _selectVarietyGame(
      catalog: catalog,
      daySeed: daySeed,
      selectedGames: [game1, game2],
      recentCombinations: recentCombinations,
      skillProfiles: skillProfiles,
      isNewUser: isNewOrGuest,
    );

    final selected = [
      (game: game1, reason: reason1),
      (game: game2, reason: reason2),
      (game: game3, reason: reason3),
    ];

    return selected.map((item) {
      final skill = skillProfiles[item.game.id];
      final difficulty = skill?.recommendedDifficulty ??
          (isNewOrGuest ? GameDifficulty.easy : GameDifficulty.medium);
      return WorkoutGameAssignment(
        game: item.game,
        assignedDifficulty: difficulty,
        selectionReason: item.reason,
        isCompleted: completedGameIds.contains(item.game.id),
      );
    }).toList();
  }

  /// Selects the primary focus game based on domain preferences or growth opportunity.
  static (CognitiveGame, String) _selectPrimaryGame({
    required List<CognitiveGame> catalog,
    required int daySeed,
    required Map<String, SkillEstimate> skillProfiles,
    required Set<CognitiveDomain> preferredDomains,
    required bool isNewUser,
  }) {
    if (isNewUser) {
      // Rotate introductory baseline across Memory, Flexibility, Attention
      final baseDomains = [
        CognitiveDomain.memory,
        CognitiveDomain.flexibility,
        CognitiveDomain.attention,
      ];
      final targetDomain = baseDomains[daySeed % baseDomains.length];
      final candidates =
          catalog.where((g) => g.domain == targetDomain).toList();
      final game = candidates.isNotEmpty
          ? candidates[(daySeed ~/ 3) % candidates.length]
          : catalog[daySeed % catalog.length];
      return (
        game,
        'Introductory Baseline: Calibration routine for ${game.domain.label}.',
      );
    }

    // If preferred domains specified, prioritize them
    if (preferredDomains.isNotEmpty) {
      for (final domain in preferredDomains) {
        final matches = catalog.where((g) => g.domain == domain).toList();
        if (matches.isNotEmpty) {
          final game = matches[daySeed % matches.length];
          return (
            game,
            'User Preference: Selected to match your training priority in ${domain.label}.',
          );
        }
      }
    }

    // Otherwise find domain with lowest average rating (greatest growth opportunity)
    final domainAverages = <CognitiveDomain, double>{};
    for (final game in catalog) {
      final skill = skillProfiles[game.id];
      if (skill != null) {
        domainAverages.putIfAbsent(game.domain, () => 0.0);
        domainAverages[game.domain] =
            (domainAverages[game.domain]! + skill.continuousRating) / 2.0;
      }
    }

    if (domainAverages.isNotEmpty) {
      var lowestDomain = domainAverages.keys.first;
      var lowestRating = domainAverages.values.first;
      for (final entry in domainAverages.entries) {
        if (entry.value < lowestRating) {
          lowestRating = entry.value;
          lowestDomain = entry.key;
        }
      }

      final candidates =
          catalog.where((g) => g.domain == lowestDomain).toList();
      if (candidates.isNotEmpty) {
        final game = candidates[daySeed % candidates.length];
        return (
          game,
          'Targeted Growth: Strengthens ${lowestDomain.label} (current skill index: ${lowestRating.toStringAsFixed(0)}).',
        );
      }
    }

    final fallbackGame = catalog[daySeed % catalog.length];
    return (
      fallbackGame,
      'Core Training: Regular focus session for ${fallbackGame.domain.label}.',
    );
  }

  /// Selects a second game from a complementary domain.
  static (CognitiveGame, String) _selectComplementaryGame({
    required List<CognitiveGame> catalog,
    required int daySeed,
    required CognitiveGame primaryGame,
    required Map<String, SkillEstimate> skillProfiles,
    required bool isNewUser,
  }) {
    final complementaryCandidates =
        catalog.where((g) => g.domain != primaryGame.domain).toList();

    if (complementaryCandidates.isEmpty) {
      // Catalog has only one domain
      final remaining = catalog.where((g) => g.id != primaryGame.id).toList();
      final game = remaining.isNotEmpty ? remaining.first : primaryGame;
      return (game, 'Sequential Exercise: Reinforces cognitive pacing.');
    }

    final game =
        complementaryCandidates[(daySeed + 1) % complementaryCandidates.length];
    final reason = isNewUser
        ? 'Cross-Domain Exposure: Engages ${game.domain.label} alongside ${primaryGame.domain.label}.'
        : 'Cross-Domain Balance: Stimulates ${game.domain.label} to complement ${primaryGame.domain.label}.';
    return (game, reason);
  }

  /// Selects a third game with anti-repetition protection.
  static (CognitiveGame, String) _selectVarietyGame({
    required List<CognitiveGame> catalog,
    required int daySeed,
    required List<CognitiveGame> selectedGames,
    required List<Set<String>> recentCombinations,
    required Map<String, SkillEstimate> skillProfiles,
    required bool isNewUser,
  }) {
    final selectedIds = selectedGames.map((g) => g.id).toSet();
    final selectedDomains = selectedGames.map((g) => g.domain).toSet();

    // Prefer a domain that has not yet been selected
    var candidates = catalog
        .where(
          (g) =>
              !selectedIds.contains(g.id) &&
              !selectedDomains.contains(g.domain),
        )
        .toList();

    if (candidates.isEmpty) {
      candidates = catalog.where((g) => !selectedIds.contains(g.id)).toList();
    }

    if (candidates.isEmpty) {
      return (selectedGames.first, 'Workout completion exercise.');
    }

    var chosen = candidates[(daySeed + 2) % candidates.length];

    // Anti-repetition check: does {game1, game2, chosen} match any recent combination?
    final candidateCombo = {
      selectedGames[0].id,
      selectedGames[1].id,
      chosen.id,
    };
    final hasRecentMatch = recentCombinations.any(
      (combo) => combo.length == 3 && combo.containsAll(candidateCombo),
    );

    var wasSwapped = false;
    if (hasRecentMatch && candidates.length > 1) {
      // Pick alternative candidate with least recent occurrences
      for (final alt in candidates) {
        if (alt.id != chosen.id) {
          final altCombo = {
            selectedGames[0].id,
            selectedGames[1].id,
            alt.id,
          };
          final altMatches = recentCombinations
              .any((c) => c.length == 3 && c.containsAll(altCombo));
          if (!altMatches) {
            chosen = alt;
            wasSwapped = true;
            break;
          }
        }
      }
    }

    final reason = wasSwapped
        ? 'Variety Rotation: Dynamically rotated to prevent recent playlist repetition.'
        : 'Cognitive Agility: Adds ${chosen.domain.label} to broaden mental activation.';

    return (chosen, reason);
  }
}
