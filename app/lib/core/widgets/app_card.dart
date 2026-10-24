import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';

/// Reusable content card with neutral surface, subtle border, and optional interaction.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = AppSpacing.pLg,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppRadii.rLg,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = widget.backgroundColor ?? tokens.cardBackground;
    final border = widget.borderColor ?? tokens.cardBorder;

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: _isFocused ? tokens.focusRingColor : border,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: widget.borderRadius,
                child: Padding(padding: widget.padding, child: widget.child),
              )
            : Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget.onTap != null) {
      card = FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: card,
        ),
      );
    }

    return card;
  }
}
