import 'package:flutter/widgets.dart';

/// Motion and animation tokens with accessibility (reduced motion) support.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOut;

  /// Returns [base] if animations are enabled, or [Duration.zero] if the user
  /// has requested reduced motion in their system accessibility preferences.
  static Duration responsiveDuration(BuildContext context, Duration base) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : base;
  }
}
