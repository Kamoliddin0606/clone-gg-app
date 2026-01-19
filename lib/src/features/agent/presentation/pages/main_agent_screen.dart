import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/agent_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/orders_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/reports_page.dart';
import 'package:gloria_marketing_flutter/src/features/navbars/agent_bottom_nav_bar.dart';

/// Main screen for Agent role with tab-based navigation
/// This prevents page recreation and maintains state across navigation
class MainAgentScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainAgentScreen({super.key, this.initialIndex = 0});

  @override
  State<MainAgentScreen> createState() => _MainAgentScreenState();
}

class _MainAgentScreenState extends State<MainAgentScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Pages are created once and cached
  late final List<Widget> _pages = [
    const AgentHomePage(key: PageStorageKey('agent_home')),
    const OrdersPage(key: PageStorageKey('orders')),
    const TradingPointsPage(key: PageStorageKey('trading_points')),
    // Placeholder for products page - will be implemented later
    Container(key: const PageStorageKey('products'), child: const Center(child: Text('Products Page'))),
    const ReportsPage(key: PageStorageKey('reports')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages, // All pages are kept in memory
      ),
      bottomNavigationBar: AgentBottomNavBar(
        initialIndex: _selectedIndex,
        onIndexChanged: _onItemTapped,
      ),
    );
  }
}