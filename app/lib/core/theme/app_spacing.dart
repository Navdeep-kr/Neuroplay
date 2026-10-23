import 'package:flutter/widgets.dart';

/// Reusable layout and spacing tokens.
///
/// Follows an 8pt grid with select 4pt and 12pt steps for dense controls.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  // Inset presets
  static const EdgeInsets pXs = EdgeInsets.all(xs);
  static const EdgeInsets pSm = EdgeInsets.all(sm);
  static const EdgeInsets pMd = EdgeInsets.all(md);
  static const EdgeInsets pLg = EdgeInsets.all(lg);
  static const EdgeInsets pXl = EdgeInsets.all(xl);
  static const EdgeInsets pXxl = EdgeInsets.all(xxl);

  // Horizontal insets
  static const EdgeInsets pHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets pHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pHLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pHXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets pHXxl = EdgeInsets.symmetric(horizontal: xxl);

  // Vertical insets
  static const EdgeInsets pVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets pVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets pVLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets pVXl = EdgeInsets.symmetric(vertical: xl);

  // SizedBox gaps (horizontal)
  static const Widget gapW4 = SizedBox(width: xs);
  static const Widget gapW8 = SizedBox(width: sm);
  static const Widget gapW12 = SizedBox(width: md);
  static const Widget gapW16 = SizedBox(width: lg);
  static const Widget gapW24 = SizedBox(width: xl);
  static const Widget gapW32 = SizedBox(width: xxl);

  // SizedBox gaps (vertical)
  static const Widget gapH2 = SizedBox(height: xxs);
  static const Widget gapH4 = SizedBox(height: xs);
  static const Widget gapH6 = SizedBox(height: 6);
  static const Widget gapH8 = SizedBox(height: sm);
  static const Widget gapH12 = SizedBox(height: md);
  static const Widget gapH16 = SizedBox(height: lg);
  static const Widget gapH24 = SizedBox(height: xl);
  static const Widget gapH32 = SizedBox(height: xxl);
  static const Widget gapH48 = SizedBox(height: xxxl);
  static const Widget gapH64 = SizedBox(height: huge);
}
