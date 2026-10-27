import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_typography.dart';

/// Extension for accessing custom NEUROPLAY design tokens directly via Theme.of(context).
class AppCustomTokens extends ThemeExtension<AppCustomTokens> {
  const AppCustomTokens({
    required this.cardBackground,
    required this.cardBorder,
    required this.subtleBackground,
    required this.mintContainer,
    required this.onMintContainer,
    required this.statCardBackground,
    required this.focusRingColor,
  });

  final Color cardBackground;
  final Color cardBorder;
  final Color subtleBackground;
  final Color mintContainer;
  final Color onMintContainer;
  final Color statCardBackground;
  final Color focusRingColor;

  static const light = AppCustomTokens(
    cardBackground: AppColors.pureWhite,
    cardBorder: AppColors.slate200,
    subtleBackground: AppColors.slate50,
    mintContainer: AppColors.mint100,
    onMintContainer: AppColors.mint950,
    statCardBackground: AppColors.slate50,
    focusRingColor: AppColors.focusRing,
  );

  static const dark = AppCustomTokens(
    cardBackground: AppColors.darkCard,
    cardBorder: AppColors.darkBorder,
    subtleBackground: AppColors.darkSurface,
    mintContainer: AppColors.mint900,
    onMintContainer: AppColors.mint100,
    statCardBackground: AppColors.darkCard,
    focusRingColor: AppColors.focusRingDark,
  );

  @override
  ThemeExtension<AppCustomTokens> copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? subtleBackground,
    Color? mintContainer,
    Color? onMintContainer,
    Color? statCardBackground,
    Color? focusRingColor,
  }) =>
      AppCustomTokens(
        cardBackground: cardBackground ?? this.cardBackground,
        cardBorder: cardBorder ?? this.cardBorder,
        subtleBackground: subtleBackground ?? this.subtleBackground,
        mintContainer: mintContainer ?? this.mintContainer,
        onMintContainer: onMintContainer ?? this.onMintContainer,
        statCardBackground: statCardBackground ?? this.statCardBackground,
        focusRingColor: focusRingColor ?? this.focusRingColor,
      );

  @override
  ThemeExtension<AppCustomTokens> lerp(
    covariant ThemeExtension<AppCustomTokens>? other,
    double t,
  ) {
    if (other is! AppCustomTokens) return this;
    return AppCustomTokens(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleBackground:
          Color.lerp(subtleBackground, other.subtleBackground, t)!,
      mintContainer: Color.lerp(mintContainer, other.mintContainer, t)!,
      onMintContainer: Color.lerp(onMintContainer, other.onMintContainer, t)!,
      statCardBackground:
          Color.lerp(statCardBackground, other.statCardBackground, t)!,
      focusRingColor: Color.lerp(focusRingColor, other.focusRingColor, t)!,
    );
  }
}

/// Convenience getter for `Theme.of(context).extension<AppCustomTokens>()`.
extension AppThemeX on BuildContext {
  AppCustomTokens get tokens =>
      Theme.of(this).extension<AppCustomTokens>() ?? AppCustomTokens.light;
}

/// Main application theme definitions (Light & Dark).
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(
        colorScheme: AppColors.lightScheme,
        isDark: false,
        tokens: AppCustomTokens.light,
      );

  static ThemeData get dark => _buildTheme(
        colorScheme: AppColors.darkScheme,
        isDark: true,
        tokens: AppCustomTokens.dark,
      );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isDark,
    required AppCustomTokens tokens,
  }) {
    final textTheme = AppTypography.createTextTheme(isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkCanvas : AppColors.pureWhite,
      textTheme: textTheme,
      extensions: [tokens],

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.pureWhite,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rLg,
          side: BorderSide(color: tokens.cardBorder),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button Theme (Primary Action)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(48, 48), // WCAG minimum touch target
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: BorderSide(color: tokens.cardBorder),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rSm),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextMuted : AppColors.navy500,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.navy700,
        ),
      ),

      // Navigation Bar (Mobile Bottom Navigation)
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        indicatorColor: tokens.mintContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? AppColors.mint400 : AppColors.mint700,
              size: 24,
            );
          }
          return IconThemeData(
            color: isDark ? AppColors.darkTextMuted : AppColors.navy500,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: isDark ? AppColors.mint400 : AppColors.mint700,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.navy500,
          );
        }),
      ),

      // Navigation Rail (Tablet / Web Desktop Side Nav)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        indicatorColor: tokens.mintContainer,
        selectedIconTheme: IconThemeData(
          color: isDark ? AppColors.mint400 : AppColors.mint700,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextMuted : AppColors.navy500,
          size: 24,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: isDark ? AppColors.mint400 : AppColors.mint700,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: isDark ? AppColors.darkTextMuted : AppColors.navy500,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.pureWhite,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.navy700,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: tokens.cardBorder,
        space: 1,
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.slate100,
        selectedColor: tokens.mintContainer,
        side: BorderSide(color: tokens.cardBorder),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rFull),
        labelStyle: textTheme.labelMedium,
      ),
    );
  }
}
