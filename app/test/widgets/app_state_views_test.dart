import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_state_views.dart';

void main() {
  group('AppStateViews Widget Tests', () {
    testWidgets('AppLoadingView renders message and indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppLoadingView(message: 'Loading neural patterns...'),
          ),
        ),
      );

      expect(find.text('Loading neural patterns...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppEmptyView renders title, description, and calls action',
        (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppEmptyView(
              title: 'No Workouts',
              description: 'You have no scheduled workouts today.',
              actionLabel: 'Refresh',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Workouts'), findsOneWidget);
      expect(
        find.text('You have no scheduled workouts today.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorView renders error message and triggers retry',
        (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppErrorView(
              title: 'Sync Failed',
              message: 'Check your internet connection.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Sync Failed'), findsOneWidget);
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('AppOfflineBanner displays offline warning', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppOfflineBanner(),
          ),
        ),
      );

      expect(
        find.text(
          'You are currently offline. Local progress will sync when reconnected.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });
  });
}
