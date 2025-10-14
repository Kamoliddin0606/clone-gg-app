import 'package:flutter/material.dart';

/// Seeds for color scheme generation
const Color primarySeed = Color(0xFF3B82F6); // blue 500
const Color secondarySeed = Color(0xFF64748B); // slate 500
const Color tertiarySeed = Color(0xFF10B981); // emerald 500

/// Custom colors for glassmorphism effects and modern UI
class AppColors {
  // Glassmorphism background colors
  static const Color glassLightBg = Color(0x333B82F6); // based on primary seed
  static const Color glassDarkBg = Color(0x15E5E7EB); // based on onSurface light

  // Accent colors for gradients
  static const Color accentLight = Color(0xFF3B82F6); // primary seed
  static const Color accentDark = Color(0xFF64748B); // secondary seed

  // Decorative blob colors
  static const Color blobPrimary = Color(0xFF3B82F6); // primary seed
  static const Color blobSecondary = Color(0xFF10B981); // tertiary seed

  // Chart colors
  static const Color chartPrimary = Color(0xFF3B82F6); // primary seed
  static const Color chartSecondary = Color(0xFFFFFFFF);
  static const Color chartTertiary = Color(0xFF64748B); // secondary seed
}

final ThemeData appLight = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.light,
    primary: primarySeed,
    secondary: secondarySeed,
    tertiary: tertiarySeed,
    surface: const Color(0xFFF7F7F9),
    surfaceContainerHighest: const Color(0xFFFFFFFF),
    outline: const Color(0xFFE5E7EB),
    onSurface: const Color(0xFF111827),
  ),
  // Custom extensions for glassmorphism
  extensions: [
    AppThemeExtension(
      glassBackground: AppColors.glassLightBg,
      accentPrimary: AppColors.accentLight,
      accentSecondary: AppColors.accentDark,
      blobPrimary: AppColors.blobPrimary,
      blobSecondary: AppColors.blobSecondary,
    ),
  ],
);

final ThemeData appDark = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.dark,
    primary: primarySeed,
    secondary: secondarySeed,
    tertiary: tertiarySeed,
    surface: const Color(0xFF0F172A),
    surfaceContainerHighest: const Color(0xFF1F2937),
    outline: const Color(0xFF334155),
    onSurface: const Color(0xFFE5E7EB),
  ),
  // Custom extensions for glassmorphism
  extensions: [
    AppThemeExtension(
      glassBackground: AppColors.glassDarkBg,
      accentPrimary: AppColors.accentLight,
      accentSecondary: AppColors.accentDark,
      blobPrimary: AppColors.blobPrimary,
      blobSecondary: AppColors.blobSecondary,
    ),
  ],
);

/// Theme extension for custom colors used in modern UI components
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color glassBackground;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color blobPrimary;
  final Color blobSecondary;

  const AppThemeExtension({
    required this.glassBackground,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.blobPrimary,
    required this.blobSecondary,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? glassBackground,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? blobPrimary,
    Color? blobSecondary,
  }) {
    return AppThemeExtension(
      glassBackground: glassBackground ?? this.glassBackground,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      blobPrimary: blobPrimary ?? this.blobPrimary,
      blobSecondary: blobSecondary ?? this.blobSecondary,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      blobPrimary: Color.lerp(blobPrimary, other.blobPrimary, t)!,
      blobSecondary: Color.lerp(blobSecondary, other.blobSecondary, t)!,
    );
  }
}