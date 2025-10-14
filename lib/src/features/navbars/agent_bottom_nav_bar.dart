import 'package:flutter/material.dart';
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
          label: 'Home',
        ),
        FluidNavItem(
          icon: Icons.add_shopping_cart,
          label: 'Buyurtma',
        ),
        FluidNavItem(
          icon: Icons.people,
          label: 'Mijozlar',
        ),
        FluidNavItem(
          icon: Icons.storefront,
          label: 'Tovarlar',
        ),
        FluidNavItem(
          icon: Icons.insert_chart_outlined,
          label: 'Hisobot',
        ),
      ],
    );
  }
}