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

/// Password recovery screen allowing users to request a magic reset link.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (mounted && success) {
      setState(() => _submitted = true);
    }
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
            padding: AppSpacing.pLg,
            child: MaxWidthContainer(
              maxWidth: 440,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Sign In'),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Branding Header
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: tokens.mintContainer,
                        borderRadius: AppRadii.rLg,
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 32,
                        color: tokens.onMintContainer,
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,

                  Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Enter your registered email address and we will send you a secure link to reset your credentials.',
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

                  if (_submitted) ...[
                    AppCard(
                      backgroundColor: tokens.mintContainer.withAlpha(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mark_email_read_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          AppSpacing.gapH12,
                          Text(
                            'Check Your Inbox',
                            style: theme.textTheme.titleMedium,
                          ),
                          AppSpacing.gapH8,
                          Text(
                            'If an account exists for ${_emailController.text.trim()}, you will receive password recovery instructions shortly.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          AppSpacing.gapH24,
                          AppButton(
                            label: 'Return to Sign In',
                            variant: AppButtonVariant.secondary,
                            isFullWidth: true,
                            onPressed: () => context.go(AppRoutes.login),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleReset(),
                            ),
                            AppSpacing.gapH24,
                            AppButton(
                              label: 'Send Recovery Email',
                              isFullWidth: true,
                              isLoading: isLoading,
                              onPressed: _handleReset,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
