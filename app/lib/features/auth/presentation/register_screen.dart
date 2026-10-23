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

/// Clean, minimal registration screen with validation and onboarding redirection.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

    if (mounted && success) {
      context.go(AppRoutes.onboarding);
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
                    'Begin your training',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Create an account to track cognitive progression across all your devices.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.gapH32,
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
                  AppCard(
                    padding: AppSpacing.pXl,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Alex Rivera',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (v) =>
                                Validators.required(v, 'Full Name'),
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacing.gapH16,
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
                            helperText: 'Minimum 8 characters',
                            textInputAction: TextInputAction.next,
                          ),
                          AppSpacing.gapH16,
                          AppTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hint: '••••••••',
                            obscureText: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSignUp(),
                          ),
                          AppSpacing.gapH24,
                          AppButton(
                            label: 'Create Account',
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: _handleSignUp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,
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
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Sign in'),
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
