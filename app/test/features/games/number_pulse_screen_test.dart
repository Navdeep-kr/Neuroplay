import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/games/presentation/number_pulse/number_pulse_screen.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';

void main() {
  group('NumberPulseScreen Widget Tests', () {
    testWidgets('renders HUD header, sequence cards, and 4 choices',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NumberPulseScreen(
            startImmediately: true,
            seed: 1234,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text('Number Pulse'), findsOneWidget);
      expect(find.text('?'), findsOneWidget); // Missing indicator

      // Option labels 1, 2, 3, 4
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('tapping an option records answer and advances round',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NumberPulseScreen(
            startImmediately: true,
            seed: 1234,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Round 1 of 5'), findsOneWidget);

      // Tap first choice button
      await tester.tap(find.text('1'));
      await tester.pump();

      expect(find.text('Round 2 of 5'), findsOneWidget);
    });

    testWidgets('pause button opens dialog and can resume', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NumberPulseScreen(
            startImmediately: true,
            seed: 1234,
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
