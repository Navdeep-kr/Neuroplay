import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/presentation/reflex_forge/reflex_forge_screen.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';

void main() {
  group('ReflexForgeScreen Widget Tests', () {
    testWidgets('renders active rule header, stimulus card, and 3 options',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReflexForgeScreen(
            startImmediately: true,
            seed: 1234,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text('Reflex Forge'), findsOneWidget);
      expect(find.textContaining('ACTIVE RULE:'), findsOneWidget);
      expect(find.text('TARGET'), findsOneWidget);

      // Verify choice option badges 1, 2, 3
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('selecting an option updates the round', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReflexForgeScreen(
            startImmediately: true,
            seed: 1234,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Round 1 of 8'), findsOneWidget);

      // Tap Option 1
      await tester.tap(find.text('1'));
      await tester.pump();

      // Successfully processed and advanced to Round 2
      expect(find.text('Round 2 of 8'), findsOneWidget);
    });

    testWidgets('pause dialog can be opened and closed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReflexForgeScreen(
            startImmediately: true,
            seed: 1234,
          ),
        ),
      );
      await tester.pump();

      final pauseBtn = find.byTooltip('Pause game (Esc)');
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsNothing);
    });
  });
}
