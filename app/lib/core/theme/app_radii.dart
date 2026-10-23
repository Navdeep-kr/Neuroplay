import 'package:flutter/widgets.dart';

/// Reusable border radius tokens for NEUROPLAY rounded components.
abstract final class AppRadii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;

  // BorderRadius objects
  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rFull = BorderRadius.all(Radius.circular(full));

  // Top rounded (e.g., bottom sheets)
  static const BorderRadius rTopLg = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  static const BorderRadius rTopXl = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
