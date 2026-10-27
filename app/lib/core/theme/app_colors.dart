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

  // --- Signature Electric Ultramarine Accent (Palette 1: Calm Focus & Obsidian) ---
  static const Color ultramarine50 = Color(0xFFEFF6FF);
  static const Color ultramarine100 = Color(0xFFDBEAFE);
  static const Color ultramarine200 = Color(0xFFBFDBFE);
  static const Color ultramarine400 = Color(0xFF60A5FA);
  static const Color ultramarine500 =
      Color(0xFF3B82F6); // Electric Blue (Primary)
  static const Color ultramarine600 =
      Color(0xFF2563EB); // Royal Blue (WCAG AA on white)
  static const Color ultramarine700 = Color(0xFF1D4ED8);
  static const Color ultramarine800 = Color(0xFF1E40AF);
  static const Color ultramarine900 = Color(0xFF1E3A8A);
  static const Color ultramarine950 = Color(0xFF172554);

  // Mint / Emerald aliases mapped to Ultramarine for backward compatibility
  static const Color mint50 = ultramarine50;
  static const Color mint100 = ultramarine100;
  static const Color mint200 = ultramarine200;
  static const Color mint400 = ultramarine400;
  static const Color mint500 = ultramarine500;
  static const Color mint600 = ultramarine600;
  static const Color mint700 = ultramarine700;
  static const Color mint800 = ultramarine800;
  static const Color mint900 = ultramarine900;
  static const Color mint950 = ultramarine950;

  // --- Spearmint & Sunset Accents (Palette 1) ---
  static const Color spearmint = Color(0xFF10B981);
  static const Color sunsetAmber = Color(0xFFF59E0B);
  static const Color coralThistle = Color(0xFFF87171);

  // --- Cognitive Faculty Themes (Lumosity / Elevate Tier) ---
  // Memory (Memory Matrix): Sapphire & Cobalt
  static const Color facultyMemoryPrimary = Color(0xFF2563EB);
  static const Color facultyMemoryLight = Color(0xFFEFF6FF);
  static const Color facultyMemoryBorder = Color(0xFFBFDBFE);

  // Flexibility (Reflex Forge): Emerald & Mint
  static const Color facultyFlexibilityPrimary = Color(0xFF10B981);
  static const Color facultyFlexibilityLight = Color(0xFFECFDF5);
  static const Color facultyFlexibilityBorder = Color(0xFFA7F3D0);

  // Attention (Focus Reactor): Amber & Tangerine
  static const Color facultyAttentionPrimary = Color(0xFFF59E0B);
  static const Color facultyAttentionLight = Color(0xFFFFFBEB);
  static const Color facultyAttentionBorder = Color(0xFFFDE68A);

  // Problem Solving (Logic Labyrinth): Indigo & Iris
  static const Color facultyProblemSolvingPrimary = Color(0xFF6366F1);
  static const Color facultyProblemSolvingLight = Color(0xFFEEF2FF);
  static const Color facultyProblemSolvingBorder = Color(0xFFC7D2FE);

  // Calculation (Number Pulse): Fuchsia & Vivid Orchid
  static const Color facultyCalculationPrimary = Color(0xFFEC4899);
  static const Color facultyCalculationLight = Color(0xFFFDF2F8);
  static const Color facultyCalculationBorder = Color(0xFFFBCFE8);

  // Language (Word Weaver): Oceanic Teal & Cyan
  static const Color facultyLanguagePrimary = Color(0xFF06B6D4);
  static const Color facultyLanguageLight = Color(0xFFECFEFF);
  static const Color facultyLanguageBorder = Color(0xFFA5F3FC);

  // --- Functional Status Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // --- Dark Mode Foundations (Palette 1: Obsidian Ink & Frosted Titanium) ---
  static const Color darkCanvas = Color(0xFF0B0E14); // Deep Obsidian Ink
  static const Color darkSurface = Color(0xFF141923); // Frosted Titanium
  static const Color darkCard = Color(0xFF161D2B); // Polished Obsidian Surface
  static const Color darkBorder =
      Color(0xFF232B3B); // Precision hairline border
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Focus & Accessibility ---
  static const Color focusRing = Color(0xFF2563EB);
  static const Color focusRingDark = Color(0xFF3B82F6);

  /// Material 3 Light ColorScheme.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ultramarine600,
    onPrimary: pureWhite,
    primaryContainer: ultramarine100,
    onPrimaryContainer: ultramarine950,
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
    primary: ultramarine500,
    onPrimary: pureWhite,
    primaryContainer: ultramarine900,
    onPrimaryContainer: ultramarine100,
    secondary: slate300,
    onSecondary: navy950,
    secondaryContainer: navy800,
    onSecondaryContainer: slate100,
    tertiary: navy400,
    onTertiary: navy950,
    tertiaryContainer: navy800,
    onTertiaryContainer: slate200,
    error: Color(0xFFF87171),
    onError: navy950,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: darkSurface,
    onSurface: darkTextPrimary,
    surfaceContainerHighest: darkCard,
    surfaceContainerHigh: Color(0xFF192131),
    surfaceContainer: darkSurface,
    surfaceContainerLow: darkCanvas,
    outline: darkBorder,
    outlineVariant: Color(0xFF1C2433),
    shadow: Color(0x33000000),
  );
}
