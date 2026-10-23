import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_button.dart';

/// Calm, accessible loading view with an optional descriptive message.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Semantics(
        label: message,
        liveRegion: true,
        child: Padding(
          padding: AppSpacing.pXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.navy600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly, minimal empty state view.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    required this.description,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.pXl,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.subtleBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.navy600,
                ),
              ),
              AppSpacing.gapH24,
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              AppSpacing.gapH8,
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.navy600,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                AppSpacing.gapH24,
                AppButton(
                  label: actionLabel!,
                  variant: AppButtonVariant.secondary,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Accessible error state with user-facing message, retry action, and optional details.
class AppErrorView extends StatefulWidget {
  const AppErrorView({
    required this.title,
    required this.message,
    super.key,
    this.onRetry,
    this.technicalDetails,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? technicalDetails;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.pXl,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF451A1A)
                      : AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: theme.colorScheme.error,
                ),
              ),
              AppSpacing.gapH24,
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              AppSpacing.gapH8,
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.navy600,
                ),
              ),
              if (widget.technicalDetails != null) ...[
                AppSpacing.gapH12,
                TextButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  child: Text(
                    _showDetails ? 'Hide technical details' : 'Show details',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.navy500,
                    ),
                  ),
                ),
                if (_showDetails) ...[
                  AppSpacing.gapH8,
                  Container(
                    padding: AppSpacing.pMd,
                    decoration: BoxDecoration(
                      color: tokens.subtleBackground,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: SelectableText(
                      widget.technicalDetails!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
              if (widget.onRetry != null) ...[
                AppSpacing.gapH24,
                AppButton(
                  label: 'Try Again',
                  icon: Icons.refresh_rounded,
                  onPressed: widget.onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Offline alert banner or view for network disconnects.
class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({
    super.key,
    this.message =
        'You are currently offline. Local progress will sync when reconnected.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF78350F) : AppColors.warningContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: isDark ? const Color(0xFFFCD34D) : AppColors.warning,
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFFFCD34D) : AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
