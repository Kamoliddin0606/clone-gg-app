import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/agent_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_osm.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_yandex.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_google.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/warehouses_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/contracts_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/reports_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/orders_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/db_view_page.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/pages/login_page.dart';
import 'package:gloria_marketing_flutter/src/features/boss/presentation/pages/boss_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/collector/presentation/pages/collector_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/forwarder/presentation/pages/forwarder_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/packer/presentation/pages/packer_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/pages/marketing_page.dart';
import 'package:gloria_marketing_flutter/src/features/warehouse_manager/presentation/pages/warehouse_manager_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/main_agent_screen.dart';

class AppRouter {
  static const String loginRoute = '/';
  static const String agentHomeRoute = '/agent-home';
  static const String mainAgentScreenRoute = '/main-agent'; // New main screen route
  static const String bossHomeRoute = '/boss-home';
  static const String collectorHomeRoute = '/collector-home';
  static const String forwarderHomeRoute = '/forwarder-home';
  static const String packerHomeRoute = '/packer-home';
  static const String warehouseManagerHomeRoute = '/warehouse-manager-home';
  static const String tradingPointsRoute = '/trading-points';
  static const String mapDetailRoute = '/map-detail-osm';
  static const String mapDetailOsmRoute = '/map-detail-osm-fullscreen';
  static const String mapDetailYandexRoute = '/map-detail-yandex-fullscreen';
  static const String mapDetailGoogleRoute = '/map-detail-google-fullscreen';
  static const String warehousesRoute = '/warehouses';
  static const String contractsRoute = '/contracts';
  static const String marketingRoute = '/marketing';
  static const String reportsRoute = '/reports';
  static const String settingsRoute = '/settings';
  static const String ordersRoute = '/orders';
  static const String dbViewRoute = '/db-view';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case agentHomeRoute:
        // For backward compatibility, redirect to main agent screen
        return MaterialPageRoute(builder: (_) => const MainAgentScreen());
      case mainAgentScreenRoute:
        return MaterialPageRoute(builder: (_) => const MainAgentScreen());
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
      case mapDetailRoute:
        final tradingPoint = settings.arguments as model.TradingPoint?;
        if (tradingPoint != null) {
          return MaterialPageRoute(
            builder: (_) => MapDetailPage(tradingPoint: tradingPoint),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: const Center(
              child: Text('Trading point data is required for map detail page'),
            ),
          ),
        );
      case mapDetailOsmRoute:
        final tradingPoint = settings.arguments as model.TradingPoint?;
        if (tradingPoint != null) {
          return MaterialPageRoute(
            builder: (_) => MapDetailPageOsm(tradingPoint: tradingPoint),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: const Center(
              child: Text('Trading point data is required for OSM map detail page'),
            ),
          ),
        );
      case mapDetailYandexRoute:
        final tradingPoint = settings.arguments as model.TradingPoint?;
        if (tradingPoint != null) {
          return MaterialPageRoute(
            builder: (_) => MapDetailPageYandex(tradingPoint: tradingPoint),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: const Center(
              child: Text('Trading point data is required for Yandex map detail page'),
            ),
          ),
        );
      case mapDetailGoogleRoute:
        final tradingPoint = settings.arguments as model.TradingPoint?;
        if (tradingPoint != null) {
          return MaterialPageRoute(
            builder: (_) => MapDetailPageGoogle(tradingPoint: tradingPoint),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: const Center(
              child: Text('Trading point data is required for Google map detail page'),
            ),
          ),
        );
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
      case ordersRoute:
        return MaterialPageRoute(builder: (_) => const OrdersPage());
      case dbViewRoute:
        return MaterialPageRoute(builder: (_) => const DbViewPage());
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