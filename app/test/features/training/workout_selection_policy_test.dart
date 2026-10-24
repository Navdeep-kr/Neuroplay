import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';
import 'package:neuroplay/features/training/domain/workout_generator.dart';
import 'package:neuroplay/features/training/domain/workout_selection_policy.dart';

void main() {
  group('WorkoutSelectionPolicy Unit Tests', () {
    final catalog = WorkoutGenerator.catalog;
    final testDate = DateTime(2026, 10, 24);

    test('algorithm version is explicitly 1.0.0', () {
      expect(WorkoutSelectionPolicy.algorithmVersion, equals('1.0.0'));
    });

    test('new or guest user receives sensible tripartite introductory baseline',
        () {
      final assignments = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
      );

      expect(assignments.length, equals(3));
      // All 3 selected games are distinct
      final ids = assignments.map((a) => a.game.id).toSet();
      expect(ids.length, equals(3));

      // Each assignment has an explainable reason and assigned difficulty
      for (final assignment in assignments) {
        expect(assignment.selectionReason.isNotEmpty, isTrue);
        expect(assignment.assignedDifficulty, equals(GameDifficulty.easy));
      }

      // First assignment explains introductory baseline
      expect(assignments[0].selectionReason, contains('Introductory Baseline'));
    });

    test('deterministic reproducibility given identical seed and inputs', () {
      final assignmentsA = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
      );
      final assignmentsB = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
      );

      expect(assignmentsA.length, equals(assignmentsB.length));
      for (var i = 0; i < assignmentsA.length; i++) {
        expect(assignmentsA[i].game.id, equals(assignmentsB[i].game.id));
        expect(
          assignmentsA[i].assignedDifficulty,
          equals(assignmentsB[i].assignedDifficulty),
        );
        expect(
          assignmentsA[i].selectionReason,
          equals(assignmentsB[i].selectionReason),
        );
      }
    });

    test('prioritizes user preferred domains when provided', () {
      final assignments = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
        preferredDomains: {CognitiveDomain.problemSolving},
        skillProfiles: {
          'logic-labyrinth': SkillEstimate(
            gameId: 'logic-labyrinth',
            continuousRating: 60,
            recommendedDifficulty: GameDifficulty.medium,
            sampleCount: 5,
          ),
        },
      );

      expect(
        assignments.first.game.domain,
        equals(CognitiveDomain.problemSolving),
      );
      expect(assignments.first.selectionReason, contains('User Preference'));
    });

    test('targets lowest rating domain for growth when skills exist', () {
      // Memory is high, Problem Solving is low
      final skills = {
        'memory-matrix': SkillEstimate(
          gameId: 'memory-matrix',
          continuousRating: 85,
          recommendedDifficulty: GameDifficulty.hard,
          sampleCount: 10,
        ),
        'logic-labyrinth': SkillEstimate(
          gameId: 'logic-labyrinth',
          continuousRating: 30,
          recommendedDifficulty: GameDifficulty.easy,
          sampleCount: 8,
        ),
      };

      final assignments = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
        skillProfiles: skills,
      );

      expect(
        assignments.first.game.domain,
        equals(CognitiveDomain.problemSolving),
      );
      expect(assignments.first.selectionReason, contains('Targeted Growth'));
      expect(assignments.first.assignedDifficulty, equals(GameDifficulty.easy));
    });

    test(
        'anti-repetition policy swaps 3rd game if combination repeated recently',
        () {
      // Baseline selection without recent history
      final base = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
      );
      final candidateCombo = base.map((a) => a.game.id).toSet();

      // Now pass the candidateCombo in recentCombinations
      final adjusted = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: catalog,
        date: testDate,
        recentCombinations: [candidateCombo],
      );

      final newCombo = adjusted.map((a) => a.game.id).toSet();

      // Combination should have rotated out at least one game to avoid duplicate
      expect(newCombo, isNot(equals(candidateCombo)));
      expect(adjusted[2].selectionReason, contains('Variety Rotation'));
    });

    test('handles small or empty catalog safely', () {
      final emptyResult = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: const [],
        date: testDate,
      );
      expect(emptyResult, isEmpty);

      final smallCatalog = [catalog.first, catalog[1]];
      final smallResult = WorkoutSelectionPolicy.selectWorkoutGames(
        catalog: smallCatalog,
        date: testDate,
      );
      expect(smallResult.length, equals(2));
    });
  });
}
