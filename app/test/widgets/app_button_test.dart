import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_button.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('renders label and triggers callback on tap', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppButton(
                label: 'Test Button',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppButton(
                label: 'Loading Button',
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsOneWidget);
    });

    testWidgets('does not trigger callback when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppButton(
                label: 'Disabled',
              ),
            ),
          ),
        ),
      );

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('provides accessible semantic label', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppButton(
                label: 'Start',
                semanticLabel: 'Start workout exercise',
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Start workout exercise'), findsOneWidget);
      handle.dispose();
    });
  });
}
