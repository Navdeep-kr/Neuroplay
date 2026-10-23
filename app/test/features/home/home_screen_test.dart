import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    Future<void> pumpTransition(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets('renders greeting, streak, workout hero, and pulse metrics',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await pumpTransition(tester);

      expect(find.text('Welcome, Alex'), findsOneWidget);
      expect(find.textContaining('Day Streak'), findsOneWidget);
      expect(find.text("Start Today's Workout"), findsOneWidget);
      expect(find.text('Training Pulse'), findsOneWidget);
      expect(find.text('Brain Index'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
      expect(find.text('Best Faculty'), findsOneWidget);
      expect(find.text('Scheduled Modules'), findsOneWidget);
    });

    testWidgets('tapping "Start Today\'s Workout" displays modal bottom sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await pumpTransition(tester);

      await tester.tap(find.text("Start Today's Workout"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Today's Guided Routine"), findsOneWidget);
      expect(find.text('Start Guided Daily Routine'), findsOneWidget);
    });
  });
}
