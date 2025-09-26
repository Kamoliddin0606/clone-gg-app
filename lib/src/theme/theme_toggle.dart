import 'package:flutter/material.dart';

/// Neumorphic pill toggle (Light <-> Dark) similar to the screenshot.
/// Use inside AppBars (actions) or anywhere.
class ThemeToggle extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  const ThemeToggle({super.key, required this.mode, required this.onChanged});

  bool get isDark => mode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surface;
    final shadow = Colors.black.withOpacity(0.12);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: cs.onSurface.withOpacity(.08), blurRadius: 1, offset: const Offset(0, 1)),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Stack(
        children: [
          // moving thumb
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 80,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHighest : cs.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isDark) BoxShadow(color: Colors.white.withOpacity(.9), blurRadius: 6, offset: const Offset(-1, -1)),
                  BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 8, offset: const Offset(1, 2)),
                ],
              ),
            ),
          ),

          // content
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _side(
                context,
                active: !isDark,
                icon: Icons.wb_sunny_rounded,
                label: 'LIGHT',
                onTap: () => onChanged(ThemeMode.light),
              ),
              _side(
                context,
                active: isDark,
                icon: Icons.nightlight_round,
                label: 'DARK',
                onTap: () => onChanged(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _side(BuildContext context, {required bool active, required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.onSurface : cs.onSurface.withOpacity(.6);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        width: 86,
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}