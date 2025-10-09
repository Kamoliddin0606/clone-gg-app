import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/agent_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/warehouses_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/contracts_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/reports_page.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/pages/login_page.dart';
import 'package:gloria_marketing_flutter/src/features/boss/presentation/pages/boss_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/collector/presentation/pages/collector_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/forwarder/presentation/pages/forwarder_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/packer/presentation/pages/packer_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/pages/marketing_page.dart';
import 'package:gloria_marketing_flutter/src/features/warehouse_manager/presentation/pages/warehouse_manager_home_page.dart';

class AppRouter {
  static const String loginRoute = '/';
  static const String agentHomeRoute = '/agent-home';
  static const String bossHomeRoute = '/boss-home';
  static const String collectorHomeRoute = '/collector-home';
  static const String forwarderHomeRoute = '/forwarder-home';
  static const String packerHomeRoute = '/packer-home';
  static const String warehouseManagerHomeRoute = '/warehouse-manager-home';
  static const String tradingPointsRoute = '/trading-points';
  static const String warehousesRoute = '/warehouses';
  static const String contractsRoute = '/contracts';
  static const String marketingRoute = '/marketing';
  static const String reportsRoute = '/reports';
  static const String settingsRoute = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case agentHomeRoute:
        return MaterialPageRoute(builder: (_) => const AgentHomePage());
      case bossHomeRoute:
        return MaterialPageRoute(builder: (_) => const BossHomePage());
      case collectorHomeRoute:
        return MaterialPageRoute(builder: (_) => const CollectorHomePage());
      case forwarderHomeRoute:
        return MaterialPageRoute(builder: (_) => const ForwarderHomePage());
      case packerHomeRoute:
        return MaterialPageRoute(builder: (_) => const PackerHomePage());
      case warehouseManagerHomeRoute:
        return MaterialPageRoute(builder: (_) => const WarehouseManagerHomePage());
      case tradingPointsRoute:
        return MaterialPageRoute(builder: (_) => const TradingPointsPage());
      case warehousesRoute:
        return MaterialPageRoute(builder: (_) => const WarehousesPage());
      case contractsRoute:
        return MaterialPageRoute(builder: (_) => const ContractsPage());
      case marketingRoute:
        return MaterialPageRoute(builder: (_) => const MarketingPage());
      case reportsRoute:
        return MaterialPageRoute(builder: (_) => const ReportsPage());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}