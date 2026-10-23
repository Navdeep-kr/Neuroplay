import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';

/// Typography hierarchy for NEUROPLAY.
///
/// Clean, legible sans-serif hierarchy engineered for high readability and
/// graceful scaling under dynamic type accessibility settings.
abstract final class AppTypography {
  static const String fontFamily = 'Roboto'; // System/standard fallback

  static TextTheme createTextTheme({required bool isDark}) {
    final primary = isDark ? AppColors.darkTextPrimary : AppColors.navy900;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.navy700;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.navy500;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.25,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.45,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.45,
        color: secondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: secondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.2,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
        color: muted,
      ),
    );
  }
}
