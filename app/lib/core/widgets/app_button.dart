import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, subtle, danger }

/// Accessible, keyboard-navigable button with consistent styling and touch targets.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color background;
    Color foreground;
    var borderSide = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        background = theme.colorScheme.primary;
        foreground = theme.colorScheme.onPrimary;
      case AppButtonVariant.secondary:
        background = Colors.transparent;
        foreground = theme.colorScheme.onSurface;
        borderSide = BorderSide(color: tokens.cardBorder);
      case AppButtonVariant.subtle:
        background = isDark ? AppColors.darkCard : AppColors.slate100;
        foreground = theme.colorScheme.onSurface;
      case AppButtonVariant.danger:
        background = theme.colorScheme.error;
        foreground = theme.colorScheme.onError;
    }

    final child = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
          AppSpacing.gapW8,
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: foreground),
          AppSpacing.gapW8,
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      container: true,
      excludeSemantics: true,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        enabled: isEnabled,
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: _isFocused
                ? Border.all(color: tokens.focusRingColor, width: 2)
                : null,
          ),
          child: Material(
            color: isEnabled ? background : background.withAlpha(120),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.rMd,
              side: borderSide,
            ),
            child: InkWell(
              onTap: isEnabled ? widget.onPressed : null,
              borderRadius: AppRadii.rMd,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 48, // WCAG touch target height
                  minWidth: widget.isFullWidth ? double.infinity : 48,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
