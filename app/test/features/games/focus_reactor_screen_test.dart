import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/presentation/focus_reactor/focus_reactor_screen.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';

void main() {
  group('FocusReactorScreen Widget Tests', () {
    testWidgets('renders seek target banner, item slots, and absent button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FocusReactorScreen(
            startImmediately: true,
            seed: 777,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text('Focus Reactor'), findsOneWidget);
      expect(find.text('SEEK TARGET'), findsOneWidget);
      expect(find.text('Target Absent [Space]'), findsOneWidget);

      // Verify slot badges 1, 2, 3, 4
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('tapping slot or absent button advances round', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FocusReactorScreen(
            startImmediately: true,
            seed: 777,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Round 1 of 8'), findsOneWidget);

      // Tap slot 1
      await tester.tap(find.text('1'));
      await tester.pump();

      expect(find.text('Round 2 of 8'), findsOneWidget);

      // Tap Target Absent button
      await tester.tap(find.text('Target Absent [Space]'));
      await tester.pump();

      expect(find.text('Round 3 of 8'), findsOneWidget);
    });

    testWidgets('pause button opens pause dialog and resumes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FocusReactorScreen(
            startImmediately: true,
            seed: 777,
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
