import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/presentation/logic_labyrinth/logic_labyrinth_screen.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';

void main() {
  group('LogicLabyrinthScreen Widget Tests', () {
    testWidgets('renders HUD header, badges, grid, and D-pad controls',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LogicLabyrinthScreen(
            startImmediately: true,
            seed: 42,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text('Logic Labyrinth'), findsOneWidget);
      expect(find.textContaining('Steps:'), findsOneWidget);
      expect(find.textContaining('Par:'), findsOneWidget);

      // Verify D-pad navigation buttons and reset
      expect(find.byTooltip('Move Up (W or Arrow Up)'), findsOneWidget);
      expect(find.byTooltip('Move Down (S or Arrow Down)'), findsOneWidget);
      expect(find.byTooltip('Move Left (A or Arrow Left)'), findsOneWidget);
      expect(find.byTooltip('Move Right (D or Arrow Right)'), findsOneWidget);
      expect(find.byTooltip('Reset to maze start (R)'), findsOneWidget);
    });

    testWidgets('tapping D-pad navigation buttons dispatches moves safely',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LogicLabyrinthScreen(
            startImmediately: true,
            seed: 42,
          ),
        ),
      );
      await tester.pump();

      // Tap move right
      await tester.tap(find.byTooltip('Move Right (D or Arrow Right)'));
      await tester.pump();

      // Ensure D-pad is scrolled into view and tap move down
      final moveDownBtn = find.byTooltip('Move Down (S or Arrow Down)');
      await tester.ensureVisible(moveDownBtn);
      await tester.pumpAndSettle();
      await tester.tap(moveDownBtn);
      await tester.pump();

      // Tap reset
      await tester.tap(find.byTooltip('Reset to maze start (R)'));
      await tester.pump();

      expect(find.byType(LogicLabyrinthScreen), findsOneWidget);
    });

    testWidgets('pause dialog opens and resumes successfully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LogicLabyrinthScreen(
            startImmediately: true,
            seed: 42,
          ),
        ),
      );
      await tester.pump();

      final pauseBtn = find.byTooltip('Pause game (Esc)');
      expect(pauseBtn, findsOneWidget);
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsOneWidget);
      expect(find.text('Game Paused'), findsOneWidget);

      // Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsNothing);
    });
  });
}
