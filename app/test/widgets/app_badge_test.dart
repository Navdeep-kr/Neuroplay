import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';

void main() {
  group('AppBadge Widget Tests', () {
    testWidgets('renders badge text and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppBadge(
                label: 'Memory',
                icon: Icons.grid_view_rounded,
                variant: AppBadgeVariant.mint,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Memory'), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });
  });
}
