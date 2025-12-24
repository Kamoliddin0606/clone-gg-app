import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/models/data_sync_table.dart';
import 'package:gloria_marketing_flutter/src/core/models/data_sync_group.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';

/// Ultra-comprehensive configuration for all syncable tables and groups in the application.
/// 
/// This configuration covers EVERY table identified in the database schema (35+ tables).
/// It handles bundled syncs, complex dependencies, and server-specific availability.
class DataSyncConfig {
  DataSyncConfig._();

  static final Map<String, DataSyncTable> _tables = {};
  static final Map<String, DataSyncGroup> _groups = {};
  static bool _isInitialized = false;

  /// Initialize configuration with sync service and user credentials
  static void initialize(
    DataSyncService ds,
    String userCode,
    String password,
    String codeProject,
    String codeSklad,
  ) {
    if (_isInitialized) return;
    _initializeTables(ds, userCode, password, codeProject, codeSklad);
    _initializeGroups();
    _isInitialized = true;
  }

  static void _initializeTables(
    DataSyncService ds,
    String userCode,
    String password,
    String codeProject,
    String codeSklad,
  ) {
    _tables.clear();

    // =========================================================================
    // GROUP: USER DATA (Account & Access)
    // =========================================================================

    _tables['user_warehouses'] = DataSyncTable(
      id: 'user_warehouses',
      tableName: 'user_warehouses',
      nameEn: 'Warehouses',
      nameRu: 'Склады',
      nameUz: 'Omborlar',
      icon: Icons.warehouse,
      dependsOn: [],
      cascadeTo: ['products', 'product_balances'],
      groupId: 'user_data',
      syncFunction: () => ds.syncUserWarehouses(userCode: userCode, forceRefresh: true),
    );

    _tables['user_organizations'] = DataSyncTable(
      id: 'user_organizations',
      tableName: 'user_organizations',
      nameEn: 'Organizations',
      nameRu: 'Организации',
      nameUz: 'Tashkilotlar',
      icon: Icons.business,
      dependsOn: [],
      cascadeTo: [],
      groupId: 'user_data',
      syncFunction: () => ds.syncUserOrganizations(userCode: userCode, forceRefresh: true),
    );

    _tables['sales_req_permissions'] = DataSyncTable(
      id: 'sales_req_permissions',
      tableName: 'sales_req_permissions',
      nameEn: 'Agent Permissions',
      nameRu: 'Разрешения агента',
      nameUz: 'Agent ruxsatlari',
      icon: Icons.security,
      dependsOn: [],
      cascadeTo: ['visit_steps', 'visit_steps_data'],
      groupId: 'user_data',
      syncFunction: () => ds.syncSalesReqPermissions(userCode: userCode, forceRefresh: true),
    );

    _tables['visit_steps'] = DataSyncTable(
      id: 'visit_steps',
      tableName: 'visit_steps',
      nameEn: 'Visit Steps',
      nameRu: 'Шаги визита',
      nameUz: 'Tashrif bosqichlari',
      icon: Icons.checklist,
      dependsOn: ['sales_req_permissions'],
      cascadeTo: [],
      groupId: 'user_data',
      syncFunction: () => ds.syncVisitSteps(userCode: userCode, forceRefresh: true),
    );

    _tables['visit_steps_data'] = DataSyncTable(
      id: 'visit_steps_data',
      tableName: 'visit_steps_data',
      nameEn: 'Visit Step Data',
      nameRu: 'Данные шагов визита',
      nameUz: 'Tashrif qadamlari ma\'lumotlari',
      icon: Icons.data_usage,
      dependsOn: ['sales_req_permissions'],
      cascadeTo: [],
      groupId: 'user_data',
      syncFunction: () => ds.syncVisitSteps(userCode: userCode, forceRefresh: true),
    );

    // =========================================================================
    // GROUP: GEOGRAPHY (Geography & Routes)
    // =========================================================================

    _tables['business_regions'] = DataSyncTable(
      id: 'business_regions',
      tableName: 'business_regions',
      nameEn: 'Business Regions',
      nameRu: 'Бизнес-регионы',
      nameUz: 'Biznes hududlari',
      icon: Icons.location_on,
      dependsOn: [],
      cascadeTo: ['clients', 'planned_routes'],
      groupId: 'regions',
      syncFunction: () => ds.syncBusinessRegions(userCode: userCode, forceRefresh: true),
    );

    _tables['planned_routes'] = DataSyncTable(
      id: 'planned_routes',
      tableName: 'planned_routes',
      nameEn: 'Planned Routes',
      nameRu: 'Маршруты',
      nameUz: 'Marshrutlar',
      icon: Icons.route,
      dependsOn: ['business_regions'],
      cascadeTo: [],
      groupId: 'regions',
      syncFunction: () => ds.syncPlannedRoutes(userCode: userCode, forceRefresh: true),
    );

    // =========================================================================
    // GROUP: PRODUCT CATALOG (Inventory & Brands)
    // =========================================================================

    _tables['products'] = DataSyncTable(
      id: 'products',
      tableName: 'products',
      nameEn: 'Products',
      nameRu: 'Продукты',
      nameUz: 'Mahsulotlar',
      icon: Icons.inventory,
      dependsOn: ['user_warehouses'],
      cascadeTo: ['product_prices', 'product_balances', 'promotions', 'order_details'],
      groupId: 'product_catalog',
      syncFunction: () => ds.syncProducts(codeProject: codeProject, codeSklad: codeSklad, forceRefresh: true),
    );

    _tables['product_balances'] = DataSyncTable(
      id: 'product_balances',
      tableName: 'product_balances',
      nameEn: 'Product Balances',
      nameRu: 'Остатки',
      nameUz: 'Qoldiqlar',
      icon: Icons.balance,
      dependsOn: ['user_warehouses', 'products'],
      cascadeTo: ['product_brands', 'product_series'],
      groupId: 'product_catalog',
      syncFunction: () => ds.syncProductBalances(codeProject: codeProject, codeSklad: codeSklad, forceRefresh: true),
    );

    _tables['product_brands'] = DataSyncTable(
      id: 'product_brands',
      tableName: 'product_brands',
      nameEn: 'Product Brands',
      nameRu: 'Бренды',
      nameUz: 'Brendlar',
      icon: Icons.branding_watermark,
      dependsOn: ['product_balances'],
      cascadeTo: [],
      groupId: 'product_catalog',
      syncFunction: () => ds.syncProductBalances(codeProject: codeProject, codeSklad: codeSklad, forceRefresh: true),
    );

    _tables['product_series'] = DataSyncTable(
      id: 'product_series',
      tableName: 'product_series',
      nameEn: 'Product Series',
      nameRu: 'Серии',
      nameUz: 'Seriyalar',
      icon: Icons.low_priority,
      dependsOn: ['product_balances'],
      cascadeTo: [],
      groupId: 'product_catalog',
      syncFunction: () => ds.syncProductBalances(codeProject: codeProject, codeSklad: codeSklad, forceRefresh: true),
    );

    // =========================================================================
    // GROUP: PRICES (Types & Values)
    // =========================================================================

    _tables['price_types'] = DataSyncTable(
      id: 'price_types',
      tableName: 'price_types',
      nameEn: 'Price Types',
      nameRu: 'Типы цен',
      nameUz: 'Narx turlari',
      icon: Icons.price_change,
      dependsOn: [],
      cascadeTo: ['product_prices'],
      groupId: 'prices',
      syncFunction: () => ds.syncPriceTypes(userCode: userCode, forceRefresh: true),
    );

    _tables['product_prices'] = DataSyncTable(
      id: 'product_prices',
      tableName: 'product_prices',
      nameEn: 'Product Prices',
      nameRu: 'Цены',
      nameUz: 'Narxlar',
      icon: Icons.attach_money,
      dependsOn: ['products', 'price_types'],
      cascadeTo: [],
      groupId: 'prices',
      syncFunction: () => ds.syncProductPrices(userCode: userCode, forceRefresh: true),
    );

    // =========================================================================
    // GROUP: CLIENTS (CRM & Contracts)
    // =========================================================================

    _tables['clients'] = DataSyncTable(
      id: 'clients',
      tableName: 'clients',
      nameEn: 'Clients',
      nameRu: 'Клиенты',
      nameUz: 'Mijozlar',
      icon: Icons.people,
      dependsOn: ['business_regions'],
      cascadeTo: ['client_contracts', 'client_images', 'orders'],
      groupId: 'clients',
      syncFunction: () => ds.syncClients(userCode: userCode, password: password, forceRefresh: true),
    );

    _tables['client_contracts'] = DataSyncTable(
      id: 'client_contracts',
      tableName: 'client_contracts',
      nameEn: 'Client Contracts',
      nameRu: 'Контракты',
      nameUz: 'Shartnomalar',
      icon: Icons.description,
      dependsOn: ['clients'],
      cascadeTo: [],
      groupId: 'clients',
      syncFunction: () async {
        await ds.syncClientContracts(userCode: userCode, forceRefresh: true);
        await ds.updateClientsHasContractField(); // Post-processing
      },
    );

    _tables['client_images'] = DataSyncTable(
      id: 'client_images',
      tableName: 'client_images',
      nameEn: 'Client Images',
      nameRu: 'Фото клиентов',
      nameUz: 'Mijozlar rasmlari',
      icon: Icons.image,
      dependsOn: ['clients'],
      cascadeTo: [],
      groupId: 'clients',
      syncFunction: () => Future.value(), // Usually on-demand or background
    );

    // =========================================================================
    // GROUP: ORDERS (Logistics & Processing)
    // =========================================================================

    _tables['order_statuses'] = DataSyncTable(
      id: 'order_statuses',
      tableName: 'order_statuses',
      nameEn: 'Order Statuses',
      nameRu: 'Статусы заказов',
      nameUz: 'Buyurtma statuslari',
      icon: Icons.list_alt,
      dependsOn: [],
      cascadeTo: ['orders'],
      groupId: 'orders',
      syncFunction: () => ds.syncOrderStatuses(userCode: userCode, forceRefresh: true),
    );

    _tables['orders'] = DataSyncTable(
      id: 'orders',
      tableName: 'orders',
      nameEn: 'Orders',
      nameRu: 'Заказы',
      nameUz: 'Buyurtmalar',
      icon: Icons.shopping_cart,
      dependsOn: ['clients', 'products', 'order_statuses'],
      cascadeTo: ['couriers', 'courier_cars', 'order_couriers', 'order_details', 'kpi_data'],
      groupId: 'orders',
      syncFunction: () => ds.syncOrders(userCode: userCode, forceRefresh: true),
    );

    _tables['order_details'] = DataSyncTable(
      id: 'order_details',
      tableName: 'order_details',
      nameEn: 'Order Details',
      nameRu: 'Детали заказов',
      nameUz: 'Buyurtma tafsilotlari',
      icon: Icons.info,
      dependsOn: ['orders', 'products'],
      cascadeTo: ['order_detail_products', 'order_payments'],
      groupId: 'orders',
      syncFunction: () => Future.value(), // On-demand only
    );

    _tables['order_detail_products'] = DataSyncTable(
      id: 'order_detail_products',
      tableName: 'order_detail_products',
      nameEn: 'Order Products',
      nameRu: 'Товары в заказах',
      nameUz: 'Buyurtmadagi mahsulotlar',
      icon: Icons.shopping_bag,
      dependsOn: ['order_details'],
      cascadeTo: [],
      groupId: 'orders',
      syncFunction: () => Future.value(), // On-demand only
    );

    _tables['order_payments'] = DataSyncTable(
      id: 'order_payments',
      tableName: 'order_payments',
      nameEn: 'Order Payments',
      nameRu: 'Оплаты заказов',
      nameUz: 'Buyurtma to\'lovlari',
      icon: Icons.payment,
      dependsOn: ['order_details'],
      cascadeTo: [],
      groupId: 'orders',
      syncFunction: () => Future.value(), // On-demand only
    );

    _tables['couriers'] = DataSyncTable(
      id: 'couriers',
      tableName: 'couriers',
      nameEn: 'Couriers',
      nameRu: 'Курьеры',
      nameUz: 'Kuryerlar',
      icon: Icons.delivery_dining,
      dependsOn: ['orders'],
      cascadeTo: [],
      groupId: 'orders',
      syncFunction: () => ds.syncOrders(userCode: userCode, forceRefresh: true),
    );

    _tables['courier_cars'] = DataSyncTable(
      id: 'courier_cars',
      tableName: 'courier_cars',
      nameEn: 'Courier Cars',
      nameRu: 'Машины курьеров',
      nameUz: 'Kuryer mashinalari',
      icon: Icons.directions_car,
      dependsOn: ['orders'],
      cascadeTo: [],
      groupId: 'orders',
      syncFunction: () => ds.syncOrders(userCode: userCode, forceRefresh: true),
    );

    _tables['order_couriers'] = DataSyncTable(
      id: 'order_couriers',
      tableName: 'order_couriers',
      nameEn: 'Order-Courier Mapping',
      nameRu: 'Привязка курьеров',
      nameUz: 'Kuryer biriktirilishi',
      icon: Icons.link,
      dependsOn: ['orders', 'couriers'],
      cascadeTo: [],
      groupId: 'orders',
      syncFunction: () => ds.syncOrders(userCode: userCode, forceRefresh: true),
    );

    _tables['create_order'] = DataSyncTable(
      id: 'create_order',
      tableName: 'create_order',
      nameEn: 'Local Orders',
      nameRu: 'Локальные заказы',
      nameUz: 'Lokal buyurtmalar',
      icon: Icons.upload_file,
      dependsOn: [],
      cascadeTo: [],
      groupId: 'orders',
      syncFunction: () => ds.syncCreateOrders(),
    );

    // =========================================================================
    // GROUP: PROMOTIONS (Aksiyalar)
    // =========================================================================

    _tables['promotions'] = DataSyncTable(
      id: 'promotions',
      tableName: 'promotions',
      nameEn: 'Promotions',
      nameRu: 'Акции',
      nameUz: 'Aksiyalar',
      icon: Icons.local_offer,
      dependsOn: ['products'],
      cascadeTo: ['promotion_product_list', 'promotion_bonus_list', 'promotion_class_list'],
      groupId: 'promotions',
      syncFunction: () => ds.syncPromotions(authToken: null, forceRefresh: true),
    );

    _tables['promotion_product_list'] = DataSyncTable(
      id: 'promotion_product_list',
      tableName: 'promotion_product_list',
      nameEn: 'Promotion Products',
      nameRu: 'Товары акций',
      nameUz: 'Aksiya mahsulotlari',
      icon: Icons.list_alt,
      dependsOn: ['promotions'],
      cascadeTo: [],
      groupId: 'promotions',
      syncFunction: () => ds.syncPromotions(authToken: null, forceRefresh: true),
    );

    _tables['promotion_bonus_list'] = DataSyncTable(
      id: 'promotion_bonus_list',
      tableName: 'promotion_bonus_list',
      nameEn: 'Promotion Bonuses',
      nameRu: 'Бонусы акций',
      nameUz: 'Aksiya bonuslari',
      icon: Icons.card_giftcard,
      dependsOn: ['promotions'],
      cascadeTo: [],
      groupId: 'promotions',
      syncFunction: () => ds.syncPromotions(authToken: null, forceRefresh: true),
    );

    _tables['promotion_class_list'] = DataSyncTable(
      id: 'promotion_class_list',
      tableName: 'promotion_class_list',
      nameEn: 'Promotion Classes',
      nameRu: 'Классы акций',
      nameUz: 'Aksiya klasslari',
      icon: Icons.class_outlined,
      dependsOn: ['promotions'],
      cascadeTo: [],
      groupId: 'promotions',
      syncFunction: () => ds.syncPromotions(authToken: null, forceRefresh: true),
    );

    // =========================================================================
    // GROUP: ANALYTICS (KPI & Reports)
    // =========================================================================

    _tables['kpi_data'] = DataSyncTable(
      id: 'kpi_data',
      tableName: 'kpi_data',
      nameEn: 'KPI Analytics',
      nameRu: 'KPI аналитика',
      nameUz: 'KPI analitika',
      icon: Icons.bar_chart,
      dependsOn: ['orders'],
      cascadeTo: [],
      groupId: 'analytics',
      syncFunction: () => ds.syncKpiData(userCode: userCode, password: password, forceRefresh: true),
    );

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
    final endOfMonth = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

    _tables['main_reports'] = DataSyncTable(
      id: 'main_reports',
      tableName: 'main_reports',
      nameEn: 'Sales Reports',
      nameRu: 'Отчеты по продажам',
      nameUz: 'Sotuv hisobotlari',
      icon: Icons.summarize,
      dependsOn: [],
      cascadeTo: ['business_region_reports', 'akb_by_categories', 'visit_plans'],
      groupId: 'analytics',
      syncFunction: () => ds.syncReportByPeriod(userCode: userCode, dateStart: startOfMonth, dateEnd: endOfMonth, forceRefresh: true),
    );

    _tables['business_region_reports'] = DataSyncTable(
      id: 'business_region_reports',
      tableName: 'business_region_reports',
      nameEn: 'Regional Reports',
      nameRu: 'Региональные отчеты',
      nameUz: 'Hududiy hisobotlar',
      icon: Icons.map_outlined,
      dependsOn: ['main_reports'],
      cascadeTo: [],
      groupId: 'analytics',
      syncFunction: () => ds.syncReportByPeriod(userCode: userCode, dateStart: startOfMonth, dateEnd: endOfMonth, forceRefresh: true),
    );

    _tables['akb_by_categories'] = DataSyncTable(
      id: 'akb_by_categories',
      tableName: 'akb_by_categories',
      nameEn: 'AKB by Categories',
      nameRu: 'АКБ по категориям',
      nameUz: 'AKB kategoriyalar bo\'yicha',
      icon: Icons.category,
      dependsOn: ['main_reports'],
      cascadeTo: [],
      groupId: 'analytics',
      syncFunction: () => ds.syncReportByPeriod(userCode: userCode, dateStart: startOfMonth, dateEnd: endOfMonth, forceRefresh: true),
    );

    _tables['visit_plans'] = DataSyncTable(
      id: 'visit_plans',
      tableName: 'visit_plans',
      nameEn: 'Visit Plans',
      nameRu: 'Планы визитов',
      nameUz: 'Tashrif rejalari',
      icon: Icons.event_available,
      dependsOn: ['main_reports'],
      cascadeTo: ['visit_plan_lists'],
      groupId: 'analytics',
      syncFunction: () => Future.value(), // Local only, or implicitly via reports
    );

    _tables['visit_plan_lists'] = DataSyncTable(
      id: 'visit_plan_lists',
      tableName: 'visit_plan_lists',
      nameEn: 'Visit Lists',
      nameRu: 'Списки визитов',
      nameUz: 'Tashrif ro\'yxatlari',
      icon: Icons.playlist_add_check,
      dependsOn: ['visit_plans'],
      cascadeTo: [],
      groupId: 'analytics',
      syncFunction: () => Future.value(), // Local only
    );

    // =========================================================================
    // GROUP: SYSTEM (Settings & Infrastructure)
    // =========================================================================

    _tables['map_tokens'] = DataSyncTable(
      id: 'map_tokens',
      tableName: 'map_tokens',
      nameEn: 'Map Tokens',
      nameRu: 'Токены карт',
      nameUz: 'Xarita tokenlari',
      icon: Icons.vpn_key,
      dependsOn: [],
      cascadeTo: [],
      groupId: 'system',
      syncFunction: () => ds.syncMapTokens(),
    );
  }

  static void _initializeGroups() {
    _groups.clear();

    _groups['user_data'] = const DataSyncGroup(
      id: 'user_data',
      nameEn: 'Account & Access',
      nameRu: 'Аккаунт и доступ',
      nameUz: 'Akkount va kirish',
      icon: Icons.account_circle,
      tableIds: ['user_warehouses', 'user_organizations', 'sales_req_permissions', 'visit_steps', 'visit_steps_data'],
      color: Colors.blue,
    );

    _groups['regions'] = const DataSyncGroup(
      id: 'regions',
      nameEn: 'Geography & Routes',
      nameRu: 'География и маршруты',
      nameUz: 'Geografiya va marshrutlar',
      icon: Icons.location_on,
      tableIds: ['business_regions', 'planned_routes'],
      color: Colors.green,
    );

    _groups['product_catalog'] = const DataSyncGroup(
      id: 'product_catalog',
      nameEn: 'Product Catalog',
      nameRu: 'Каталог товаров',
      nameUz: 'Mahsulotlar katalogi',
      icon: Icons.inventory_2,
      tableIds: ['products', 'product_balances', 'product_brands', 'product_series'],
      color: Colors.orange,
    );

    _groups['prices'] = const DataSyncGroup(
      id: 'prices',
      nameEn: 'Pricing',
      nameRu: 'Цены',
      nameUz: 'Narxlar',
      icon: Icons.payments,
      tableIds: ['price_types', 'product_prices'],
      color: Colors.teal,
    );

    _groups['clients'] = const DataSyncGroup(
      id: 'clients',
      nameEn: 'Clients & CRM',
      nameRu: 'Клиенты и CRM',
      nameUz: 'Mijozlar va CRM',
      icon: Icons.groups,
      tableIds: ['clients', 'client_contracts', 'client_images'],
      color: Colors.purple,
    );

    _groups['orders'] = const DataSyncGroup(
      id: 'orders',
      nameEn: 'Orders & Logistics',
      nameRu: 'Заказы и логистика',
      nameUz: 'Buyurtmalar va lojistika',
      icon: Icons.receipt_long,
      tableIds: [
        'order_statuses', 'orders', 'order_details', 'order_detail_products', 
        'order_payments', 'couriers', 'courier_cars', 'order_couriers', 'create_order'
      ],
      color: Colors.indigo,
    );

    _groups['promotions'] = const DataSyncGroup(
      id: 'promotions',
      nameEn: 'Promotions',
      nameRu: 'Акции и скидки',
      nameUz: 'Aksiyalar va chegirmalar',
      icon: Icons.sell,
      tableIds: ['promotions', 'promotion_product_list', 'promotion_bonus_list', 'promotion_class_list'],
      color: Colors.red,
    );

    _groups['analytics'] = const DataSyncGroup(
      id: 'analytics',
      nameEn: 'Performance & Reports',
      nameRu: 'Эффективность и отчеты',
      nameUz: 'Samaradorlik va hisobotlar',
      icon: Icons.analytics,
      tableIds: ['kpi_data', 'main_reports', 'business_region_reports', 'akb_by_categories', 'visit_plans', 'visit_plan_lists'],
      color: Colors.amber,
    );

    _groups['system'] = const DataSyncGroup(
      id: 'system',
      nameEn: 'System Settings',
      nameRu: 'Системные настройки',
      nameUz: 'Tizim sozlamalari',
      icon: Icons.settings,
      tableIds: ['map_tokens'],
      color: Colors.grey,
    );
  }

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  static List<DataSyncTable> getAllTables() {
    _checkInitialized();
    return _tables.values.toList();
  }

  static List<DataSyncGroup> getAllGroups() {
    _checkInitialized();
    return _groups.values.toList();
  }

  static DataSyncTable? getTable(String tableId) {
    _checkInitialized();
    return _tables[tableId];
  }

  static DataSyncGroup? getGroup(String groupId) {
    _checkInitialized();
    return _groups[groupId];
  }

  static List<DataSyncTable> getTablesInGroup(String groupId) {
    _checkInitialized();
    final group = _groups[groupId];
    if (group == null) return [];

    return group.tableIds
        .map((id) => _tables[id])
        .where((table) => table != null)
        .cast<DataSyncTable>()
        .toList();
  }

  static List<String> getDependencyTree(String tableId) {
    _checkInitialized();
    final table = _tables[tableId];
    if (table == null) return [];

    final result = <String>[];
    final visited = <String>{};

    void visit(String id) {
      if (visited.contains(id)) return;
      visited.add(id);

      final t = _tables[id];
      if (t == null) return;

      for (final depId in t.dependsOn) {
        visit(depId);
      }

      result.add(id);
    }

    visit(tableId);
    return result;
  }

  static List<String> getCascadeTree(String tableId) {
    _checkInitialized();
    final result = <String>[];
    final visited = <String>{};

    void visit(String id) {
      final table = _tables[id];
      if (table == null) return;

      for (final childId in table.cascadeTo) {
        if (visited.contains(childId)) continue;
        visited.add(childId);

        result.add(childId);
        visit(childId);
      }
    }

    visit(tableId);
    return result;
  }

  static void validateDependencyGraph() {
    _checkInitialized();
    for (final table in _tables.values) {
      final visited = <String>{};

      bool hasCycle(String currentId) {
        if (visited.contains(currentId)) return true;
        visited.add(currentId);

        final current = _tables[currentId];
        if (current == null) return false;

        for (final depId in current.dependsOn) {
          if (hasCycle(depId)) return true;
        }

        visited.remove(currentId);
        return false;
      }

      if (hasCycle(table.id)) {
        throw StateError(
          'Circular dependency detected in sync configuration for table: ${table.id}',
        );
      }
    }
  }

  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'DataSyncConfig not initialized. Call DataSyncConfig.initialize() first.',
      );
    }
  }
}
