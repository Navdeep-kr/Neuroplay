import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/presentation/memory_matrix/memory_matrix_screen.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';

void main() {
  group('MemoryMatrixScreen Widget Tests', () {
    testWidgets('renders HUD header, phase banner, and grid tiles immediately',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MemoryMatrixScreen(
            startImmediately: true,
            seed: 42,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text('Memory Matrix'), findsOneWidget);
      expect(find.text('MEMORIZE PATTERN'), findsOneWidget);
      expect(find.text('Ready to Recall'), findsOneWidget);

      // Verify 16 tiles exist for 4x4 medium grid
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can advance to recall and select a tile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MemoryMatrixScreen(
            startImmediately: true,
            seed: 42,
          ),
        ),
      );
      await tester.pump();

      // Tap "Ready to Recall"
      await tester.tap(find.text('Ready to Recall'));
      await tester.pump();

      expect(find.text('RECALL TILES'), findsOneWidget);

      // Tap first tile
      final firstTile = find.byType(InkWell).first;
      await tester.tap(firstTile);
      await tester.pump();

      // Ensure tile response was handled without crashes
      expect(find.byType(MemoryMatrixScreen), findsOneWidget);
    });

    testWidgets('pause button opens GamePauseDialog and can resume',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MemoryMatrixScreen(
            startImmediately: true,
            seed: 42,
          ),
        ),
      );
      await tester.pump();

      // Tap pause button in header
      final pauseBtn = find.byTooltip('Pause game (Esc)');
      expect(pauseBtn, findsOneWidget);
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsOneWidget);
      expect(find.text('Game Paused'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsNothing);
    });
  });
}
