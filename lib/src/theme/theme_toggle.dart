import 'package:flutter/material.dart';

/// 3D Toggle Switch for Light/Dark mode with smooth animation
class ThemeToggle extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  const ThemeToggle({super.key, required this.mode, required this.onChanged});

  bool get isDark => mode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Track gradient based on mode
    final trackGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF7C3AED)], // Blue to purple
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], // Yellow to orange
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    return GestureDetector(
      onTap: () => onChanged(isDark ? ThemeMode.light : ThemeMode.dark),
      child: Container(
        width: 120,
        height: 32,
        decoration: BoxDecoration(
          gradient: trackGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icons on sides
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      size: 16,
                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.nightlight_round,
                      size: 16,
                      color: isDark ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            // Moving thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF7C3AED) : const Color(0xFFFF8C00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}