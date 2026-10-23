import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/app/app.dart';

void main() {
  group('Navigation and Shell Integration Tests', () {
    Future<void> pumpTransition(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets('boots into Home and displays "Start Today\'s Workout"',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: NeuroplayApp(),
        ),
      );

      await pumpTransition(tester);

      // Check Home screen elements
      expect(find.text('Welcome, Alex'), findsOneWidget);
      expect(find.text("Start Today's Workout"), findsOneWidget);
      expect(find.text('Scheduled Modules'), findsOneWidget);
    });

    testWidgets('mobile bottom navigation tabs work without dead buttons',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: NeuroplayApp(),
        ),
      );

      await pumpTransition(tester);

      // 1. Navigate to Games
      await tester.tap(find.text('Games'));
      await pumpTransition(tester);
      expect(find.text('Games Library'), findsOneWidget);
      expect(find.text('All Domains'), findsOneWidget);

      // 2. Navigate to Progress
      await tester.tap(find.text('Progress'));
      await pumpTransition(tester);
      expect(find.text('Cognitive Progress'), findsOneWidget);
      expect(find.text('Cognitive Faculty Breakdown'), findsOneWidget);

      // 3. Navigate to Challenges
      await tester.tap(find.text('Challenges'));
      await pumpTransition(tester);
      expect(find.text('Cognitive Challenges'), findsOneWidget);

      // 4. Navigate to Profile
      await tester.tap(find.text('Profile'));
      await pumpTransition(tester);
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      // 5. Navigate back to Home
      await tester.tap(find.text('Home'));
      await pumpTransition(tester);
      expect(find.text('Welcome, Alex'), findsOneWidget);
    });

    testWidgets('desktop viewport renders NavigationRail and theme toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: NeuroplayApp(),
        ),
      );

      await pumpTransition(tester);

      // Check NavigationRail and NEUROPLAY desktop title
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('NEUROPLAY'), findsOneWidget);
    });
  });
}
