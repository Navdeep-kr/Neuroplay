import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/word_weaver/word_weaver_screen.dart';

void main() {
  group('WordWeaverScreen Widget Tests', () {
    testWidgets('renders anchor word, category badge, and 4 choices',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WordWeaverScreen(
            startImmediately: true,
            seed: 5555,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text('Word Weaver'), findsOneWidget);
      expect(
        find.text('Select the associated term from the same domain'),
        findsOneWidget,
      );

      // Verify choice key badges 1, 2, 3, 4
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('selecting word association advances to next round',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WordWeaverScreen(
            startImmediately: true,
            seed: 5555,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Round 1 of 5'), findsOneWidget);

      // Tap first choice
      await tester.tap(find.text('1'));
      await tester.pump();

      expect(find.text('Round 2 of 5'), findsOneWidget);
    });

    testWidgets('pause dialog functions properly and resumes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WordWeaverScreen(
            startImmediately: true,
            seed: 5555,
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

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePauseDialog), findsNothing);
    });
  });
}
