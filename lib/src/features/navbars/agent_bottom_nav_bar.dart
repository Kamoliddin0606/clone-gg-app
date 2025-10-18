import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'fluid_nav_bar.dart';

class AgentBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  const AgentBottomNavBar({
    super.key,
    required this.initialIndex,
    this.onIndexChanged,
  });

  @override
  State<AgentBottomNavBar> createState() => _AgentBottomNavBarState();
}

class _AgentBottomNavBarState extends State<AgentBottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      widget.onIndexChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FluidNavBar(
      initialIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      items: [
        FluidNavItem(
          icon: Icons.home,
          label: AppLocalizations.of(context)!.home,
        ),
        FluidNavItem(
          icon: Icons.add_shopping_cart,
          label: AppLocalizations.of(context)!.orders,
        ),
        FluidNavItem(
          icon: Icons.people,
          label: AppLocalizations.of(context)!.customers,
        ),
        FluidNavItem(
          icon: Icons.storefront,
          label: AppLocalizations.of(context)!.products,
        ),
        FluidNavItem(
          icon: Icons.insert_chart_outlined,
          label: AppLocalizations.of(context)!.reports,
        ),
      ],
    );
  }
}