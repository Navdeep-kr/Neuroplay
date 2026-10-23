import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/app/theme.dart';
import 'package:neuroplay/features/auth/presentation/forgot_password_screen.dart';

void main() {
  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('renders reset password input and back button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ForgotPasswordScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Send Recovery Email'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('validates email before dispatching reset request',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ForgotPasswordScreen(),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Send Recovery Email'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });
  });
}
