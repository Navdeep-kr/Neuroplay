import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_card.dart';

void main() {
  group('AppCard Widget Tests', () {
    testWidgets('renders child content properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppCard(
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppCard(
                onTap: () => tapped = true,
                child: const Text('Interactive Card'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Interactive Card'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
