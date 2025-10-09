import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'fluid_nav_bar.dart';

class AgentBottomNavBar extends StatelessWidget {
  final int initialIndex;

  const AgentBottomNavBar({
    super.key,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return FluidNavBar(
      initialIndex: initialIndex,
      items: [
        FluidNavItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () => Navigator.pushNamed(context, AppRouter.agentHomeRoute),
        ),
        FluidNavItem(
          icon: Icons.add_shopping_cart,
          label: 'Buyurtma',
        ),
        FluidNavItem(
          icon: Icons.people,
          label: 'Mijozlar',
          onTap: () => Navigator.pushNamed(context, AppRouter.tradingPointsRoute),
        ),
        FluidNavItem(
          icon: Icons.storefront,
          label: 'Tovarlar',
        ),
        FluidNavItem(
          icon: Icons.insert_chart_outlined,
          label: 'Hisobot',
          onTap: () => Navigator.pushNamed(context, '/reports'),
        ),
      ],
    );
  }
}