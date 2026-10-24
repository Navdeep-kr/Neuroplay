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
        'renders disclaimers, 7-day trend, domain faculty breakdown, and toggles accessible table',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
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

      // Verify Header & Non-Clinical Disclaimer
      expect(find.text('Cognitive Progress'), findsOneWidget);
      expect(
        find.textContaining('not clinical cognitive assessments'),
        findsOneWidget,
      );

      // Verify 7-Day Trend & Overview
      expect(find.text('7-Day Training Trend'), findsOneWidget);
      expect(find.text('Daily Activity Calendar'), findsOneWidget);
      expect(find.text('Cognitive Faculty Breakdown'), findsOneWidget);

      // Verify faculty names
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Focus & Attention'), findsOneWidget);
      expect(find.text('Cognitive Flexibility'), findsOneWidget);

      // Toggle to accessible table view
      final toggleButton = find.byTooltip('Switch to Accessible Table');
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await pumpTransition(tester);

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Score Index'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets(
        'navigates to Game Performance tab and displays personal bests, charts, and recent sessions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
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

      // Tap "Game Performance" tab
      final gameTab = find.text('Game Performance');
      expect(gameTab, findsOneWidget);
      await tester.tap(gameTab);
      await pumpTransition(tester);

      // Verify game selector chips
      expect(find.text('Select Exercise'), findsOneWidget);
      expect(find.text('Memory Matrix'), findsWidgets);
      expect(find.text('Reflex Forge'), findsWidgets);

      // Select Reflex Forge (supports reaction time)
      await tester.tap(find.widgetWithText(FilterChip, 'Reflex Forge'));
      await pumpTransition(tester);

      // Check Personal Bests & Accuracy History
      expect(find.textContaining('Personal Bests'), findsOneWidget);
      expect(find.text('Accuracy History (%)'), findsOneWidget);
      expect(find.text('Median Response Latency (ms)'), findsOneWidget);
      expect(find.text('Recent Session Log'), findsOneWidget);

      // Toggle Accuracy Chart to Table
      final tableToggle = find.byTooltip('Switch to Accessible Table').first;
      await tester.tap(tableToggle);
      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsWidgets);
      expect(find.text('Score'), findsWidgets);
    });

    testWidgets(
        'navigates to XP & Achievements tab and shows level progression and achievements gallery',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
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

      // Tap "XP & Achievements" tab
      final xpTab = find.text('XP & Achievements');
      expect(xpTab, findsOneWidget);
      await tester.tap(xpTab);
      await pumpTransition(tester);

      // Verify Level progression card
      expect(find.textContaining('Level'), findsWidgets);
      expect(find.textContaining('Total XP Earned'), findsOneWidget);

      // Verify Achievements Gallery
      expect(find.text('Achievements Showcase'), findsOneWidget);
      expect(find.text('Consistency Pioneer'), findsOneWidget);
      expect(find.text('Habit Architect'), findsOneWidget);
      expect(find.text('Flawless Execution'), findsOneWidget);
      expect(find.text('Cognitive Velocity'), findsOneWidget);
    });

    testWidgets('opens explicit streak rules dialog with transparent rules',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
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

      // Tap help button on streak card
      final helpBtn = find.byTooltip('Explicit Streak Rules');
      expect(helpBtn, findsOneWidget);
      await tester.tap(helpBtn);
      await pumpTransition(tester);

      expect(find.text('Transparent Streak Rules'), findsOneWidget);
      expect(
        find.textContaining(
            'Complete at least one training session or workout'),
        findsOneWidget,
      );
      expect(
        find.textContaining('does not use deceptive streak freezes'),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await pumpTransition(tester);
      expect(find.text('Transparent Streak Rules'), findsNothing);
    });
  });
}
