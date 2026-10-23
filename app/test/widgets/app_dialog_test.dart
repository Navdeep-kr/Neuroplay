import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_dialog.dart';

void main() {
  group('AppDialog Widget Tests', () {
    testWidgets('shows confirmation dialog and handles confirm',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showConfirmation(
                    context: context,
                    title: 'Confirm Reset',
                    message: 'Reset current session scores?',
                    confirmLabel: 'Yes, Reset',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Reset'), findsOneWidget);
      expect(find.text('Reset current session scores?'), findsOneWidget);
      expect(find.text('Yes, Reset'), findsOneWidget);

      await tester.tap(find.text('Yes, Reset'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('handles cancel button', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showConfirmation(
                    context: context,
                    title: 'Delete Item',
                    message: 'Are you sure?',
                    cancelLabel: 'Dismiss',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
