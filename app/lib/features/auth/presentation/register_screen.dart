import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_text_field.dart';

/// Clean, minimal registration screen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
                    'Begin your training',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Create your NEUROPLAY profile to measure and improve cognitive agility.',
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
                          controller: _nameController,
                          label: 'Your name',
                          hint: 'Alex Rivera',
                        ),
                        AppSpacing.gapH16,
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
                          hint: 'At least 8 characters',
                          obscureText: true,
                        ),
                        AppSpacing.gapH24,
                        AppButton(
                          label: 'Create Account',
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
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Sign In'),
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
