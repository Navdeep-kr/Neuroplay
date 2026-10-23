import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/progress/presentation/progress_screen.dart';

void main() {
  group('ProgressScreen Widget Tests', () {
    Future<void> pumpTransition(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets(
        'renders 7-day trend, domain faculty breakdown, and toggles accessible table',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProgressScreen(),
          ),
        ),
      );

      await pumpTransition(tester);

      expect(find.text('Cognitive Progress'), findsOneWidget);
      expect(find.text('7-Day Training Trend'), findsOneWidget);
      expect(find.text('Cognitive Faculty Breakdown'), findsOneWidget);

      // Verify domain faculty names are shown
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Focus & Attention'), findsOneWidget);
      expect(find.text('Cognitive Flexibility'), findsOneWidget);

      // Toggle to accessible table view
      final toggleButton = find.byTooltip('Switch to Accessible Table');
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Score Index'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });
  });
}
