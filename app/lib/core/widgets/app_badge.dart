import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';

enum AppBadgeVariant { mint, neutral, info, warning, success, outline }

/// A compact pill badge for categorization, domain tags, or state indicators.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    Color background;
    Color foreground;
    var borderSide = BorderSide.none;

    switch (variant) {
      case AppBadgeVariant.mint:
        background = tokens.mintContainer;
        foreground = tokens.onMintContainer;
        borderSide = BorderSide(
          color: isDark ? const Color(0x4010B981) : const Color(0xFFA7F3D0),
        );
      case AppBadgeVariant.neutral:
        background = isDark ? AppColors.darkCard : AppColors.slate100;
        foreground = isDark ? AppColors.darkTextSecondary : AppColors.navy700;
        borderSide = BorderSide(color: tokens.cardBorder);
      case AppBadgeVariant.info:
        background = isDark ? const Color(0xFF1E3A8A) : AppColors.infoContainer;
        foreground = isDark ? const Color(0xFF93C5FD) : AppColors.info;
      case AppBadgeVariant.warning:
        background =
            isDark ? const Color(0xFF78350F) : AppColors.warningContainer;
        foreground = isDark ? const Color(0xFFFCD34D) : AppColors.warning;
      case AppBadgeVariant.success:
        background =
            isDark ? const Color(0xFF14532D) : AppColors.successContainer;
        foreground = isDark ? const Color(0xFF86EFAC) : AppColors.success;
      case AppBadgeVariant.outline:
        background = Colors.transparent;
        foreground = isDark ? AppColors.darkTextSecondary : AppColors.navy700;
        borderSide = BorderSide(color: tokens.cardBorder);
    }

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.rFull,
        border: borderSide != BorderSide.none
            ? Border.fromBorderSide(borderSide)
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            AppSpacing.gapW4,
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
