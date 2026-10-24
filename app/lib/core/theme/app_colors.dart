import 'package:flutter/material.dart';

/// Design tokens for NEUROPLAY colors.
///
/// Palette direction:
/// - Neutral surfaces (crisp slate50 canvas and pure white cards).
/// - Deep navy typography and structural elements (navy900, navy800).
/// - Signature radiant Emerald / Mint accent for focused actions, progress, and badges.
/// - Calibrated for high-contrast accessibility (WCAG AA/AAA).
abstract final class AppColors {
  // --- Navy & Slates (Structure & Hierarchy) ---
  static const Color navy950 = Color(0xFF090D16);
  static const Color navy900 = Color(0xFF0F172A);
  static const Color navy800 = Color(0xFF1E293B);
  static const Color navy700 = Color(0xFF334155);
  static const Color navy600 = Color(0xFF475569);
  static const Color navy500 = Color(0xFF64748B);
  static const Color navy400 = Color(0xFF94A3B8);

  // --- Neutrals (Surfaces & Borders) ---
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);

  // --- Signature Emerald / Mint Accent (Unified with Marketing Website) ---
  static const Color mint50 = Color(0xFFECFDF5);
  static const Color mint100 = Color(0xFFD1FAE5);
  static const Color mint200 = Color(0xFFA7F3D0);
  static const Color mint400 = Color(0xFF34D399);
  static const Color mint500 = Color(0xFF10B981); // Emerald 500
  static const Color mint600 =
      Color(0xFF059669); // Emerald 600 (WCAG AA on white)
  static const Color mint700 = Color(0xFF047857);
  static const Color mint800 = Color(0xFF065F46);
  static const Color mint900 = Color(0xFF064E3B);
  static const Color mint950 = Color(0xFF022C22);

  // --- Functional Status Colors ---
  static const Color success = Color(0xFF15803D);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // --- Dark Mode Foundations (Exact Match with Marketing Theme) ---
  static const Color darkCanvas = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF131B2A);
  static const Color darkBorder = Color(0xFF243048);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Focus & Accessibility ---
  static const Color focusRing = Color(0xFF059669);
  static const Color focusRingDark = Color(0xFF10B981);

  /// Material 3 Light ColorScheme.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: mint600,
    onPrimary: pureWhite,
    primaryContainer: mint100,
    onPrimaryContainer: mint950,
    secondary: navy800,
    onSecondary: pureWhite,
    secondaryContainer: slate100,
    onSecondaryContainer: navy900,
    tertiary: navy600,
    onTertiary: pureWhite,
    tertiaryContainer: slate200,
    onTertiaryContainer: navy900,
    error: error,
    onError: pureWhite,
    errorContainer: errorContainer,
    onErrorContainer: Color(0xFF7F1D1D),
    surface: pureWhite,
    onSurface: navy900,
    surfaceContainerHighest: slate100,
    surfaceContainerHigh: slate50,
    surfaceContainer: pureWhite,
    surfaceContainerLow: slate50,
    outline: slate200,
    outlineVariant: slate100,
    shadow: Color(0x0A0F172A),
  );

  /// Material 3 Dark ColorScheme.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: mint400,
    onPrimary: navy950,
    primaryContainer: mint900,
    onPrimaryContainer: mint100,
    secondary: slate300,
    onSecondary: navy950,
    secondaryContainer: navy800,
    onSecondaryContainer: slate100,
    tertiary: navy400,
    onTertiary: navy950,
    tertiaryContainer: navy800,
    onTertiaryContainer: slate200,
    error: Color(0xFFEF4444),
    onError: navy950,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: darkSurface,
    onSurface: darkTextPrimary,
    surfaceContainerHighest: darkCard,
    surfaceContainerHigh: Color(0xFF151D2C),
    surfaceContainer: darkSurface,
    surfaceContainerLow: darkCanvas,
    outline: darkBorder,
    outlineVariant: Color(0xFF202B3C),
    shadow: Color(0x33000000),
  );
}
