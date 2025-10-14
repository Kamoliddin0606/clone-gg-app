import 'package:flutter/material.dart';

/// Light/Dark schemes matched to your AgentHome palette.
final Color seed = const Color(0xFF6C63FF); // tweak if you like

/// Custom colors for glassmorphism effects and modern UI
class AppColors {
  // Glassmorphism background colors
  static const Color glassLightBg = Color(0x334B6BFF);
  static const Color glassDarkBg = Color(0x15FDFDFD);

  // Accent colors for gradients
  static const Color accentLight = Color(0xFF6C8CFF);
  static const Color accentDark = Color(0xFFEDF4F2);

  // Decorative blob colors
  static const Color blobPrimary = Color(0xFF6C8CFF);
  static const Color blobSecondary = Color(0xFFE3F1ED);

  // Chart colors
  static const Color chartPrimary = Color(0xFF6C8CFF);
  static const Color chartSecondary = Color(0xFFFFFFFF);
  static const Color chartTertiary = Color(0xFFFFA726);
}

final ThemeData appLight = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: AppColors.accentLight,
    secondary: AppColors.accentDark,
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
    seedColor: seed,
    brightness: Brightness.dark,
    primary: AppColors.accentLight,
    secondary: AppColors.accentDark,
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