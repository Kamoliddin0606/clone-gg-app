import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart' show sl;
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/outbox_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/visit_finish_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/bloc/outbox_status/outbox_status_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/pages/dead_letter_page.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/pages/visit_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/pages/visit_list_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/agent_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/project_picker_page.dart';
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
import 'package:gloria_marketing_flutter/src/core/widgets/permission_check_page.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/pages/knowledge_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/pages/knowledge_category_page.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/pages/knowledge_document_page.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/pages/knowledge_search_page.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/presentation/version_gate_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static const String permissionCheckRoute = '/permission-check';
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
  static const String faqRoute = '/faq';
  static const String knowledgeRoute = '/knowledge';
  static const String knowledgeCategoryRoute = '/knowledge/category';
  static const String knowledgeDocumentRoute = '/knowledge/document';
  static const String knowledgeSearchRoute = '/knowledge/search';
  // Notification center — see docs/notifications/passport-mobile.md.
  static const String notificationListRoute = '/notifications';
  static const String notificationDetailRoute = '/notifications/detail';
  static const String notificationPreferencesRoute = '/notifications/preferences';

  /// Visits v2 dead-letter / sync screen. Surfaces envelopes the outbox
  /// dispatcher couldn't deliver and lets the agent retry or discard them.
  static const String visitsSyncRoute = '/visits/sync';

  /// Visits v2 history list (`GET /visits/`). Cursor-paginated. Filtered
  /// by customer when arguments include a `customer_id` string.
  static const String visitsHistoryRoute = '/visits/history';

  /// Visits v2 detail view (`GET /visits/{id}/`). Arguments must include
  /// a `visit_id` string.
  static const String visitsDetailRoute = '/visits/detail';
  // Active project picker for `customer_scope=project` tenants.
  // See ProjectContext + mobile-customer-scope.md backend handoff.
  static const String projectPickerRoute = '/project-picker';
  // App version gate (force_update / blocked / maintenance) — full-screen,
  // back disabled. See docs/integration-prompts/mobile-app-version-*.md.
  static const String versionGateRoute = '/version-gate';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case permissionCheckRoute:
        return MaterialPageRoute(builder: (_) => const PermissionCheckPage());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case agentHomeRoute:
        // For backward compatibility, redirect to main agent screen
        return MaterialPageRoute(builder: (_) => const MainAgentScreen());
      case mainAgentScreenRoute:
        final initialIndex = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => MainAgentScreen(initialIndex: initialIndex ?? 0),
        );
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
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );
      case visitsSyncRoute:
        return MaterialPageRoute(
          builder: (_) {
            // RepositoryProvider ships with flutter_bloc so we don't have
            // to take a direct dependency on `package:provider`. The
            // DeadLetterPage uses `context.read<OutboxRepository>()` and
            // `context.read<VisitFinishOrchestrator>()`, which
            // RepositoryProvider satisfies the same way Provider would.
            return MultiRepositoryProvider(
              providers: [
                RepositoryProvider<OutboxRepository>.value(
                  value: sl<OutboxRepository>(),
                ),
                RepositoryProvider<VisitFinishOrchestrator>.value(
                  value: sl<VisitFinishOrchestrator>(),
                ),
              ],
              child: BlocProvider<OutboxStatusCubit>.value(
                value: sl<OutboxStatusCubit>()..refresh(),
                child: const DeadLetterPage(),
              ),
            );
          },
          settings: settings,
        );
      case visitsHistoryRoute:
        // Argument support: pass a `customer_id` string to pre-filter
        // the list to a single trading point. No arguments = full
        // history across the caller's customers.
        final args = settings.arguments;
        final customerId = args is Map ? args['customer_id'] as String? : null;
        return MaterialPageRoute(
          builder: (_) => VisitListPage(customerId: customerId),
          settings: settings,
        );
      case visitsDetailRoute:
        final args = settings.arguments;
        final visitId = args is Map ? args['visit_id'] as String? : null;
        if (visitId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('visit_id argumenti yetishmadi')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => VisitDetailPage(visitId: visitId),
          settings: settings,
        );
      case ordersRoute:
        return MaterialPageRoute(builder: (_) => const OrdersPage());
      case dbViewRoute:
        return MaterialPageRoute(builder: (_) => const DbViewPage());
      case faqRoute:
        // Backward compat: legacy /faq deep links land on the new
        // Knowledge Base home, scoped to the regulation category.
        return MaterialPageRoute(
          builder: (_) =>
              const KnowledgeHomePage(initialCategorySlug: 'reglament'),
        );
      case knowledgeRoute:
        return MaterialPageRoute(builder: (_) => const KnowledgeHomePage());
      case knowledgeCategoryRoute:
        final args = settings.arguments;
        final id = args is Map ? args['id'] as String? : null;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Category id is required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => KnowledgeCategoryPage(categoryId: id),
        );
      case knowledgeDocumentRoute:
        final args = settings.arguments;
        final id = args is Map ? args['id'] as String? : null;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Document id is required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => KnowledgeDocumentPage(documentId: id),
        );
      case knowledgeSearchRoute:
        return MaterialPageRoute(
          builder: (_) => const KnowledgeSearchPage(),
        );
      case notificationListRoute:
        return MaterialPageRoute(builder: (_) => const NotificationListPage());
      case notificationDetailRoute:
        final args = settings.arguments;
        final id = args is Map ? args['id'] as String? : null;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Notification id is required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => NotificationDetailPage(id: id),
        );
      case notificationPreferencesRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationPreferencesPage(),
        );
      case projectPickerRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final mandatory = args?['mandatory'] == true;
        return MaterialPageRoute(
          builder: (_) => ProjectPickerPage(mandatory: mandatory),
          fullscreenDialog: mandatory,
        );
      case versionGateRoute:
        final payload = settings.arguments;
        if (payload is VersionGateResponse) {
          return MaterialPageRoute(
            builder: (_) => VersionGateScreen(payload: payload),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('VersionGateResponse argument required')),
          ),
        );
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