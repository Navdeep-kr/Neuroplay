import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/utils/validators.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_text_field.dart';
import 'package:neuroplay/features/auth/presentation/controllers/auth_controller.dart';

/// Clean, minimal authentication login screen with guest bypass support.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (mounted && success) {
      context.go(AppRoutes.home);
    }
  }

  void _handleGuestMode() {
    ref.read(authControllerProvider.notifier).enterGuestMode();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

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
                  // App Icon Header
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tokens.mintContainer,
                        borderRadius: AppRadii.rLg,
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: tokens.onMintContainer,
                        size: 30,
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

                  // Error notification if sign-in fails
                  if (authState.hasError) ...[
                    Container(
                      padding: AppSpacing.pMd,
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(25),
                        borderRadius: AppRadii.rMd,
                        border: Border.all(
                          color: AppColors.error.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          AppSpacing.gapW12,
                          Expanded(
                            child: Text(
                              authState.error.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapH16,
                  ],

                  // Login Form Card
                  AppCard(
                    padding: AppSpacing.pXl,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _emailController,
                            label: 'Email address',
                            hint: 'alex@example.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: Validators.email,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacing.gapH16,
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: '••••••••',
                            obscureText: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: Validators.password,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSignIn(),
                          ),
                          AppSpacing.gapH8,
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.forgotPassword),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          AppSpacing.gapH16,
                          AppButton(
                            label: 'Sign In',
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: _handleSignIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Guest Mode Divider & CTA
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'OR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.navy600,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  AppSpacing.gapH24,

                  AppButton(
                    label: 'Continue as Guest',
                    icon: Icons.person_outline_rounded,
                    variant: AppButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: _handleGuestMode,
                  ),
                  AppSpacing.gapH24,

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text('Create one'),
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
