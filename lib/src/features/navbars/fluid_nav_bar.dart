import 'package:flutter/material.dart';

class FluidNavItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const FluidNavItem({required this.icon, required this.label, this.onTap});
}

class FluidNavBar extends StatefulWidget {
  final List<FluidNavItem> items;   // 3–5 element
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final EdgeInsets padding;
  final double height;

  const FluidNavBar({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onIndexChanged,
    // this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
    this.padding = EdgeInsets.zero,
    this.height = 64,
  });

  @override
  State<FluidNavBar> createState() => _FluidNavBarState();
}

class _FluidNavBarState extends State<FluidNavBar> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final pill = theme.colorScheme.primaryContainer;
    final onPill = theme.colorScheme.onPrimaryContainer;

        return SafeArea(
          top: false,
          // minimum: const EdgeInsets.only(bottom: 8), // CHANGED: faqat pastdan xavfsiz zona
          child: Container(
            width: double.infinity,                   // CHANGED: to‘liq kenglik
            color: theme.colorScheme.surfaceContainerHighest, // CHANGED: chetlar to‘liq yopiladi
            child: SizedBox(
              height: widget.height,
              child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // pastdagi "track" chizig'i (namunadagi ingichka chiziq)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 88,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                                      children: List.generate(widget.items.length, (i) {
                                      final item = widget.items[i];
                                      final selected = i == _index;
                                      return Expanded(                       // CHANGED: har biri teng slotda
                                        child: _FluidItem(
                                          icon: item.icon,
                                          label: item.label,
                                          selected: selected,
                                          pillColor: pill,
                                          onPillColor: onPill,
                                          onTap: () {
                                            if (_index != i) {
                                              setState(() => _index = i);
                                              widget.onIndexChanged?.call(i);
                                            }
                                            item.onTap?.call();
                                          },
                                        ),
                                      );
                                    }),
                                ),
              ],
            ),
          ),
        ),

    );
  }
}

class _FluidItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color pillColor;
  final Color onPillColor;
  final VoidCallback? onTap;

  const _FluidItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.pillColor,
    required this.onPillColor,
    this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // Slotga qarab moslashtirish
        final iconSize = w >= 96 ? 26.0 : w >= 80 ? 24.0 : 22.0;
        final hPad = 10.0; // vertical tartibda gorizontal pad kamroq bo'lsin
        const dur = Duration(milliseconds: 220);
        const curve = Curves.easeOutCubic;

        final targetScale = selected ? 1.0 : 0.92; // aktiv kattaroq, passiv biroz kichikroq

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: dur,
            curve: curve,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? pillColor : Colors.transparent, // kapsula rangi joyida fade
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON — joyida scale
                AnimatedScale(
                  scale: targetScale,
                  duration: dur,
                  curve: curve,
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: selected
                        ? onPillColor
                        : theme.iconTheme.color ?? theme.colorScheme.onSurface,
                  ),
                ),

                // icon va label orasidagi bo'shliq: aktivda 6, passivda 2
                AnimatedSize(
                  duration: dur,
                  curve: curve,
                  child: SizedBox(height: selected ? 6 : 2),
                ),

                // LABEL — joyida opacity + size (hech qayerga siljimaydi)
                ClipRect(
                  child: AnimatedSize(
                    duration: dur,
                    curve: curve,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutQuad,
                      opacity: selected ? 1 : 0,
                      child: selected
                          ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: onPillColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}
