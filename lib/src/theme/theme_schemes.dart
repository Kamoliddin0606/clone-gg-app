import 'package:flutter/material.dart';

/// Custom color scheme with multiple seeds for enhanced theming
final Color primarySeed = const Color(0xFF6366F1); // indigo 500
final Color secondarySeed = const Color(0xFFA78BFA); // violet 400
final Color tertiarySeed = const Color(0xFF22D3EE); // cyan 400

/// Light theme with custom colors
final ThemeData appLight = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.light,
    secondary: secondarySeed,
    tertiary: tertiarySeed,
  ).copyWith(
    // Custom surface colors for better contrast and readability
    background: const Color(0xFFF8F7FF),
    surface: const Color(0xFFFFFFFF),
    surfaceVariant: const Color(0xFFF3F4FF),
    outline: const Color(0xFFE5E7FF),
    onSurface: const Color(0xFF0B0F1A),
  ),
);

/// Dark theme with custom colors
final ThemeData appDark = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.dark,
    secondary: secondarySeed,
    tertiary: tertiarySeed,
  ).copyWith(
    // Custom surface colors for dark mode
    background: const Color(0xFF0B0B12),
    surface: const Color(0xFF111322),
    surfaceVariant: const Color(0xFF151833),
    outline: const Color(0xFF2A2F55),
    onSurface: const Color(0xFFE7E9FF),
  ),
);