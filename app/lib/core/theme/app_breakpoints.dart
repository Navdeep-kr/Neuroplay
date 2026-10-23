import 'package:flutter/material.dart';

/// Screen size categorization for responsive layouts.
enum WindowSizeClass {
  compact, // Mobile (< 640dp)
  medium, // Tablet (640dp - 1023dp)
  expanded, // Desktop & Large Web (>= 1024dp)
}

/// Breakpoint tokens and responsive helpers.
abstract final class AppBreakpoints {
  static const double compactMax = 640;
  static const double mediumMax = 1024;
  static const double maxContentWidth = 1140;

  /// Returns the current [WindowSizeClass] for a given [BuildContext].
  static WindowSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactMax) return WindowSizeClass.compact;
    if (width < mediumMax) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  /// Convenience flags
  static bool isCompact(BuildContext context) =>
      of(context) == WindowSizeClass.compact;

  static bool isMedium(BuildContext context) =>
      of(context) == WindowSizeClass.medium;

  static bool isExpanded(BuildContext context) =>
      of(context) == WindowSizeClass.expanded;
}

/// A container that constrains content to a maximum readable width and
/// centers it horizontally on wide displays.
class MaxWidthContainer extends StatelessWidget {
  const MaxWidthContainer({
    required this.child,
    super.key,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return content;
  }
}
