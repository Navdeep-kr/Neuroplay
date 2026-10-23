import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_text_field.dart';

/// Clean, minimal authentication login screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pXl,
            child: MaxWidthContainer(
              maxWidth: 440,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Sign in to access your customized cognitive routine.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.gapH32,
                  AppCard(
                    padding: AppSpacing.pXl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _emailController,
                          label: 'Email address',
                          hint: 'alex@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        AppSpacing.gapH16,
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          obscureText: true,
                        ),
                        AppSpacing.gapH24,
                        AppButton(
                          label: 'Sign In',
                          isFullWidth: true,
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
