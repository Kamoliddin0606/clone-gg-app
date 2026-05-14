import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_organization.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_brand.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_series.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan_list.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_detail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/planned_route.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/contract_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/district_contracting.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_channel.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_class.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';

class ApiDatabaseService {
  static final ApiDatabaseService _instance = ApiDatabaseService._internal();
  static Database? _database;

  ApiDatabaseService._internal();

  factory ApiDatabaseService() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with version 29
  /// Database schema initialization
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gloria_api_cache.db');

    return await openDatabase(
      path,
      version: 41, // v41: user_projects.id_uuid + id_1c added for customer_scope=project header (X-Project-Id) resolution
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);

    // Ensure visit_steps_data table exists for fresh installations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_steps_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visit_id TEXT NOT NULL,
        client_code TEXT NOT NULL,
        step_code INTEGER NOT NULL,
        step_name TEXT NOT NULL,
        data_type TEXT NOT NULL,
        data_content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT,
        sync_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for visit_steps_data table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_visit_id ON visit_steps_data(visit_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_client_code ON visit_steps_data(client_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_step_code ON visit_steps_data(step_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_data_type ON visit_steps_data(data_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_is_synced ON visit_steps_data(is_synced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_timestamp ON visit_steps_data(timestamp)',
    );

    // Ensure user_projects table exists for fresh installations
    // Таблица проектов пользователя / Foydalanuvchi loyihalari jadvali
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        user_code TEXT NOT NULL,
        id_uuid TEXT,
        id_1c TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(code, user_code)
      )
    ''');

    // Create indexes for user_projects table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_projects_code ON user_projects(code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_projects_user_code ON user_projects(user_code)',
    );

    // Ensure user_organizations table exists for fresh installations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_organizations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        user_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for user_organizations table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_organizations_code ON user_organizations(code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_organizations_user_code ON user_organizations(user_code)',
    );

    // Ensure map_tokens table exists for fresh installations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS map_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        yandex_token TEXT,
        google_token TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Knowledge Base tables (v37). The same DDL runs from the v37
    // upgrade branch — keep both copies in sync if columns change.
    await _createKnowledgeBaseTables(db);
  }

  /// CREATE TABLE statements for the Knowledge Base feature (v37).
  ///
  /// Called from both [_onCreate] (fresh installs) and the
  /// `oldVersion < 37` branch of [_onUpgrade] (upgrades from v36 or
  /// earlier). Idempotent — every statement uses IF NOT EXISTS.
  Future<void> _createKnowledgeBaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_categories (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        parent_id TEXT,
        slug TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        color TEXT,
        cover_media_id TEXT,
        order_idx INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_cat_org_parent ON knowledge_categories(organization_id, parent_id, order_idx)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_documents (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        slug TEXT,
        doc_type TEXT,
        status TEXT,
        is_pinned INTEGER DEFAULT 0,
        cover_media_id TEXT,
        published_at INTEGER,
        expires_at INTEGER,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_doc_org_cat ON knowledge_documents(organization_id, category_id, status, published_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_doc_pinned ON knowledge_documents(organization_id, is_pinned, published_at DESC)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_document_translations (
        document_id TEXT NOT NULL,
        language TEXT NOT NULL,
        title TEXT,
        summary TEXT,
        PRIMARY KEY(document_id, language)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_sections (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        parent_id TEXT,
        anchor TEXT,
        title_i18n_json TEXT,
        order_idx INTEGER,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_sec_doc ON knowledge_sections(document_id, parent_id, order_idx)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_content_blocks (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        section_id TEXT NOT NULL,
        order_idx INTEGER,
        block_type TEXT,
        data_json TEXT,
        media_id TEXT,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_block_sec ON knowledge_content_blocks(section_id, order_idx)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_media (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        kind TEXT,
        mime_type TEXT,
        size_bytes INTEGER,
        small_url TEXT,
        medium_url TEXT,
        large_url TEXT,
        blurhash TEXT,
        width INTEGER,
        height INTEGER,
        storage_key TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_assignments (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        target_type TEXT,
        target_role_id TEXT,
        target_user_id TEXT,
        target_staff_id TEXT,
        target_branch_id TEXT,
        target_territory_id TEXT,
        mandatory INTEGER,
        due_at INTEGER,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_asg_doc ON knowledge_assignments(document_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kn_asg_staff ON knowledge_assignments(target_staff_id)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_tags (
        id TEXT PRIMARY KEY,
        organization_id TEXT NOT NULL,
        slug TEXT,
        name TEXT,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_document_tags (
        document_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY(document_id, tag_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_sync_state (
        resource_name TEXT PRIMARY KEY,
        last_synced_at INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old tables and recreate with new structure
      await db.execute('DROP TABLE IF EXISTS kpi_data');
      await db.execute('DROP TABLE IF EXISTS clients');
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS price_types');
      await db.execute('DROP TABLE IF EXISTS product_prices');
      await _createTables(db);
    } else if (oldVersion < 3) {
      // Add promotions tables for version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          min_promo_product_count INTEGER NOT NULL,
          bonus_count INTEGER NOT NULL,
          date_start TEXT NOT NULL,
          date_end TEXT NOT NULL,
          last_synced TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create promotion product list table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotion_product_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_code TEXT NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
          UNIQUE(promotion_code, product_code)
        )
      ''');

      // Create promotion bonus list table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotion_bonus_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_code TEXT NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
          UNIQUE(promotion_code, product_code)
        )
      ''');

      // Create promotion class list table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotion_class_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_code TEXT NOT NULL,
          class_code TEXT NOT NULL,
          class_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
          UNIQUE(promotion_code, class_code)
        )
      ''');

      await db.execute('CREATE INDEX idx_promotions_code ON promotions(code)');
      await db.execute(
        'CREATE INDEX idx_promotions_active ON promotions(is_active)',
      );
      await db.execute(
        'CREATE INDEX idx_promotions_date_range ON promotions(date_start, date_end)',
      );
      await db.execute(
        'CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)',
      );
      await db.execute(
        'CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)',
      );
      await db.execute(
        'CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)',
      );
    } else if (oldVersion < 4) {
      // Migrate from old promotion_products table to separate tables
      // First, create the new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotion_product_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_code TEXT NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
          UNIQUE(promotion_code, product_code)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotion_bonus_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_code TEXT NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
          UNIQUE(promotion_code, product_code)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotion_class_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_code TEXT NOT NULL,
          class_code TEXT NOT NULL,
          class_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
          UNIQUE(promotion_code, class_code)
        )
      ''');

      // Migrate data from old table
      final oldProducts = await db.query('promotion_products');
      for (final product in oldProducts) {
        final table = product['product_type'] == 'product'
            ? 'promotion_product_list'
            : 'promotion_bonus_list';
        await db.insert(table, {
          'promotion_code': product['promotion_code'],
          'product_code': product['product_code'],
          'product_name': product['product_name'],
          'created_at': product['created_at'],
        });
      }

      // Drop old table
      await db.execute('DROP TABLE promotion_products');

      // Create indexes
      await db.execute(
        'CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)',
      );
      await db.execute(
        'CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)',
      );
      await db.execute(
        'CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)',
      );
    } else if (oldVersion < 5) {
      // Add business regions table for version 5
      await db.execute('''
        CREATE TABLE IF NOT EXISTS business_regions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Add foreign key constraint to clients table
      await db.execute('''
        CREATE INDEX idx_clients_code_region ON clients(code_region)
      ''');
    } else if (oldVersion < 6) {
      // Add user warehouses table for version 6
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_warehouses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          organization TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    } else if (oldVersion < 7) {
      // Add product balance, brands, and series tables for version 7
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_brands (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_series (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          brand_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (brand_name) REFERENCES product_brands (name) ON DELETE CASCADE,
          UNIQUE(name, brand_name)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_balances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_sklad TEXT NOT NULL,
          code_product TEXT NOT NULL,
          name_product TEXT NOT NULL,
          have INTEGER NOT NULL,
          reserved INTEGER NOT NULL,
          available INTEGER NOT NULL,
          weight REAL NOT NULL,
          capacity REAL NOT NULL,
          code_project TEXT NOT NULL,
          vendor_code TEXT NOT NULL,
          product_brand TEXT NOT NULL,
          product_series TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (code_sklad) REFERENCES user_warehouses (code) ON DELETE CASCADE,
          FOREIGN KEY (code_product) REFERENCES products (code) ON DELETE CASCADE,
          FOREIGN KEY (product_brand) REFERENCES product_brands (name) ON DELETE CASCADE,
          UNIQUE(code_sklad, code_product)
        )
      ''');

      // Create indexes for better performance
      await db.execute(
        'CREATE INDEX idx_product_balances_code_sklad ON product_balances(code_sklad)',
      );
      await db.execute(
        'CREATE INDEX idx_product_balances_code_product ON product_balances(code_product)',
      );
      await db.execute(
        'CREATE INDEX idx_product_balances_product_brand ON product_balances(product_brand)',
      );
      await db.execute(
        'CREATE INDEX idx_product_balances_product_series ON product_balances(product_series)',
      );
      await db.execute(
        'CREATE INDEX idx_product_series_brand_name ON product_series(brand_name)',
      );
    } else if (oldVersion < 8) {
      // Add foreign key constraints for version 8
      // Since this is a cache database that gets cleared and reloaded,
      // the FK constraints will be applied when tables are recreated
      // No specific migration needed as data is refreshed from server
    } else if (oldVersion < 9) {
      // Add client contracts table for version 9
      await db.execute('''
        CREATE TABLE IF NOT EXISTS client_contracts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_contract TEXT UNIQUE NOT NULL,
          date_of_contract TEXT,
          sum_of_contract REAL NOT NULL,
          term_of_contract TEXT,
          type_contract TEXT,
          numb_reference TEXT,
          numb_certificate TEXT,
          term_reference TEXT,
          term_certificate TEXT,
          numb_passport TEXT,
          term_passport TEXT,
          certificate_unlimited INTEGER NOT NULL,
          code_district TEXT,
          name_district TEXT,
          code_project TEXT,
          code_client TEXT NOT NULL,
          active INTEGER NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (code_client) REFERENCES clients (code) ON DELETE CASCADE
        )
      ''');

      // Create indexes for better performance
      await db.execute(
        'CREATE INDEX idx_client_contracts_code_contract ON client_contracts(code_contract)',
      );
      await db.execute(
        'CREATE INDEX idx_client_contracts_code_client ON client_contracts(code_client)',
      );
      await db.execute(
        'CREATE INDEX idx_client_contracts_active ON client_contracts(active)',
      );
      await db.execute(
        'CREATE INDEX idx_client_contracts_status ON client_contracts(status)',
      );
    } else if (oldVersion < 10) {
      // Add report tables for version 10
      await db.execute('''
        CREATE TABLE main_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_code TEXT NOT NULL,
          date_start TEXT NOT NULL,
          date_end TEXT NOT NULL,
          count_akb INTEGER NOT NULL,
          count_okb INTEGER NOT NULL,
          cash REAL NOT NULL,
          transfer REAL NOT NULL,
          sum REAL NOT NULL,
          count_visited INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE business_region_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          main_report_id INTEGER NOT NULL,
          code TEXT NOT NULL,
          name TEXT NOT NULL,
          akb INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE akb_by_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          main_report_id INTEGER NOT NULL,
          code TEXT NOT NULL,
          name TEXT NOT NULL,
          akb INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE visit_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          main_report_id INTEGER NOT NULL,
          client_code TEXT NOT NULL,
          client_name TEXT NOT NULL,
          planned_date TEXT NOT NULL,
          actual_visit_date TEXT,
          is_completed INTEGER DEFAULT 0,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE visit_plan_lists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_plan_id INTEGER NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          planned_quantity INTEGER NOT NULL,
          actual_quantity INTEGER,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (visit_plan_id) REFERENCES visit_plans (id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for better performance
      await db.execute(
        'CREATE INDEX idx_main_reports_user_code ON main_reports(user_code)',
      );
      await db.execute(
        'CREATE INDEX idx_main_reports_date_range ON main_reports(date_start, date_end)',
      );
      await db.execute(
        'CREATE INDEX idx_business_region_reports_main_report_id ON business_region_reports(main_report_id)',
      );
      await db.execute(
        'CREATE INDEX idx_akb_by_categories_main_report_id ON akb_by_categories(main_report_id)',
      );
      await db.execute(
        'CREATE INDEX idx_visit_plans_main_report_id ON visit_plans(main_report_id)',
      );
      await db.execute(
        'CREATE INDEX idx_visit_plans_client_code ON visit_plans(client_code)',
      );
      await db.execute(
        'CREATE INDEX idx_visit_plan_lists_visit_plan_id ON visit_plan_lists(visit_plan_id)',
      );
    } else if (oldVersion < 11) {
      // Add order statuses and orders tables for version 11
      await db.execute('''
        CREATE TABLE order_statuses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message TEXT UNIQUE NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''CREATE TABLE couriers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        car TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

      await db.execute('''CREATE TABLE courier_cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        car TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

      await db.execute('''CREATE TABLE order_couriers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_num TEXT NOT NULL,
        courier_name TEXT,
        courier_car TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (order_num) REFERENCES orders (num_order) ON DELETE CASCADE,
        FOREIGN KEY (courier_name) REFERENCES couriers (name) ON DELETE SET NULL,
        FOREIGN KEY (courier_car) REFERENCES courier_cars (car) ON DELETE SET NULL,
        UNIQUE(order_num)
      )''');

      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          num_order TEXT UNIQUE NOT NULL,
          date_order TEXT NOT NULL,
          caption_order TEXT NOT NULL,
          type_price_code TEXT NOT NULL,
          status INTEGER NOT NULL,
          comment_supervisor TEXT,
          comment_forwarder TEXT,
          comment_agent TEXT,
          total REAL NOT NULL,
          client_code TEXT NOT NULL,
          client_name TEXT NOT NULL,
          code_org TEXT NOT NULL,
          main_status TEXT NOT NULL,
          courier_name TEXT,
          courier_car TEXT,
          server INTEGER NOT NULL DEFAULT 0,
          promo INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (type_price_code) REFERENCES price_types (code) ON DELETE CASCADE,
          FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE,
          FOREIGN KEY (main_status) REFERENCES order_statuses (message) ON DELETE SET NULL,
          FOREIGN KEY (courier_name) REFERENCES couriers (name) ON DELETE SET NULL,
          FOREIGN KEY (courier_car) REFERENCES courier_cars (car) ON DELETE SET NULL
        )
      ''');

      // Create indexes for orders table
      await db.execute(
        'CREATE INDEX idx_orders_num_order ON orders(num_order)',
      );
      await db.execute(
        'CREATE INDEX idx_orders_client_code ON orders(client_code)',
      );
      await db.execute(
        'CREATE INDEX idx_orders_type_price_code ON orders(type_price_code)',
      );
      await db.execute(
        'CREATE INDEX idx_orders_main_status ON orders(main_status)',
      );
      await db.execute(
        'CREATE INDEX idx_order_statuses_message ON order_statuses(message)',
      );
      await db.execute('CREATE INDEX idx_couriers_name ON couriers(name)');
      await db.execute(
        'CREATE INDEX idx_courier_cars_car ON courier_cars(car)',
      );
      await db.execute(
        'CREATE INDEX idx_order_couriers_order_num ON order_couriers(order_num)',
      );
    } else if (oldVersion < 12) {
      // Add order details tables for version 12
      await db.execute('''
        CREATE TABLE order_details (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          num_order TEXT UNIQUE NOT NULL,
          credit INTEGER NOT NULL DEFAULT 0,
          code_price TEXT NOT NULL,
          date_order TEXT NOT NULL,
          code_sklad TEXT NOT NULL,
          comment_supervisor TEXT,
          comment_forwarder TEXT,
          comment_agent TEXT,
          shipping_date TEXT NOT NULL,
          order_type INTEGER NOT NULL DEFAULT 0,
          code_org TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (num_order) REFERENCES orders (num_order) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE order_detail_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_detail_id INTEGER NOT NULL,
          code_product TEXT NOT NULL,
          name_product TEXT NOT NULL,
          amount INTEGER NOT NULL,
          price REAL NOT NULL,
          total REAL NOT NULL,
          discount_rate REAL NOT NULL DEFAULT 0.0,
          weight REAL NOT NULL DEFAULT 0.0,
          capacity REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (order_detail_id) REFERENCES order_details (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE order_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_detail_id INTEGER NOT NULL,
          date_of_payment TEXT NOT NULL,
          total REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (order_detail_id) REFERENCES order_details (id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for order details tables
      await db.execute(
        'CREATE INDEX idx_order_details_num_order ON order_details(num_order)',
      );
      await db.execute(
        'CREATE INDEX idx_order_detail_products_order_detail_id ON order_detail_products(order_detail_id)',
      );
      await db.execute(
        'CREATE INDEX idx_order_payments_order_detail_id ON order_payments(order_detail_id)',
      );
    } else if (oldVersion < 13) {
      // Add sales req permissions and visit steps tables for version 13
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_req_permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_code TEXT UNIQUE NOT NULL,
          skip_tin_duplicate_check INTEGER NOT NULL DEFAULT 0,
          allow_creation_without_tin INTEGER NOT NULL DEFAULT 0,
          visit INTEGER NOT NULL DEFAULT 0,
          strict_sequence INTEGER NOT NULL DEFAULT 0,
          unplanned_order INTEGER NOT NULL DEFAULT 0,
          planned_route INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS visit_steps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sales_req_permissions_id INTEGER NOT NULL,
          step_code INTEGER NOT NULL,
          step_name TEXT NOT NULL,
          step_required INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (sales_req_permissions_id) REFERENCES sales_req_permissions (id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for sales req permissions tables
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_req_permissions_user_code ON sales_req_permissions(user_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_sales_req_permissions_id ON visit_steps(sales_req_permissions_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_step_code ON visit_steps(step_code)',
      );
    } else if (oldVersion < 14) {
      // Add visit_steps_data table for version 14
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visit_steps_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_id TEXT NOT NULL,
          client_code TEXT NOT NULL,
          step_code INTEGER NOT NULL,
          step_name TEXT NOT NULL,
          data_type TEXT NOT NULL,
          data_content TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          synced_at TEXT,
          sync_error TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes for visit_steps_data table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_visit_id ON visit_steps_data(visit_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_client_code ON visit_steps_data(client_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_step_code ON visit_steps_data(step_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_data_type ON visit_steps_data(data_type)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_is_synced ON visit_steps_data(is_synced)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_timestamp ON visit_steps_data(timestamp)',
      );
    } else if (oldVersion < 15) {
      // Add create_order tables for version 15
      await db.execute('''
        CREATE TABLE IF NOT EXISTS create_order (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_agent TEXT NOT NULL,
          code_client TEXT NOT NULL,
          code_price TEXT NOT NULL,
          payment TEXT NOT NULL,
          shipping_date TEXT NOT NULL,
          comment_supervisor TEXT,
          comment_forwarder TEXT,
          comment TEXT,
          create_date TEXT NOT NULL,
          longitude REAL NOT NULL,
          latitude REAL NOT NULL,
          weight REAL NOT NULL,
          capacity REAL NOT NULL,
          credit INTEGER NOT NULL DEFAULT 0,
          code_project TEXT NOT NULL,
          order_type INTEGER NOT NULL DEFAULT 0,
          code_org TEXT NOT NULL,
          code_sklad TEXT NOT NULL,
          code_contract TEXT,
          has_promo INTEGER NOT NULL DEFAULT 0,
          is_synced INTEGER NOT NULL DEFAULT 0,
          synced_at TEXT,
          sync_error TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS create_order_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          create_order_id INTEGER NOT NULL,
          code_sklad TEXT NOT NULL,
          code_product TEXT NOT NULL,
          amount INTEGER NOT NULL,
          price REAL NOT NULL,
          total REAL NOT NULL,
          weight REAL NOT NULL,
          capacity REAL NOT NULL,
          payment_type INTEGER NOT NULL,
          discount_sum REAL NOT NULL DEFAULT 0.0,
          discount_rate REAL NOT NULL DEFAULT 0.0,
          gift_amount INTEGER NOT NULL DEFAULT 0,
          promo INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS competitive_intelligence (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          create_order_id INTEGER NOT NULL,
          competitor TEXT NOT NULL,
          product TEXT NOT NULL,
          price REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS credit_details (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          create_order_id INTEGER NOT NULL,
          date_of_payment TEXT NOT NULL,
          total REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for new tables
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_create_order_code_agent ON create_order(code_agent)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_create_order_code_client ON create_order(code_client)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_create_order_is_synced ON create_order(is_synced)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_create_order_create_date ON create_order(create_date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_create_order_products_create_order_id ON create_order_products(create_order_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_create_order_products_code_product ON create_order_products(code_product)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_competitive_intelligence_create_order_id ON competitive_intelligence(create_order_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_credit_details_create_order_id ON credit_details(create_order_id)',
      );
    } else if (oldVersion < 16) {
      // Add user_organizations table for version 16
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_organizations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          user_code TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes for user_organizations table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_organizations_code ON user_organizations(code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_organizations_user_code ON user_organizations(user_code)',
      );
    } else if (oldVersion < 17) {
      // Add new fields to sales_req_permissions table for version 17
      await db.execute(
        'ALTER TABLE sales_req_permissions ADD COLUMN client_zone_access INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE sales_req_permissions ADD COLUMN location_update_interval INTEGER NOT NULL DEFAULT 0',
      );
    } else if (oldVersion < 18) {
      // Add new fields to sales_req_permissions table for version 18
      // Check if columns exist before adding to avoid errors
      final columns = await db.rawQuery(
        "PRAGMA table_info(sales_req_permissions)",
      );
      final hasClientZoneAccess = columns.any(
        (col) => col['name'] == 'client_zone_access',
      );
      if (!hasClientZoneAccess) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN client_zone_access INTEGER NOT NULL DEFAULT 0',
        );
      }

      final hasLocationUpdateInterval = columns.any(
        (col) => col['name'] == 'location_update_interval',
      );
      if (!hasLocationUpdateInterval) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN location_update_interval INTEGER NOT NULL DEFAULT 0',
        );
      }
    } else if (oldVersion < 19) {
      // Ensure sales_req_permissions table exists with new fields for version 19
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_req_permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_code TEXT UNIQUE NOT NULL,
          skip_tin_duplicate_check INTEGER NOT NULL DEFAULT 0,
          allow_creation_without_tin INTEGER NOT NULL DEFAULT 0,
          visit INTEGER NOT NULL DEFAULT 0,
          strict_sequence INTEGER NOT NULL DEFAULT 0,
          unplanned_order INTEGER NOT NULL DEFAULT 0,
          planned_route INTEGER NOT NULL DEFAULT 0,
          edit_client_coordinates INTEGER NOT NULL DEFAULT 0,
          client_zone_access INTEGER NOT NULL DEFAULT 0,
          location_update_interval INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Check if columns exist before adding to avoid errors
      final columns = await db.rawQuery(
        "PRAGMA table_info(sales_req_permissions)",
      );
      final hasClientZoneAccess = columns.any(
        (col) => col['name'] == 'client_zone_access',
      );
      if (!hasClientZoneAccess) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN client_zone_access INTEGER NOT NULL DEFAULT 0',
        );
      }

      final hasLocationUpdateInterval = columns.any(
        (col) => col['name'] == 'location_update_interval',
      );
      if (!hasLocationUpdateInterval) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN location_update_interval INTEGER NOT NULL DEFAULT 0',
        );
      }
    } else if (oldVersion < 22) {
      // Add client_images table for version 22
      await db.execute('''
        CREATE TABLE IF NOT EXISTS client_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          client_code TEXT NOT NULL,
          client_id INTEGER,
          image TEXT,
          image_url TEXT,
          image_sm_url TEXT,
          image_md_url TEXT,
          image_lg_url TEXT,
          image_thumbnail_url TEXT,
          image_dimensions TEXT,
          image_sm_dimensions TEXT,
          image_md_dimensions TEXT,
          image_lg_dimensions TEXT,
          image_thumbnail_dimensions TEXT,
          is_main INTEGER DEFAULT 0,
          category TEXT,
          note TEXT,
          status TEXT,
          source TEXT,
          status_code TEXT,
          status_name TEXT,
          source_name TEXT,
          source_type TEXT,
          created_at_server TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE
        )
      ''');

      // Create indexes for client_images table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_client_code ON client_images(client_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_server_id ON client_images(server_id)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_client_images_client_code_server_id ON client_images(client_code, server_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_client_id ON client_images(client_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_is_main ON client_images(is_main)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_status_code ON client_images(status_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_created_at_server ON client_images(created_at_server)',
      );
    } else if (oldVersion < 24) {
      // Align client_images table to latest API response structure
      //
      // New API fields:
      // - id (server image id)
      // - client (numeric id)
      // - image (original url)
      // - status/source (nullable)
      final columns = await db.rawQuery("PRAGMA table_info(client_images)");

      Future<void> addColumnIfMissing(String name, String type) async {
        final hasColumn = columns.any((col) => col['name'] == name);
        if (!hasColumn) {
          await db.execute('ALTER TABLE client_images ADD COLUMN $name $type');
          if (kDebugMode) {
            print(
              'ApiDatabaseService: Added $name column to client_images table',
            );
          }
        }
      }

      await addColumnIfMissing('server_id', 'INTEGER');
      await addColumnIfMissing('client_id', 'INTEGER');
      await addColumnIfMissing('image', 'TEXT');
      await addColumnIfMissing('status', 'TEXT');
      await addColumnIfMissing('source', 'TEXT');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_server_id ON client_images(server_id)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_client_images_client_code_server_id ON client_images(client_code, server_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_images_client_id ON client_images(client_id)',
      );
    }

    // =========================================================================
    // Version 25: Client Balance tables for storing balance data from buh2 API
    // =========================================================================
    if (oldVersion < 25) {
      // Asosiy mijoz balansi jadvali
      await db.execute('''
        CREATE TABLE IF NOT EXISTS client_balances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inn TEXT UNIQUE NOT NULL,
          balance REAL NOT NULL DEFAULT 0.0,
          project_name TEXT,
          last_updated TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Shartnomalar bo'yicha balans jadvali
      await db.execute('''
        CREATE TABLE IF NOT EXISTS client_balance_contracts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inn TEXT NOT NULL,
          project_name TEXT,
          region TEXT,
          tax_id TEXT,
          customer_name TEXT,
          contract_code TEXT,
          payment_amount REAL NOT NULL DEFAULT 0.0,
          debt_amount REAL NOT NULL DEFAULT 0.0,
          contract_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (inn) REFERENCES client_balances (inn) ON DELETE CASCADE
        )
      ''');

      // Buyurtmalar bo'yicha balans jadvali
      await db.execute('''
        CREATE TABLE IF NOT EXISTS client_balance_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inn TEXT NOT NULL,
          project_name TEXT,
          region TEXT,
          tax_id TEXT,
          customer_name TEXT,
          contract_code TEXT,
          sales_channel TEXT,
          order_number TEXT,
          order_date TEXT,
          order_amount REAL NOT NULL DEFAULT 0.0,
          payment_amount REAL NOT NULL DEFAULT 0.0,
          debt_amount REAL NOT NULL DEFAULT 0.0,
          status TEXT,
          overdue_days INTEGER NOT NULL DEFAULT 0,
          contract_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (inn) REFERENCES client_balances (inn) ON DELETE CASCADE
        )
      ''');

      // Indekslar
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balances_inn ON client_balances(inn)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balances_last_updated ON client_balances(last_updated)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_contracts_inn ON client_balance_contracts(inn)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_contracts_contract_code ON client_balance_contracts(contract_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_inn ON client_balance_orders(inn)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_order_number ON client_balance_orders(order_number)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_status ON client_balance_orders(status)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_order_date ON client_balance_orders(order_date)',
      );

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Created client_balances tables (version 25)',
        );
      }
    }

    // =========================================================================
    // Version 26: Add client_code relationship to clients table
    // =========================================================================
    if (oldVersion < 26) {
      // client_balances jadvaliga client_code ustunini qo'shish
      final balanceColumns = await db.rawQuery(
        "PRAGMA table_info(client_balances)",
      );
      final hasClientCode = balanceColumns.any(
        (col) => col['name'] == 'client_code',
      );
      if (!hasClientCode) {
        await db.execute(
          'ALTER TABLE client_balances ADD COLUMN client_code TEXT REFERENCES clients(code) ON DELETE CASCADE',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added client_code column to client_balances table',
          );
        }
      }

      // client_balance_contracts jadvaliga client_code ustunini qo'shish
      final contractColumns = await db.rawQuery(
        "PRAGMA table_info(client_balance_contracts)",
      );
      final contractHasClientCode = contractColumns.any(
        (col) => col['name'] == 'client_code',
      );
      if (!contractHasClientCode) {
        await db.execute(
          'ALTER TABLE client_balance_contracts ADD COLUMN client_code TEXT REFERENCES clients(code) ON DELETE CASCADE',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added client_code column to client_balance_contracts table',
          );
        }
      }

      // client_balance_orders jadvaliga client_code ustunini qo'shish
      final orderColumns = await db.rawQuery(
        "PRAGMA table_info(client_balance_orders)",
      );
      final orderHasClientCode = orderColumns.any(
        (col) => col['name'] == 'client_code',
      );
      if (!orderHasClientCode) {
        await db.execute(
          'ALTER TABLE client_balance_orders ADD COLUMN client_code TEXT REFERENCES clients(code) ON DELETE CASCADE',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added client_code column to client_balance_orders table',
          );
        }
      }

      // Indekslar yaratish
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balances_client_code ON client_balances(client_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_contracts_client_code ON client_balance_contracts(client_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_client_code ON client_balance_orders(client_code)',
      );

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Added client_code relationships (version 26)',
        );
      }
    }

    // =========================================================================
    // Version 27: Contract Types table for storing contract type data
    // =========================================================================
    if (oldVersion < 27) {
      // Create contract_types table for caching contract types from server
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contract_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create index for contract_types table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_contract_types_code ON contract_types(code)',
      );

      if (kDebugMode) {
        print('ApiDatabaseService: Created contract_types table (version 27)');
      }
    }

    // =========================================================================
    // Version 28: District Contracting table for contract city/district data
    // =========================================================================
    if (oldVersion < 28) {
      // Create district_contracting table for caching district data from server
      await db.execute('''
        CREATE TABLE IF NOT EXISTS district_contracting (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_district TEXT UNIQUE NOT NULL,
          name_district TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create index for district_contracting table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_district_contracting_code ON district_contracting(code_district)',
      );

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Created district_contracting table (version 28)',
        );
      }
    }

    // =========================================================================
    // Version 29: Product Images table for nomenklatura images from REST API
    // =========================================================================
    if (oldVersion < 29) {
      // Create product_images table for caching product images from server
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          product_code TEXT NOT NULL,
          nomenklatura_id INTEGER,
          image TEXT,
          image_url TEXT,
          image_sm_url TEXT,
          image_md_url TEXT,
          image_lg_url TEXT,
          image_thumbnail_url TEXT,
          image_dimensions TEXT,
          image_sm_dimensions TEXT,
          image_md_dimensions TEXT,
          image_lg_dimensions TEXT,
          image_thumbnail_dimensions TEXT,
          is_main INTEGER DEFAULT 0,
          category TEXT,
          note TEXT,
          status TEXT,
          source TEXT,
          created_at_server TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (product_code) REFERENCES products (code) ON DELETE CASCADE
        )
      ''');

      // Create indexes for product_images table
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_images_product_code ON product_images(product_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_images_server_id ON product_images(server_id)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_product_images_product_code_server_id ON product_images(product_code, server_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_images_is_main ON product_images(is_main)',
      );

      if (kDebugMode) {
        print('ApiDatabaseService: Created product_images table (version 29)');
      }
    }

    // =========================================================================
    // Version 30: Add price_type fields to order_detail_products table
    // =========================================================================
    if (oldVersion < 30) {
      // Add price_type_code and price_type_name columns to order_detail_products
      final columns = await db.rawQuery(
        "PRAGMA table_info(order_detail_products)",
      );

      final hasPriceTypeCode = columns.any(
        (col) => col['name'] == 'price_type_code',
      );
      if (!hasPriceTypeCode) {
        await db.execute(
          'ALTER TABLE order_detail_products ADD COLUMN price_type_code TEXT',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added price_type_code column to order_detail_products table',
          );
        }
      }

      final hasPriceTypeName = columns.any(
        (col) => col['name'] == 'price_type_name',
      );
      if (!hasPriceTypeName) {
        await db.execute(
          'ALTER TABLE order_detail_products ADD COLUMN price_type_name TEXT',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added price_type_name column to order_detail_products table',
          );
        }
      }

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Added price_type fields to order_detail_products (version 30)',
        );
      }
    }

    // =========================================================================
    // Version 31: Add map_tokens table for storing Yandex/Google map API tokens
    // =========================================================================
    if (oldVersion < 31) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS map_tokens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          yandex_token TEXT,
          google_token TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      if (kDebugMode) {
        print('ApiDatabaseService: Created map_tokens table (version 31)');
      }
    }

    // =========================================================================
    // Version 32: Add sync_metadata table for conditional sync optimization
    // =========================================================================
    if (oldVersion < 32) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          table_name TEXT PRIMARY KEY,
          last_sync_at TEXT NOT NULL,
          records_count INTEGER DEFAULT 0,
          sync_duration_ms INTEGER DEFAULT 0
        )
      ''');

      if (kDebugMode) {
        print('ApiDatabaseService: Created sync_metadata table (version 32)');
      }
    }

    // =========================================================================
    // Version 33: Add promo column to orders table
    // =========================================================================
    if (oldVersion < 33) {
      await db.execute(
        'ALTER TABLE orders ADD COLUMN promo INTEGER NOT NULL DEFAULT 0',
      );

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Added promo column to orders table (version 33)',
        );
      }
    }

    // =========================================================================
    // Version 34: Add server_data_updated_at to client_balances table
    // Stores when accounting system last updated balance data (separate from local lastUpdated)
    // =========================================================================
    if (oldVersion < 34) {
      final columns = await db.rawQuery(
        "PRAGMA table_info(client_balances)",
      );
      final hasServerDataUpdatedAt = columns.any(
        (col) => col['name'] == 'server_data_updated_at',
      );
      if (!hasServerDataUpdatedAt) {
        await db.execute(
          'ALTER TABLE client_balances ADD COLUMN server_data_updated_at TEXT',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added server_data_updated_at column to client_balances table (version 34)',
          );
        }
      }
    }

    // =========================================================================
    // Version 35: Add shipping_date to orders table
    // Stores the expected delivery date for the order
    // =========================================================================
    if (oldVersion < 35) {
      final columns = await db.rawQuery(
        "PRAGMA table_info(orders)",
      );
      final hasShippingDate = columns.any(
        (col) => col['name'] == 'shipping_date',
      );
      if (!hasShippingDate) {
        await db.execute(
          'ALTER TABLE orders ADD COLUMN shipping_date TEXT',
        );
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Added shipping_date column to orders table (version 35)',
          );
        }
      }
    }

    // =========================================================================
    // Version 36: User Projects table
    // Таблица проектов пользователя / Foydalanuvchi loyihalari jadvali
    // Stores user-specific project assignments from GetProjectsUser SOAP API
    // =========================================================================
    if (oldVersion < 36) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL,
          name TEXT NOT NULL,
          user_code TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(code, user_code)
        )
      ''');

      // Индексы для быстрого поиска / Tez qidiruv uchun indekslar
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_projects_code ON user_projects(code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_projects_user_code ON user_projects(user_code)',
      );

      if (kDebugMode) {
        print('ApiDatabaseService: Created user_projects table (version 36)');
      }
    }

    if (oldVersion < 37) {
      // Knowledge Base feature — categories, documents, sections,
      // content blocks, media, assignments, tags. Schema is shared
      // with [_onCreate]; see [_createKnowledgeBaseTables] for the
      // single source of truth.
      await _createKnowledgeBaseTables(db);
      if (kDebugMode) {
        print('ApiDatabaseService: Created knowledge base tables (version 37)');
      }
    }

    if (oldVersion < 38) {
      // Knowledge assignment STAFF target — backend now scopes
      // documents by staff record (not just user/role). The column
      // is nullable, so existing rows survive the migration; the
      // sync feed will populate it on next refresh.
      //
      // ALTER TABLE column add is wrapped in try/catch because
      // sqflite raises a "duplicate column" SQLITE_ERROR when the
      // db was created against the v38 schema directly via
      // [_onCreate] (fresh installs). Idempotency keeps the
      // migration safe to re-run.
      try {
        await db.execute(
          'ALTER TABLE knowledge_assignments ADD COLUMN target_staff_id TEXT',
        );
      } catch (e) {
        if (kDebugMode) {
          print(
              'ApiDatabaseService: skip ADD target_staff_id (likely already present): $e');
        }
      }
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_kn_asg_staff ON knowledge_assignments(target_staff_id)',
      );
      if (kDebugMode) {
        print(
            'ApiDatabaseService: knowledge_assignments.target_staff_id ready (version 38)');
      }
    }

    if (oldVersion < 39) {
      // Customer-creation permission moved to V2 codename
      // `customers.add_customer` (BackendPermissionStore). SOAP-derived
      // `allow_creating_point_of_sale` is no longer read or written, so
      // we drop the column to keep the schema honest.
      //
      // ALTER TABLE … DROP COLUMN is wrapped in try/catch for two
      // reasons: (a) fresh installs hit `_onCreate` directly and the
      // column never existed, so the DROP would raise "no such column";
      // (b) very old SQLite without DROP COLUMN support would also
      // raise — harmless because the stale column is unreferenced.
      try {
        await db.execute(
          'ALTER TABLE sales_req_permissions DROP COLUMN allow_creating_point_of_sale',
        );
      } catch (e) {
        if (kDebugMode) {
          print(
              'ApiDatabaseService: skip DROP allow_creating_point_of_sale (likely already absent): $e');
        }
      }
      if (kDebugMode) {
        print(
            'ApiDatabaseService: sales_req_permissions.allow_creating_point_of_sale dropped (version 39)');
      }
    }

    if (oldVersion < 40) {
      // Backend-first customer reads via `GET /api/mobile/v2/customers/`
      // ship `code` (backend identifier, `C-XXXXXXXX`) as the primary
      // key and `code_1c` as a separate downstream value. The legacy
      // SOAP-derived rows used `code_1c` as the local `code` column;
      // we add a dedicated `code_1c` column and one-shot wipe the
      // table so the next sync refills with the V2 shape.
      try {
        await db.execute(
          "ALTER TABLE clients ADD COLUMN code_1c TEXT NOT NULL DEFAULT ''",
        );
      } catch (e) {
        if (kDebugMode) {
          print(
              'ApiDatabaseService: skip ADD code_1c (likely already present): $e');
        }
      }
      await db.delete('clients');
      if (kDebugMode) {
        print(
            'ApiDatabaseService: clients table wiped + code_1c column added (version 40)');
      }
    }

    if (oldVersion < 41) {
      // customer_scope=project rollout: `user_projects` needs `id_uuid`
      // (V2 backend UUID) and `id_1c` (1C ref) so the mobile can send
      // `X-Project-Id` on `/api/mobile/v2/customers/...` calls.
      for (final column in const ['id_uuid', 'id_1c']) {
        try {
          await db.execute(
            'ALTER TABLE user_projects ADD COLUMN $column TEXT',
          );
        } catch (e) {
          if (kDebugMode) {
            print(
                'ApiDatabaseService: skip ADD $column on user_projects (likely already present): $e');
          }
        }
      }
      if (kDebugMode) {
        print(
            'ApiDatabaseService: user_projects extended with id_uuid + id_1c (version 41)');
      }
    }
  }

  Future<void> _createTables(Database db) async {
    // Create KPI data table with new fields
    await db.execute('''
      CREATE TABLE kpi_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_code TEXT NOT NULL,
        plan TEXT NOT NULL,
        fact TEXT NOT NULL,
        total_percent TEXT NOT NULL,
        total_forecast TEXT NOT NULL,
        total_percent_forecast_fact TEXT NOT NULL,
        akb_plan TEXT NOT NULL,
        akb_fact TEXT NOT NULL,
        akb_percent TEXT NOT NULL,
        okb TEXT NOT NULL,
        update_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create business regions table
    await db.execute('''
      CREATE TABLE business_regions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create user warehouses table
    await db.execute('''
      CREATE TABLE user_warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        organization TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create product brands table
    await db.execute('''
      CREATE TABLE product_brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create product series table
    await db.execute('''
      CREATE TABLE product_series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (brand_name) REFERENCES product_brands (name) ON DELETE CASCADE,
        UNIQUE(name, brand_name)
      )
    ''');

    // Create product balances table
    await db.execute('''
      CREATE TABLE product_balances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_sklad TEXT NOT NULL,
        code_product TEXT NOT NULL,
        name_product TEXT NOT NULL,
        have INTEGER NOT NULL,
        reserved INTEGER NOT NULL,
        available INTEGER NOT NULL,
        weight REAL NOT NULL,
        capacity REAL NOT NULL,
        code_project TEXT NOT NULL,
        vendor_code TEXT NOT NULL,
        product_brand TEXT NOT NULL,
        product_series TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (code_sklad) REFERENCES user_warehouses (code) ON DELETE CASCADE,
        FOREIGN KEY (code_product) REFERENCES products (code) ON DELETE CASCADE,
        FOREIGN KEY (product_brand) REFERENCES product_brands (name) ON DELETE CASCADE,
        UNIQUE(code_sklad, code_product)
      )
    ''');

    // Create clients table with new fields
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        code_1c TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT,
        inn TEXT,
        contact_person TEXT,
        latitude REAL DEFAULT 0.0,
        longitude REAL DEFAULT 0.0,
        region TEXT,
        district TEXT,
        status TEXT DEFAULT 'active',
        last_visit_date TEXT,
        has_orders INTEGER DEFAULT 0,
        has_contracts INTEGER DEFAULT 0,
        is_visited INTEGER DEFAULT 0,
        has_contract INTEGER DEFAULT 0,
        owner_name TEXT,
        signboard TEXT,
        reference_point TEXT,
        responsible_person TEXT,
        responsible_person_phone TEXT,
        trade_point_type TEXT,
        credit_limit REAL DEFAULT 0.0,
        accumulated_credit REAL DEFAULT 0.0,
        code_region TEXT REFERENCES business_regions(code) ON DELETE SET NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create client contracts table
    await db.execute('''
      CREATE TABLE client_contracts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_contract TEXT UNIQUE NOT NULL,
        date_of_contract TEXT,
        sum_of_contract REAL NOT NULL,
        term_of_contract TEXT,
        type_contract TEXT,
        numb_reference TEXT,
        numb_certificate TEXT,
        term_reference TEXT,
        term_certificate TEXT,
        numb_passport TEXT,
        term_passport TEXT,
        certificate_unlimited INTEGER NOT NULL,
        code_district TEXT,
        name_district TEXT,
        code_project TEXT,
        code_client TEXT NOT NULL,
        active INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (code_client) REFERENCES clients (code) ON DELETE CASCADE
      )
    ''');

    // Create products table with new fields
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL DEFAULT 0.0,
        reserved REAL DEFAULT 0.0,
        available REAL DEFAULT 0.0,
        category TEXT,
        barcode TEXT,
        have INTEGER DEFAULT 0,
        warehouse_code TEXT,
        weight REAL DEFAULT 0.0,
        capacity REAL DEFAULT 0.0,
        vendor_code TEXT,
        product_brand TEXT,
        product_series TEXT,
        code_project TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for products
    await db.execute(
      'CREATE INDEX idx_products_warehouse_code ON products(warehouse_code)',
    );
    await db.execute(
      'CREATE INDEX idx_products_code_project ON products(code_project)',
    );

    // Create price types table
    await db.execute('''
      CREATE TABLE price_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create product prices table
    await db.execute('''
      CREATE TABLE product_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_code TEXT NOT NULL,
        price_type_code TEXT NOT NULL,
        price REAL NOT NULL,
        currency TEXT DEFAULT 'UZS',
        valid_from TEXT,
        valid_to TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_code) REFERENCES products (code) ON DELETE CASCADE,
        FOREIGN KEY (price_type_code) REFERENCES price_types (code) ON DELETE CASCADE,
        UNIQUE(product_code, price_type_code)
      )
    ''');

    // Create indexes for product prices
    await db.execute(
      'CREATE INDEX idx_product_prices_price_type_code ON product_prices(price_type_code)',
    );
    await db.execute(
      'CREATE INDEX idx_product_prices_product_code ON product_prices(product_code)',
    );

    // Create promotions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS promotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        min_promo_product_count INTEGER NOT NULL,
        bonus_count INTEGER NOT NULL,
        date_start TEXT NOT NULL,
        date_end TEXT NOT NULL,
        last_synced TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create promotion product list table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS promotion_product_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_code TEXT NOT NULL,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
        UNIQUE(promotion_code, product_code)
      )
    ''');

    // Create promotion bonus list table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS promotion_bonus_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_code TEXT NOT NULL,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
        UNIQUE(promotion_code, product_code)
      )
    ''');

    // Create promotion class list table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS promotion_class_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_code TEXT NOT NULL,
        class_code TEXT NOT NULL,
        class_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
        UNIQUE(promotion_code, class_code)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_promotions_code ON promotions(code)');
    await db.execute(
      'CREATE INDEX idx_promotions_active ON promotions(is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_promotions_date_range ON promotions(date_start, date_end)',
    );
    await db.execute(
      'CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)',
    );
    await db.execute(
      'CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)',
    );
    await db.execute(
      'CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)',
    );

    // Indexes for product balance tables
    await db.execute(
      'CREATE INDEX idx_product_balances_code_sklad ON product_balances(code_sklad)',
    );
    await db.execute(
      'CREATE INDEX idx_product_balances_code_product ON product_balances(code_product)',
    );
    await db.execute(
      'CREATE INDEX idx_product_balances_product_brand ON product_balances(product_brand)',
    );
    await db.execute(
      'CREATE INDEX idx_product_balances_product_series ON product_balances(product_series)',
    );
    await db.execute(
      'CREATE INDEX idx_product_series_brand_name ON product_series(brand_name)',
    );

    // Indexes for client contracts table
    await db.execute(
      'CREATE INDEX idx_client_contracts_code_contract ON client_contracts(code_contract)',
    );
    await db.execute(
      'CREATE INDEX idx_client_contracts_code_client ON client_contracts(code_client)',
    );
    await db.execute(
      'CREATE INDEX idx_client_contracts_active ON client_contracts(active)',
    );
    await db.execute(
      'CREATE INDEX idx_client_contracts_status ON client_contracts(status)',
    );

    // Create report tables
    await db.execute('''
      CREATE TABLE main_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_code TEXT NOT NULL,
        date_start TEXT NOT NULL,
        date_end TEXT NOT NULL,
        count_akb INTEGER NOT NULL,
        count_okb INTEGER NOT NULL,
        cash REAL NOT NULL,
        transfer REAL NOT NULL,
        sum REAL NOT NULL,
        count_visited INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE business_region_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_report_id INTEGER NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        akb INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE akb_by_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_report_id INTEGER NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        akb INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE visit_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_report_id INTEGER NOT NULL,
        client_code TEXT NOT NULL,
        client_name TEXT NOT NULL,
        planned_date TEXT NOT NULL,
        actual_visit_date TEXT,
        is_completed INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE visit_plan_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visit_plan_id INTEGER NOT NULL,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        planned_quantity INTEGER NOT NULL,
        actual_quantity INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (visit_plan_id) REFERENCES visit_plans (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for report tables
    await db.execute(
      'CREATE INDEX idx_main_reports_user_code ON main_reports(user_code)',
    );
    await db.execute(
      'CREATE INDEX idx_main_reports_date_range ON main_reports(date_start, date_end)',
    );
    await db.execute(
      'CREATE INDEX idx_business_region_reports_main_report_id ON business_region_reports(main_report_id)',
    );
    await db.execute(
      'CREATE INDEX idx_akb_by_categories_main_report_id ON akb_by_categories(main_report_id)',
    );
    await db.execute(
      'CREATE INDEX idx_visit_plans_main_report_id ON visit_plans(main_report_id)',
    );
    await db.execute(
      'CREATE INDEX idx_visit_plans_client_code ON visit_plans(client_code)',
    );
    await db.execute(
      'CREATE INDEX idx_visit_plan_lists_visit_plan_id ON visit_plan_lists(visit_plan_id)',
    );

    // Create order statuses table
    await db.execute('''
      CREATE TABLE order_statuses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create orders table
    await db.execute('''CREATE TABLE couriers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      car TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE courier_cars (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      car TEXT UNIQUE NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE order_couriers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_num TEXT NOT NULL,
      courier_name TEXT,
      courier_car TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (order_num) REFERENCES orders (num_order) ON DELETE CASCADE,
      FOREIGN KEY (courier_name) REFERENCES couriers (name) ON DELETE SET NULL,
      FOREIGN KEY (courier_car) REFERENCES courier_cars (car) ON DELETE SET NULL,
      UNIQUE(order_num)
    )''');

    await db.execute('''CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      num_order TEXT UNIQUE NOT NULL,
      date_order TEXT NOT NULL,
      caption_order TEXT NOT NULL,
      type_price_code TEXT NOT NULL,
      status INTEGER NOT NULL,
      comment_supervisor TEXT,
      comment_forwarder TEXT,
      comment_agent TEXT,
      total REAL NOT NULL,
      client_code TEXT NOT NULL,
      client_name TEXT NOT NULL,
      code_org TEXT NOT NULL,
      main_status TEXT NOT NULL,
      courier_name TEXT,
      courier_car TEXT,
      shipping_date TEXT,
      server INTEGER NOT NULL DEFAULT 0,
      promo INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (type_price_code) REFERENCES price_types (code) ON DELETE CASCADE,
      FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE,
      FOREIGN KEY (main_status) REFERENCES order_statuses (message) ON DELETE SET NULL,
      FOREIGN KEY (courier_name) REFERENCES couriers (name) ON DELETE SET NULL,
      FOREIGN KEY (courier_car) REFERENCES courier_cars (car) ON DELETE SET NULL
    )''');

    // Create indexes for orders table
    await db.execute('CREATE INDEX idx_orders_num_order ON orders(num_order)');
    await db.execute(
      'CREATE INDEX idx_orders_client_code ON orders(client_code)',
    );
    await db.execute(
      'CREATE INDEX idx_orders_type_price_code ON orders(type_price_code)',
    );
    await db.execute(
      'CREATE INDEX idx_orders_main_status ON orders(main_status)',
    );
    await db.execute(
      'CREATE INDEX idx_order_statuses_message ON order_statuses(message)',
    );

    // Create create_order table for local order creation
    await db.execute('''
      CREATE TABLE create_order (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_agent TEXT NOT NULL,
        code_client TEXT NOT NULL,
        code_price TEXT NOT NULL,
        payment TEXT NOT NULL,
        shipping_date TEXT NOT NULL,
        comment_supervisor TEXT,
        comment_forwarder TEXT,
        comment TEXT,
        create_date TEXT NOT NULL,
        longitude REAL NOT NULL,
        latitude REAL NOT NULL,
        weight REAL NOT NULL,
        capacity REAL NOT NULL,
        credit INTEGER NOT NULL DEFAULT 0,
        code_project TEXT NOT NULL,
        order_type INTEGER NOT NULL DEFAULT 0,
        code_org TEXT NOT NULL,
        code_sklad TEXT NOT NULL,
        code_contract TEXT,
        has_promo INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT,
        sync_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create create_order_products table
    await db.execute('''
      CREATE TABLE create_order_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        create_order_id INTEGER NOT NULL,
        code_sklad TEXT NOT NULL,
        code_product TEXT NOT NULL,
        amount INTEGER NOT NULL,
        price REAL NOT NULL,
        total REAL NOT NULL,
        weight REAL NOT NULL,
        capacity REAL NOT NULL,
        payment_type INTEGER NOT NULL,
        discount_sum REAL NOT NULL DEFAULT 0.0,
        discount_rate REAL NOT NULL DEFAULT 0.0,
        gift_amount INTEGER NOT NULL DEFAULT 0,
        promo INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
      )
    ''');

    // Create competitive_intelligence table
    await db.execute('''
      CREATE TABLE competitive_intelligence (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        create_order_id INTEGER NOT NULL,
        competitor TEXT NOT NULL,
        product TEXT NOT NULL,
        price REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
      )
    ''');

    // Create credit_details table
    await db.execute('''
      CREATE TABLE credit_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        create_order_id INTEGER NOT NULL,
        date_of_payment TEXT NOT NULL,
        total REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for new tables
    await db.execute(
      'CREATE INDEX idx_create_order_code_agent ON create_order(code_agent)',
    );
    await db.execute(
      'CREATE INDEX idx_create_order_code_client ON create_order(code_client)',
    );
    await db.execute(
      'CREATE INDEX idx_create_order_is_synced ON create_order(is_synced)',
    );
    await db.execute(
      'CREATE INDEX idx_create_order_create_date ON create_order(create_date)',
    );
    await db.execute(
      'CREATE INDEX idx_create_order_products_create_order_id ON create_order_products(create_order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_create_order_products_code_product ON create_order_products(code_product)',
    );
    await db.execute(
      'CREATE INDEX idx_competitive_intelligence_create_order_id ON competitive_intelligence(create_order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_credit_details_create_order_id ON credit_details(create_order_id)',
    );

    // Create sales_req_permissions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_req_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_code TEXT UNIQUE NOT NULL,
        skip_tin_duplicate_check INTEGER NOT NULL DEFAULT 0,
        allow_creation_without_tin INTEGER NOT NULL DEFAULT 0,
        visit INTEGER NOT NULL DEFAULT 0,
        strict_sequence INTEGER NOT NULL DEFAULT 0,
        unplanned_order INTEGER NOT NULL DEFAULT 0,
        planned_route INTEGER NOT NULL DEFAULT 0,
        edit_client_coordinates INTEGER NOT NULL DEFAULT 0,
        client_zone_access INTEGER NOT NULL DEFAULT 0,
        location_update_interval INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create visit_steps table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_req_permissions_id INTEGER NOT NULL,
        step_code INTEGER NOT NULL,
        step_name TEXT NOT NULL,
        step_required INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP),
        updated_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP),
        FOREIGN KEY (sales_req_permissions_id) REFERENCES sales_req_permissions (id) ON DELETE CASCADE
      )
    ''');

    // Create visit_steps_data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_steps_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visit_id TEXT NOT NULL,
        client_code TEXT NOT NULL,
        step_code INTEGER NOT NULL,
        step_name TEXT NOT NULL,
        data_type TEXT NOT NULL,
        data_content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT,
        sync_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create planned_routes table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS planned_routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_code TEXT NOT NULL,
        code_weekday INTEGER NOT NULL,
        week_day TEXT NOT NULL,
        code_client TEXT NOT NULL,
        client_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_code, code_weekday, code_client)
      )
    ''');

    // Create client_images table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        client_code TEXT NOT NULL,
        client_id INTEGER,
        image TEXT,
        image_url TEXT,
        image_sm_url TEXT,
        image_md_url TEXT,
        image_lg_url TEXT,
        image_thumbnail_url TEXT,
        image_dimensions TEXT,
        image_sm_dimensions TEXT,
        image_md_dimensions TEXT,
        image_lg_dimensions TEXT,
        image_thumbnail_dimensions TEXT,
        is_main INTEGER DEFAULT 0,
        category TEXT,
        note TEXT,
        status TEXT,
        source TEXT,
        status_code TEXT,
        status_name TEXT,
        source_name TEXT,
        source_type TEXT,
        created_at_server TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE
      )
    ''');

    // Create indexes for new tables
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_req_permissions_user_code ON sales_req_permissions(user_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_sales_req_permissions_id ON visit_steps(sales_req_permissions_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_step_code ON visit_steps(step_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_visit_id ON visit_steps_data(visit_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_client_code ON visit_steps_data(client_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_step_code ON visit_steps_data(step_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_data_type ON visit_steps_data(data_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_is_synced ON visit_steps_data(is_synced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_timestamp ON visit_steps_data(timestamp)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_planned_routes_user_code ON planned_routes(user_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_planned_routes_code_weekday ON planned_routes(code_weekday)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_planned_routes_code_client ON planned_routes(code_client)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_images_client_code ON client_images(client_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_images_server_id ON client_images(server_id)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_client_images_client_code_server_id ON client_images(client_code, server_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_images_client_id ON client_images(client_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_images_is_main ON client_images(is_main)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_images_status_code ON client_images(status_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_images_created_at_server ON client_images(created_at_server)',
    );

    // =========================================================================
    // Client Balance tables - Mijoz balansi ma'lumotlari uchun
    // =========================================================================

    // Asosiy mijoz balansi jadvali - clients table bilan bog'langan
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_balances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inn TEXT UNIQUE NOT NULL,
        client_code TEXT,
        balance REAL NOT NULL DEFAULT 0.0,
        project_name TEXT,
        last_updated TEXT NOT NULL,
        server_data_updated_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE
      )
    ''');


    // Shartnomalar bo'yicha balans jadvali - clients table bilan bog'langan
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_balance_contracts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inn TEXT NOT NULL,
        client_code TEXT,
        project_name TEXT,
        region TEXT,
        tax_id TEXT,
        customer_name TEXT,
        contract_code TEXT,
        payment_amount REAL NOT NULL DEFAULT 0.0,
        debt_amount REAL NOT NULL DEFAULT 0.0,
        contract_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (inn) REFERENCES client_balances (inn) ON DELETE CASCADE,
        FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE
      )
    ''');

    // Buyurtmalar bo'yicha balans jadvali - clients table bilan bog'langan
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_balance_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inn TEXT NOT NULL,
        client_code TEXT,
        project_name TEXT,
        region TEXT,
        tax_id TEXT,
        customer_name TEXT,
        contract_code TEXT,
        sales_channel TEXT,
        order_number TEXT,
        order_date TEXT,
        order_amount REAL NOT NULL DEFAULT 0.0,
        payment_amount REAL NOT NULL DEFAULT 0.0,
        debt_amount REAL NOT NULL DEFAULT 0.0,
        status TEXT,
        overdue_days INTEGER NOT NULL DEFAULT 0,
        contract_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (inn) REFERENCES client_balances (inn) ON DELETE CASCADE,
        FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE
      )
    ''');

    // Client Balance indekslari
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balances_inn ON client_balances(inn)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balances_client_code ON client_balances(client_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balances_last_updated ON client_balances(last_updated)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_contracts_inn ON client_balance_contracts(inn)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_contracts_client_code ON client_balance_contracts(client_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_contracts_contract_code ON client_balance_contracts(contract_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_inn ON client_balance_orders(inn)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_client_code ON client_balance_orders(client_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_order_number ON client_balance_orders(order_number)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_status ON client_balance_orders(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_client_balance_orders_order_date ON client_balance_orders(order_date)',
    );

    // =========================================================================
    // Contract Types table - Shartnoma turlari uchun
    // =========================================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contract_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Contract Types indekslari
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_contract_types_code ON contract_types(code)',
    );

    // =========================================================================
    // District Contracting table - Shartnoma uchun shahar/tuman ma'lumotlari
    // =========================================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS district_contracting (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_district TEXT UNIQUE NOT NULL,
        name_district TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // District Contracting indekslari
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_district_contracting_code ON district_contracting(code_district)',
    );

    // =========================================================================
    // Product Images table - Mahsulot rasmlari uchun (REST API)
    // =========================================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        product_code TEXT NOT NULL,
        nomenklatura_id INTEGER,
        image TEXT,
        image_url TEXT,
        image_sm_url TEXT,
        image_md_url TEXT,
        image_lg_url TEXT,
        image_thumbnail_url TEXT,
        image_dimensions TEXT,
        image_sm_dimensions TEXT,
        image_md_dimensions TEXT,
        image_lg_dimensions TEXT,
        image_thumbnail_dimensions TEXT,
        is_main INTEGER DEFAULT 0,
        category TEXT,
        note TEXT,
        status TEXT,
        source TEXT,
        created_at_server TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_code) REFERENCES products (code) ON DELETE CASCADE
      )
    ''');

    // Product Images indekslari
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_images_product_code ON product_images(product_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_images_server_id ON product_images(server_id)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_product_images_product_code_server_id ON product_images(product_code, server_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_images_is_main ON product_images(is_main)',
    );

    if (kDebugMode) print('API cache database tables created successfully');
  }

  // KPI Data methods
  /// Save KPI data for a specific user
  /// Ensures kpi_data table exists before operations and handles errors gracefully
  /// This method replaces all existing KPI data for the user with new data
  Future<void> saveKpiData(String userCode, KpiData kpiData) async {
    try {
      if (kDebugMode) {
        print('ApiDatabaseService: Saving KPI data for user: $userCode');
      }

      // Ensure table exists before performing operations
      final tableInfo = getTableCreationSql()['kpi_data'];
      if (tableInfo != null) {
        await ensureTableExists(
          'kpi_data',
          tableInfo['sql'] as String,
          tableInfo['indexes'] as List<String>,
        );
      }

      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.delete(
        'kpi_data',
        where: 'user_code = ?',
        whereArgs: [userCode],
      );

      await db.insert('kpi_data', {
        'user_code': userCode,
        'plan': kpiData.plan,
        'fact': kpiData.fact,
        'total_percent': kpiData.totalPercent,
        'total_forecast': kpiData.totalForecast,
        'total_percent_forecast_fact': kpiData.totalPercentForecastFact,
        'akb_plan': kpiData.akbPlan,
        'akb_fact': kpiData.akbFact,
        'akb_percent': kpiData.akbPercent,
        'okb': kpiData.okb,
        'update_date': kpiData.updateDate,
        'created_at': now,
      });

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Successfully saved KPI data for user: $userCode',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error saving KPI data for user $userCode: $e',
        );
      }
      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }

  Future<KpiData?> getKpiData(String userCode) async {
    try {
      if (kDebugMode) {
        print('ApiDatabaseService: Getting KPI data for user: $userCode');
      }

      // Ensure table exists before querying
      final tableInfo = getTableCreationSql()['kpi_data'];
      if (tableInfo != null) {
        await ensureTableExists(
          'kpi_data',
          tableInfo['sql'] as String,
          tableInfo['indexes'] as List<String>,
        );
      }

      final db = await database;
      final result = await db.query(
        'kpi_data',
        where: 'user_code = ?',
        whereArgs: [userCode],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (kDebugMode) {
        print(
          'ApiDatabaseService: KPI query result isEmpty: ${result.isEmpty}',
        );
      }

      if (result.isEmpty) return null;

      final row = result.first;
      if (kDebugMode) {
        print('ApiDatabaseService: KPI data row: $row');
      }

      return KpiData(
        plan: row['plan'] as String,
        fact: row['fact'] as String,
        totalPercent: row['total_percent'] as String,
        totalForecast: row['total_forecast'] as String,
        totalPercentForecastFact: row['total_percent_forecast_fact'] as String,
        akbPlan: row['akb_plan'] as String,
        akbFact: row['akb_fact'] as String,
        akbPercent: row['akb_percent'] as String,
        okb: row['okb'] as String,
        updateDate: row['update_date'] as String,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error getting KPI data for user $userCode: $e',
        );
      }
      return null;
    }
  }

  // Clients methods
  Future<void> saveClients(List<TradingPoint> clients) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing clients
    batch.delete('clients');

    // Deduplicate clients by code to avoid UNIQUE constraint violations
    final uniqueClients = <String, TradingPoint>{};
    for (final client in clients) {
      uniqueClients[client.id] = client;
    }

    // Add all inserts to batch
    for (final client in uniqueClients.values) {
      batch.insert('clients', {
        'code': client.id,
        'code_1c': client.code1c,
        'name': client.name,
        'address': client.address,
        'phone': client.phone,
        'inn': client.inn,
        'contact_person': client.contactPerson,
        'latitude': client.latitude,
        'longitude': client.longitude,
        'region': client.region,
        'district': client.district,
        'status': client.status,
        'last_visit_date': client.lastVisitDate,
        'has_orders': client.hasOrders ? 1 : 0,
        'has_contracts': client.hasContracts ? 1 : 0,
        'is_visited': client.isVisited ? 1 : 0,
        'has_contract': client.hasContract ? 1 : 0,
        'owner_name': client.ownerName,
        'signboard': client.signboard,
        'reference_point': client.referencePoint,
        'responsible_person': client.responsiblePerson,
        'responsible_person_phone': client.responsiblePersonPhone,
        'trade_point_type': client.tradePointType,
        'credit_limit': client.creditLimit,
        'accumulated_credit': client.accumulatedCredit,
        'code_region': client.codeRegion,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  /// Save clients with delta sync - only insert/update/delete changed records.
  ///
  /// Performance: O(n) where n = changed records, not total records.
  /// Memory: O(m) where m = existing codes set size.
  ///
  /// Returns statistics about the sync operation.
  Future<Map<String, int>> saveClientsIncremental(
    List<TradingPoint> clients,
  ) async {
    final stopwatch = Stopwatch()..start();
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Get existing client codes - O(n) query, minimal memory
    final existingRows = await db.rawQuery('SELECT code FROM clients');
    final existingCodes = existingRows.map((r) => r['code'] as String).toSet();

    // Deduplicate incoming clients
    final uniqueClients = <String, TradingPoint>{};
    for (final client in clients) {
      uniqueClients[client.id] = client;
    }
    final newCodes = uniqueClients.keys.toSet();

    // Calculate deltas
    final toDelete = existingCodes.difference(newCodes);
    final toInsert = newCodes.difference(existingCodes);
    final toUpdate = newCodes.intersection(existingCodes);

    int insertedCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;

    // Use batch for efficiency
    final batch = db.batch();

    // Delete removed clients
    if (toDelete.isNotEmpty) {
      for (final code in toDelete) {
        batch.delete('clients', where: 'code = ?', whereArgs: [code]);
        deletedCount++;
      }
    }

    // Insert new clients
    for (final code in toInsert) {
      final client = uniqueClients[code]!;
      batch.insert('clients', {
        'code': client.id,
        'code_1c': client.code1c,
        'name': client.name,
        'address': client.address,
        'phone': client.phone,
        'inn': client.inn,
        'contact_person': client.contactPerson,
        'latitude': client.latitude,
        'longitude': client.longitude,
        'region': client.region,
        'district': client.district,
        'status': client.status,
        'last_visit_date': client.lastVisitDate,
        'has_orders': client.hasOrders ? 1 : 0,
        'has_contracts': client.hasContracts ? 1 : 0,
        'is_visited': client.isVisited ? 1 : 0,
        'has_contract': client.hasContract ? 1 : 0,
        'owner_name': client.ownerName,
        'signboard': client.signboard,
        'reference_point': client.referencePoint,
        'responsible_person': client.responsiblePerson,
        'responsible_person_phone': client.responsiblePersonPhone,
        'trade_point_type': client.tradePointType,
        'credit_limit': client.creditLimit,
        'accumulated_credit': client.accumulatedCredit,
        'code_region': client.codeRegion,
        'created_at': now,
        'updated_at': now,
      });
      insertedCount++;
    }

    // Update existing clients (only update if needed)
    for (final code in toUpdate) {
      final client = uniqueClients[code]!;
      batch.update(
        'clients',
        {
          'code_1c': client.code1c,
          'name': client.name,
          'address': client.address,
          'phone': client.phone,
          'inn': client.inn,
          'contact_person': client.contactPerson,
          'latitude': client.latitude,
          'longitude': client.longitude,
          'region': client.region,
          'district': client.district,
          'status': client.status,
          'last_visit_date': client.lastVisitDate,
          'has_orders': client.hasOrders ? 1 : 0,
          'has_contracts': client.hasContracts ? 1 : 0,
          'is_visited': client.isVisited ? 1 : 0,
          'has_contract': client.hasContract ? 1 : 0,
          'owner_name': client.ownerName,
          'signboard': client.signboard,
          'reference_point': client.referencePoint,
          'responsible_person': client.responsiblePerson,
          'responsible_person_phone': client.responsiblePersonPhone,
          'trade_point_type': client.tradePointType,
          'credit_limit': client.creditLimit,
          'accumulated_credit': client.accumulatedCredit,
          'code_region': client.codeRegion,
          'updated_at': now,
        },
        where: 'code = ?',
        whereArgs: [code],
      );
      updatedCount++;
    }

    await batch.commit(noResult: true);
    stopwatch.stop();

    if (kDebugMode) {
      print(
        '[DeltaSync] Clients: +$insertedCount, ~$updatedCount, -$deletedCount (${stopwatch.elapsedMilliseconds}ms)',
      );
    }

    return {
      'inserted': insertedCount,
      'updated': updatedCount,
      'deleted': deletedCount,
      'duration_ms': stopwatch.elapsedMilliseconds,
    };
  }

  Future<List<TradingPoint>> getClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'name ASC');

    // Helper function for safe double parsing from database
    double _safeParseDoubleFromDb(
      dynamic value,
      String fieldName,
      String clientCode,
    ) {
      if (value == null) return 0.0;

      // Handle different types safely
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is num) return value.toDouble();

      // Log warning for unexpected types
      if (kDebugMode)
        print(
          'Warning: Unexpected type for $fieldName in client $clientCode: ${value.runtimeType} = $value',
        );
      return 0.0;
    }

    return result
        .map(
          (row) => TradingPoint(
            id: row['code'] as String,
            name: row['name'] as String,
            address: row['address'] as String,
            phone: row['phone'] as String? ?? '',
            ownerName: row['owner_name'] as String? ?? '',
            contactPerson: row['contact_person'] as String? ?? '',
            inn: row['inn'] as String? ?? '',
            status: row['status'] as String? ?? 'active',
            lastVisitDate: row['last_visit_date'] as String? ?? '',
            hasOrders: (row['has_orders'] as int?) == 1,
            hasContracts: (row['has_contracts'] as int?) == 1,
            isVisited: (row['is_visited'] as int?) == 1,
            hasContract: (row['has_contract'] as int?) == 1,
            latitude: _safeParseDoubleFromDb(
              row['latitude'],
              'latitude',
              row['code'] as String,
            ),
            longitude: _safeParseDoubleFromDb(
              row['longitude'],
              'longitude',
              row['code'] as String,
            ),
            region: row['region'] as String? ?? '',
            district: row['district'] as String? ?? '',
            signboard: row['signboard'] as String? ?? '',
            referencePoint: row['reference_point'] as String? ?? '',
            responsiblePerson: row['responsible_person'] as String? ?? '',
            responsiblePersonPhone:
                row['responsible_person_phone'] as String? ?? '',
            tradePointType: row['trade_point_type'] as String? ?? '',
            creditLimit: _safeParseDoubleFromDb(
              row['credit_limit'],
              'creditLimit',
              row['code'] as String,
            ),
            accumulatedCredit: _safeParseDoubleFromDb(
              row['accumulated_credit'],
              'accumulatedCredit',
              row['code'] as String,
            ),
            codeRegion: row['code_region'] as String? ?? '',
            code: row['code'] as String,
            code1c: row['code_1c'] as String? ?? '',
          ),
        )
        .toList();
  }

  /// Get unique trade point types from existing clients
  /// Uses SQL DISTINCT for O(n) efficiency - fastest way to get unique values
  Future<List<String>> getUniqueTradePointTypes() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT DISTINCT trade_point_type FROM clients WHERE trade_point_type IS NOT NULL AND trade_point_type != '' ORDER BY trade_point_type ASC",
    );
    return result.map((row) => row['trade_point_type'] as String).toList();
  }

  // Products methods
  Future<void> saveProducts(List<ProductData> products) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing products
    batch.delete('products');

    // Deduplicate products by code to avoid UNIQUE constraint violations
    final uniqueProducts = <String, ProductData>{};
    for (final product in products) {
      uniqueProducts[product.code] = product;
    }

    // Add all inserts to batch
    for (final product in uniqueProducts.values) {
      batch.insert('products', {
        'code': product.code,
        'name': product.name,
        'unit': product.unit,
        'quantity': product.quantity,
        'reserved': product.reserved,
        'available': product.available,
        'category': product.category,
        'barcode': product.barcode,
        'have': product.have,
        'warehouse_code': product.warehouseCode,
        'weight': product.weight,
        'capacity': product.capacity,
        'vendor_code': product.vendorCode,
        'product_brand': product.productBrand,
        'product_series': product.productSeries,
        'code_project': product.codeProject,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  /// Save products with delta sync - only insert/update/delete changed records.
  ///
  /// Performance: O(n) where n = changed records, not total records.
  /// Memory: O(m) where m = existing codes set size.
  ///
  /// Returns statistics about the sync operation.
  Future<Map<String, int>> saveProductsIncremental(
    List<ProductData> products,
  ) async {
    final stopwatch = Stopwatch()..start();
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Get existing product codes - O(n) query, minimal memory
    final existingRows = await db.rawQuery('SELECT code FROM products');
    final existingCodes = existingRows.map((r) => r['code'] as String).toSet();

    // Deduplicate incoming products
    final uniqueProducts = <String, ProductData>{};
    for (final product in products) {
      uniqueProducts[product.code] = product;
    }
    final newCodes = uniqueProducts.keys.toSet();

    // Calculate deltas
    final toDelete = existingCodes.difference(newCodes);
    final toInsert = newCodes.difference(existingCodes);
    final toUpdate = newCodes.intersection(existingCodes);

    int insertedCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;

    // Use batch for efficiency
    final batch = db.batch();

    // Delete removed products
    if (toDelete.isNotEmpty) {
      for (final code in toDelete) {
        batch.delete('products', where: 'code = ?', whereArgs: [code]);
        deletedCount++;
      }
    }

    // Insert new products
    for (final code in toInsert) {
      final product = uniqueProducts[code]!;
      batch.insert('products', {
        'code': product.code,
        'name': product.name,
        'unit': product.unit,
        'quantity': product.quantity,
        'reserved': product.reserved,
        'available': product.available,
        'category': product.category,
        'barcode': product.barcode,
        'have': product.have,
        'warehouse_code': product.warehouseCode,
        'weight': product.weight,
        'capacity': product.capacity,
        'vendor_code': product.vendorCode,
        'product_brand': product.productBrand,
        'product_series': product.productSeries,
        'code_project': product.codeProject,
        'created_at': now,
        'updated_at': now,
      });
      insertedCount++;
    }

    // Update existing products
    for (final code in toUpdate) {
      final product = uniqueProducts[code]!;
      batch.update(
        'products',
        {
          'name': product.name,
          'unit': product.unit,
          'quantity': product.quantity,
          'reserved': product.reserved,
          'available': product.available,
          'category': product.category,
          'barcode': product.barcode,
          'have': product.have,
          'warehouse_code': product.warehouseCode,
          'weight': product.weight,
          'capacity': product.capacity,
          'vendor_code': product.vendorCode,
          'product_brand': product.productBrand,
          'product_series': product.productSeries,
          'code_project': product.codeProject,
          'updated_at': now,
        },
        where: 'code = ?',
        whereArgs: [code],
      );
      updatedCount++;
    }

    await batch.commit(noResult: true);
    stopwatch.stop();

    if (kDebugMode) {
      print(
        '[DeltaSync] Products: +$insertedCount, ~$updatedCount, -$deletedCount (${stopwatch.elapsedMilliseconds}ms)',
      );
    }

    return {
      'inserted': insertedCount,
      'updated': updatedCount,
      'deleted': deletedCount,
      'duration_ms': stopwatch.elapsedMilliseconds,
    };
  }

  Future<List<ProductData>> getProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'name ASC');

    return result
        .map(
          (row) => ProductData(
            code: row['code'] as String,
            name: row['name'] as String,
            unit: row['unit'] as String,
            quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
            reserved: (row['reserved'] as num?)?.toDouble() ?? 0.0,
            available: (row['available'] as num?)?.toDouble() ?? 0.0,
            category: row['category'] as String? ?? '',
            barcode: row['barcode'] as String? ?? '',
            have: (row['have'] as int?) ?? 0,
            warehouseCode: row['warehouse_code'] as String? ?? '',
            weight: (row['weight'] as num?)?.toDouble() ?? 0.0,
            capacity: (row['capacity'] as num?)?.toDouble() ?? 0.0,
            vendorCode: row['vendor_code'] as String? ?? '',
            productBrand: row['product_brand'] as String? ?? '',
            productSeries: row['product_series'] as String? ?? '',
            codeProject: row['code_project'] as String? ?? '',
          ),
        )
        .toList();
  }

  /// Get a single product by its code
  ///
  /// Returns ProductData if found, null otherwise.
  /// Used for displaying product details in promotion product/bonus cards.
  Future<ProductData?> getProductByCode(String productCode) async {
    if (productCode.isEmpty) return null;

    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'code = ?',
        whereArgs: [productCode],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return ProductData(
        code: row['code'] as String,
        name: row['name'] as String,
        unit: row['unit'] as String,
        quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
        reserved: (row['reserved'] as num?)?.toDouble() ?? 0.0,
        available: (row['available'] as num?)?.toDouble() ?? 0.0,
        category: row['category'] as String? ?? '',
        barcode: row['barcode'] as String? ?? '',
        have: (row['have'] as int?) ?? 0,
        warehouseCode: row['warehouse_code'] as String? ?? '',
        weight: (row['weight'] as num?)?.toDouble() ?? 0.0,
        capacity: (row['capacity'] as num?)?.toDouble() ?? 0.0,
        vendorCode: row['vendor_code'] as String? ?? '',
        productBrand: row['product_brand'] as String? ?? '',
        productSeries: row['product_series'] as String? ?? '',
        codeProject: row['code_project'] as String? ?? '',
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error getting product by code $productCode: $e',
        );
      }
      return null;
    }
  }

  // Price types methods
  Future<void> savePriceTypes(List<PriceType> priceTypes) async {
    // Validate input data
    if (priceTypes.isEmpty) {
      return; // Nothing to save
    }

    // Validate each price type
    for (final priceType in priceTypes) {
      if (priceType.code.isEmpty) {
        throw ArgumentError('PriceType code cannot be empty');
      }
      if (priceType.name.isEmpty) {
        throw ArgumentError('PriceType name cannot be empty');
      }
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing price types
    batch.delete('price_types');

    // Deduplicate price types by code to avoid UNIQUE constraint violations
    final uniquePriceTypes = <String, PriceType>{};
    for (final priceType in priceTypes) {
      uniquePriceTypes[priceType.code] = priceType;
    }

    // Add all inserts to batch
    for (final priceType in uniquePriceTypes.values) {
      batch.insert('price_types', {
        'code': priceType.code,
        'name': priceType.name,
        'description': priceType.description,
        'is_default': priceType.isDefault ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<PriceType>> getPriceTypes() async {
    final db = await database;
    final result = await db.query('price_types', orderBy: 'name ASC');

    return result
        .map(
          (row) => PriceType(
            code: row['code'] as String,
            name: row['name'] as String,
            description: row['description'] as String? ?? '',
            isDefault: (row['is_default'] as int?) == 1,
          ),
        )
        .toList();
  }

  /// Get price type by code
  /// Returns null if not found
  Future<PriceType?> getPriceTypeByCode(String code) async {
    if (code.isEmpty) return null;

    final db = await database;
    final result = await db.query(
      'price_types',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return PriceType(
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      isDefault: (row['is_default'] as int?) == 1,
    );
  }

  /// Get price type name by code with fallback logic
  /// Returns: price type name if found, 'Bonus' if price is 0, or code as fallback
  Future<String> getPriceTypeDisplayName(
    String code, {
    double price = 0,
  }) async {
    if (code.isEmpty) {
      return price == 0 ? 'Bonus' : '';
    }

    final priceType = await getPriceTypeByCode(code);
    if (priceType != null && priceType.name.isNotEmpty) {
      return priceType.name;
    }

    // Fallback: if price is 0, show "Bonus", otherwise show code
    return price == 0 ? 'Bonus' : code;
  }

  // Product prices methods
  Future<void> saveProductPrices(List<ProductPrice> productPrices) async {
    // Validate input data
    if (productPrices.isEmpty) {
      return; // Nothing to save
    }

    // Validate each product price
    for (final productPrice in productPrices) {
      if (productPrice.productCode.isEmpty) {
        throw ArgumentError('ProductPrice productCode cannot be empty');
      }
      if (productPrice.priceTypeCode.isEmpty) {
        throw ArgumentError('ProductPrice priceTypeCode cannot be empty');
      }
      if (productPrice.price < 0) {
        throw ArgumentError('ProductPrice price cannot be negative');
      }
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing product prices
    batch.delete('product_prices');

    // Deduplicate product prices by (product_code, price_type_code) to avoid UNIQUE constraint violations
    final uniqueProductPrices = <String, ProductPrice>{};
    for (final productPrice in productPrices) {
      final key = '${productPrice.productCode}_${productPrice.priceTypeCode}';
      uniqueProductPrices[key] = productPrice;
    }

    // Add all inserts to batch
    for (final productPrice in uniqueProductPrices.values) {
      batch.insert('product_prices', {
        'product_code': productPrice.productCode,
        'price_type_code': productPrice.priceTypeCode,
        'price': productPrice.price,
        'currency': productPrice.currency,
        'valid_from': productPrice.validFrom,
        'valid_to': productPrice.validTo,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  /// Save product prices with delta sync - only insert/update/delete changed records.
  ///
  /// Performance: O(n) where n = changed records, not total records.
  /// Memory: O(m) where m = existing keys set size.
  ///
  /// Returns statistics about the sync operation.
  Future<Map<String, int>> saveProductPricesIncremental(
    List<ProductPrice> productPrices,
  ) async {
    final stopwatch = Stopwatch()..start();
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Get existing product price keys - O(n) query, minimal memory
    final existingRows = await db.rawQuery(
      'SELECT product_code, price_type_code FROM product_prices',
    );
    final existingKeys = existingRows
        .map((r) => '${r['product_code']}_${r['price_type_code']}')
        .toSet();

    // Deduplicate incoming product prices
    final uniquePrices = <String, ProductPrice>{};
    for (final price in productPrices) {
      final key = '${price.productCode}_${price.priceTypeCode}';
      uniquePrices[key] = price;
    }
    final newKeys = uniquePrices.keys.toSet();

    // Calculate deltas
    final toDelete = existingKeys.difference(newKeys);
    final toInsert = newKeys.difference(existingKeys);
    final toUpdate = newKeys.intersection(existingKeys);

    int insertedCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;

    // Use batch for efficiency
    final batch = db.batch();

    // Delete removed prices
    for (final key in toDelete) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final productCode = parts[0];
        final priceTypeCode = parts.sublist(1).join('_');
        batch.delete(
          'product_prices',
          where: 'product_code = ? AND price_type_code = ?',
          whereArgs: [productCode, priceTypeCode],
        );
        deletedCount++;
      }
    }

    // Insert new prices
    for (final key in toInsert) {
      final price = uniquePrices[key]!;
      batch.insert('product_prices', {
        'product_code': price.productCode,
        'price_type_code': price.priceTypeCode,
        'price': price.price,
        'currency': price.currency,
        'valid_from': price.validFrom,
        'valid_to': price.validTo,
        'created_at': now,
        'updated_at': now,
      });
      insertedCount++;
    }

    // Update existing prices
    for (final key in toUpdate) {
      final price = uniquePrices[key]!;
      batch.update(
        'product_prices',
        {
          'price': price.price,
          'currency': price.currency,
          'valid_from': price.validFrom,
          'valid_to': price.validTo,
          'updated_at': now,
        },
        where: 'product_code = ? AND price_type_code = ?',
        whereArgs: [price.productCode, price.priceTypeCode],
      );
      updatedCount++;
    }

    await batch.commit(noResult: true);
    stopwatch.stop();

    if (kDebugMode) {
      print(
        '[DeltaSync] ProductPrices: +$insertedCount, ~$updatedCount, -$deletedCount (${stopwatch.elapsedMilliseconds}ms)',
      );
    }

    return {
      'inserted': insertedCount,
      'updated': updatedCount,
      'deleted': deletedCount,
      'duration_ms': stopwatch.elapsedMilliseconds,
    };
  }

  Future<List<ProductPrice>> getProductPrices({String? priceTypeCode}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (priceTypeCode != null) {
      whereClause = 'WHERE price_type_code = ?';
      whereArgs = [priceTypeCode];
    }

    final result = await db.rawQuery('''
      SELECT * FROM product_prices 
      $whereClause
      ORDER BY product_code ASC
    ''', whereArgs);

    return result
        .map(
          (row) => ProductPrice(
            productCode: row['product_code'] as String,
            priceTypeCode: row['price_type_code'] as String,
            price: (row['price'] as num?)?.toDouble() ?? 0.0,
            currency: row['currency'] as String? ?? 'UZS',
            validFrom: row['valid_from'] as String? ?? '',
            validTo: row['valid_to'] as String? ?? '',
          ),
        )
        .toList();
  }

  // Promotions methods
  Future<void> savePromotions(List<PromotionModel> promotions) async {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode)
      print(
        '[$timestamp] DEBUG DB: savePromotions called with ${promotions.length} promotions',
      );

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing promotions and their products
    if (kDebugMode)
      print('[$timestamp] DEBUG DB: Deleting existing promotions and products');
    batch.delete('promotion_product_list');
    batch.delete('promotion_bonus_list');
    batch.delete('promotion_class_list');
    batch.delete('promotions');

    // Deduplicate promotions by code to avoid UNIQUE constraint violations
    final uniquePromotions = <String, PromotionModel>{};
    for (final promotion in promotions) {
      uniquePromotions[promotion.code] = promotion;
    }

    if (kDebugMode)
      print(
        '[$timestamp] DEBUG DB: After deduplication: ${uniquePromotions.length} unique promotions',
      );

    // Add all inserts to batch
    for (final promotion in uniquePromotions.values) {
      if (kDebugMode)
        print(
          '[$timestamp] DEBUG DB: Inserting promotion ${promotion.code}: ${promotion.name}',
        );
      batch.insert('promotions', {
        'code': promotion.code,
        'name': promotion.name,
        'type': promotion.type,
        'min_promo_product_count': promotion.minPromoProductCount,
        'bonus_count': promotion.bonusCount,
        'date_start': promotion.dateStart.toIso8601String(),
        'date_end': promotion.dateEnd.toIso8601String(),
        'last_synced': promotion.lastSynced?.toIso8601String(),
        'is_active': promotion.isActive ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });

      // Deduplicate product list by product_code
      final uniqueProductList = <String, PromotionProduct>{};
      for (final product in promotion.productList) {
        uniqueProductList[product.code] = product;
      }

      // Insert product list
      for (final product in uniqueProductList.values) {
        batch.insert('promotion_product_list', {
          'promotion_code': promotion.code,
          'product_code': product.code,
          'product_name': product.productName,
          'created_at': now,
        });
      }

      // Deduplicate bonus list by product_code
      final uniqueBonusList = <String, PromotionProduct>{};
      for (final bonus in promotion.bonusList) {
        uniqueBonusList[bonus.code] = bonus;
      }

      // Insert bonus list
      for (final bonus in uniqueBonusList.values) {
        batch.insert('promotion_bonus_list', {
          'promotion_code': promotion.code,
          'product_code': bonus.code,
          'product_name': bonus.productName,
          'created_at': now,
        });
      }

      // Deduplicate class list by class_code
      final uniqueClassList = <String, PromotionProduct>{};
      for (final classItem in promotion.classList) {
        uniqueClassList[classItem.code] = classItem;
      }

      // Insert class list
      for (final classItem in uniqueClassList.values) {
        batch.insert('promotion_class_list', {
          'promotion_code': promotion.code,
          'class_code': classItem.code,
          'class_name': classItem.productName,
          'created_at': now,
        });
      }

      if (kDebugMode)
        print(
          '[$timestamp] DEBUG DB: Promotion ${promotion.code} has ${uniqueProductList.length} unique products, ${uniqueBonusList.length} unique bonuses, and ${uniqueClassList.length} unique classes',
        );
    }

    // Execute batch operation
    if (kDebugMode) print('[$timestamp] DEBUG DB: Committing batch');
    await batch.commit(noResult: true);
    if (kDebugMode)
      print('[$timestamp] DEBUG DB: Batch committed successfully');
  }

  Future<List<PromotionModel>> getPromotions({
    bool onlyActive = true,
    String? searchQuery,
    DateTime? dateFilter,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode)
      print(
        '[$timestamp] DEBUG DB: getPromotions called, onlyActive: $onlyActive, searchQuery: $searchQuery, dateFilter: $dateFilter',
      );

    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (onlyActive) {
      whereClause += 'WHERE is_active = 1';
    }

    if (dateFilter != null) {
      final dateStr = dateFilter.toIso8601String().split('T')[0];
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      } else {
        whereClause = 'WHERE ';
      }
      whereClause += 'date_start <= ? AND date_end >= ?';
      whereArgs.addAll([dateStr, dateStr]);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      } else {
        whereClause = 'WHERE ';
      }
      whereClause += '(name LIKE ? OR code LIKE ?)';
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }

    if (kDebugMode)
      print(
        '[$timestamp] DEBUG DB: Query: SELECT * FROM promotions $whereClause with args: $whereArgs',
      );

    final promotionResults = await db.rawQuery('''
      SELECT * FROM promotions
      $whereClause
      ORDER BY date_start DESC, name ASC
    ''', whereArgs);

    if (kDebugMode)
      print(
        '[$timestamp] DEBUG DB: Found ${promotionResults.length} promotion records',
      );

    final promotions = <PromotionModel>[];

    for (final promoRow in promotionResults) {
      final promotionCode = promoRow['code'] as String;

      // Get product list for this promotion
      final productResults = await db.query(
        'promotion_product_list',
        where: 'promotion_code = ?',
        whereArgs: [promotionCode],
        orderBy: 'product_name ASC',
      );

      // Get bonus list for this promotion
      final bonusResults = await db.query(
        'promotion_bonus_list',
        where: 'promotion_code = ?',
        whereArgs: [promotionCode],
        orderBy: 'product_name ASC',
      );

      // Get class list for this promotion
      final classResults = await db.query(
        'promotion_class_list',
        where: 'promotion_code = ?',
        whereArgs: [promotionCode],
        orderBy: 'class_name ASC',
      );

      if (kDebugMode)
        print(
          '[$timestamp] DEBUG DB: Promotion $promotionCode has ${productResults.length} products, ${bonusResults.length} bonuses, ${classResults.length} classes',
        );

      final productList = productResults
          .map(
            (row) => PromotionProduct(
              code: row['product_code'] as String,
              productName: row['product_name'] as String,
            ),
          )
          .toList();

      final bonusList = bonusResults
          .map(
            (row) => PromotionProduct(
              code: row['product_code'] as String,
              productName: row['product_name'] as String,
            ),
          )
          .toList();

      final classList = classResults
          .map(
            (row) => PromotionProduct(
              code: row['class_code'] as String,
              productName: row['class_name'] as String,
            ),
          )
          .toList();

      promotions.add(
        PromotionModel(
          code: promoRow['code'] as String,
          name: promoRow['name'] as String,
          type: promoRow['type'] as String,
          minPromoProductCount: promoRow['min_promo_product_count'] as int,
          bonusCount: promoRow['bonus_count'] as int,
          dateStart: DateTime.parse(promoRow['date_start'] as String),
          dateEnd: DateTime.parse(promoRow['date_end'] as String),
          productList: productList,
          bonusList: bonusList,
          classList: classList,
          lastSynced: promoRow['last_synced'] != null
              ? DateTime.parse(promoRow['last_synced'] as String)
              : null,
          isActive: (promoRow['is_active'] as int) == 1,
        ),
      );
    }

    if (kDebugMode)
      print('[$timestamp] DEBUG DB: Returning ${promotions.length} promotions');
    return promotions;
  }

  Future<PromotionModel?> getPromotionByCode(String code) async {
    final db = await database;
    final results = await db.query(
      'promotions',
      where: 'code = ?',
      whereArgs: [code],
    );

    if (results.isEmpty) return null;

    final promoRow = results.first;
    final promotionCode = promoRow['code'] as String;

    // Get product list for this promotion
    final productResults = await db.query(
      'promotion_product_list',
      where: 'promotion_code = ?',
      whereArgs: [promotionCode],
      orderBy: 'product_name ASC',
    );

    // Get bonus list for this promotion
    final bonusResults = await db.query(
      'promotion_bonus_list',
      where: 'promotion_code = ?',
      whereArgs: [promotionCode],
      orderBy: 'product_name ASC',
    );

    // Get class list for this promotion
    final classResults = await db.query(
      'promotion_class_list',
      where: 'promotion_code = ?',
      whereArgs: [promotionCode],
      orderBy: 'class_name ASC',
    );

    final productList = productResults
        .map(
          (row) => PromotionProduct(
            code: row['product_code'] as String,
            productName: row['product_name'] as String,
          ),
        )
        .toList();

    final bonusList = bonusResults
        .map(
          (row) => PromotionProduct(
            code: row['product_code'] as String,
            productName: row['product_name'] as String,
          ),
        )
        .toList();

    final classList = classResults
        .map(
          (row) => PromotionProduct(
            code: row['class_code'] as String,
            productName: row['class_name'] as String,
          ),
        )
        .toList();

    return PromotionModel(
      code: promoRow['code'] as String,
      name: promoRow['name'] as String,
      type: promoRow['type'] as String,
      minPromoProductCount: promoRow['min_promo_product_count'] as int,
      bonusCount: promoRow['bonus_count'] as int,
      dateStart: DateTime.parse(promoRow['date_start'] as String),
      dateEnd: DateTime.parse(promoRow['date_end'] as String),
      productList: productList,
      bonusList: bonusList,
      classList: classList,
      lastSynced: promoRow['last_synced'] != null
          ? DateTime.parse(promoRow['last_synced'] as String)
          : null,
      isActive: (promoRow['is_active'] as int) == 1,
    );
  }

  Future<void> updatePromotionSyncTime(String code, DateTime syncTime) async {
    final db = await database;
    await db.update(
      'promotions',
      {
        'last_synced': syncTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<void> deletePromotion(String code) async {
    final db = await database;
    // Foreign key constraint will handle deleting related products
    await db.delete('promotions', where: 'code = ?', whereArgs: [code]);
  }

  Future<int> getPromotionCount({bool onlyActive = true}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM promotions
      ${onlyActive ? 'WHERE is_active = 1' : ''}
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Business regions methods
  Future<void> saveBusinessRegions(List<BusinessRegion> regions) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing regions
    batch.delete('business_regions');

    // Deduplicate regions by code to avoid UNIQUE constraint violations
    final uniqueRegions = <String, BusinessRegion>{};
    for (final region in regions) {
      uniqueRegions[region.code] = region;
    }

    // Add all inserts to batch
    for (final region in uniqueRegions.values) {
      batch.insert('business_regions', {
        'code': region.code,
        'name': region.name,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<BusinessRegion>> getBusinessRegions() async {
    final db = await database;
    final result = await db.query('business_regions', orderBy: 'name ASC');

    return result
        .map(
          (row) => BusinessRegion(
            code: row['code'] as String,
            name: row['name'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  Future<BusinessRegion?> getBusinessRegionByCode(String code) async {
    final db = await database;
    final result = await db.query(
      'business_regions',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return BusinessRegion(
      code: row['code'] as String,
      name: row['name'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<void> saveBusinessRegion(BusinessRegion region) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('business_regions', {
      'code': region.code,
      'name': region.name,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBusinessRegion(String code, BusinessRegion region) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'business_regions',
      {'name': region.name, 'updated_at': now},
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<void> deleteBusinessRegion(String code) async {
    final db = await database;
    await db.delete('business_regions', where: 'code = ?', whereArgs: [code]);
  }

  // User warehouses methods
  Future<void> saveUserWarehouses(List<UserWarehouse> warehouses) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing warehouses
    batch.delete('user_warehouses');

    // Deduplicate warehouses by code to avoid UNIQUE constraint violations
    final uniqueWarehouses = <String, UserWarehouse>{};
    for (final warehouse in warehouses) {
      uniqueWarehouses[warehouse.code] = warehouse;
    }

    // Add all inserts to batch
    for (final warehouse in uniqueWarehouses.values) {
      batch.insert('user_warehouses', {
        'code': warehouse.code,
        'name': warehouse.name,
        'organization': warehouse.organization,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<UserWarehouse>> getUserWarehouses() async {
    final db = await database;
    final result = await db.query('user_warehouses', orderBy: 'name ASC');

    return result
        .map(
          (row) => UserWarehouse(
            code: row['code'] as String,
            name: row['name'] as String,
            organization: row['organization'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  Future<UserWarehouse?> getUserWarehouseByCode(String code) async {
    final db = await database;
    final result = await db.query(
      'user_warehouses',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return UserWarehouse(
      code: row['code'] as String,
      name: row['name'] as String,
      organization: row['organization'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<void> saveUserWarehouse(UserWarehouse warehouse) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('user_warehouses', {
      'code': warehouse.code,
      'name': warehouse.name,
      'organization': warehouse.organization,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUserWarehouse(String code, UserWarehouse warehouse) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'user_warehouses',
      {
        'name': warehouse.name,
        'organization': warehouse.organization,
        'updated_at': now,
      },
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<void> deleteUserWarehouse(String code) async {
    final db = await database;
    await db.delete('user_warehouses', where: 'code = ?', whereArgs: [code]);
  }

  // Product brands methods
  Future<void> saveProductBrands(List<ProductBrand> brands) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing brands
    batch.delete('product_brands');

    // Deduplicate brands by name to avoid UNIQUE constraint violations
    final uniqueBrands = <String, ProductBrand>{};
    for (final brand in brands) {
      uniqueBrands[brand.name] = brand;
    }

    // Add all inserts to batch
    for (final brand in uniqueBrands.values) {
      batch.insert('product_brands', {
        'name': brand.name,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<ProductBrand>> getProductBrands() async {
    final db = await database;
    final result = await db.query('product_brands', orderBy: 'name ASC');

    return result
        .map(
          (row) => ProductBrand(
            name: row['name'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  Future<ProductBrand?> getProductBrandByName(String name) async {
    final db = await database;
    final result = await db.query(
      'product_brands',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return ProductBrand(
      name: row['name'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<void> saveProductBrand(ProductBrand brand) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('product_brands', {
      'name': brand.name,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProductBrand(String name, ProductBrand brand) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'product_brands',
      {'name': brand.name, 'updated_at': now},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<void> deleteProductBrand(String name) async {
    final db = await database;
    await db.delete('product_brands', where: 'name = ?', whereArgs: [name]);
  }

  // Product series methods
  Future<void> saveProductSeries(List<ProductSeries> series) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing series
    batch.delete('product_series');

    // Deduplicate series by (name, brand_name) to avoid UNIQUE constraint violations
    final uniqueSeries = <String, ProductSeries>{};
    for (final serie in series) {
      final key = '${serie.name}_${serie.brandName}';
      uniqueSeries[key] = serie;
    }

    // Add all inserts to batch
    for (final serie in uniqueSeries.values) {
      batch.insert('product_series', {
        'name': serie.name,
        'brand_name': serie.brandName,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<ProductSeries>> getProductSeries({String? brandName}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (brandName != null) {
      whereClause = 'WHERE brand_name = ?';
      whereArgs = [brandName];
    }

    final result = await db.rawQuery('''
      SELECT * FROM product_series
      $whereClause
      ORDER BY brand_name ASC, name ASC
    ''', whereArgs);

    return result
        .map(
          (row) => ProductSeries(
            name: row['name'] as String,
            brandName: row['brand_name'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  Future<ProductSeries?> getProductSeriesByNameAndBrand(
    String name,
    String brandName,
  ) async {
    final db = await database;
    final result = await db.query(
      'product_series',
      where: 'name = ? AND brand_name = ?',
      whereArgs: [name, brandName],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return ProductSeries(
      name: row['name'] as String,
      brandName: row['brand_name'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<void> saveProductSerie(ProductSeries series) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('product_series', {
      'name': series.name,
      'brand_name': series.brandName,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProductSeries(
    String name,
    String brandName,
    ProductSeries series,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'product_series',
      {'name': series.name, 'brand_name': series.brandName, 'updated_at': now},
      where: 'name = ? AND brand_name = ?',
      whereArgs: [name, brandName],
    );
  }

  Future<void> deleteProductSeries(String name, String brandName) async {
    final db = await database;
    await db.delete(
      'product_series',
      where: 'name = ? AND brand_name = ?',
      whereArgs: [name, brandName],
    );
  }

  // Product balances methods
  Future<void> saveProductBalances(List<ProductBalance> balances) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing balances
    batch.delete('product_balances');

    // Deduplicate balances by (code_sklad, code_product) to avoid UNIQUE constraint violations
    final uniqueBalances = <String, ProductBalance>{};
    for (final balance in balances) {
      final key = '${balance.codeSklad}_${balance.codeProduct}';
      uniqueBalances[key] = balance;
    }

    // Add all inserts to batch
    for (final balance in uniqueBalances.values) {
      batch.insert('product_balances', {
        'code_sklad': balance.codeSklad,
        'code_product': balance.codeProduct,
        'name_product': balance.nameProduct,
        'have': balance.have,
        'reserved': balance.reserved,
        'available': balance.available,
        'weight': balance.weight,
        'capacity': balance.capacity,
        'code_project': balance.codeProject,
        'vendor_code': balance.vendorCode,
        'product_brand': balance.productBrand,
        'product_series': balance.productSeries,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  /// Save product balances with delta sync - only insert/update/delete changed records.
  ///
  /// Performance: O(n) where n = changed records, not total records.
  /// Memory: O(m) where m = existing keys set size.
  ///
  /// Returns statistics about the sync operation.
  Future<Map<String, int>> saveProductBalancesIncremental(
    List<ProductBalance> balances,
  ) async {
    final stopwatch = Stopwatch()..start();
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Get existing balance keys - O(n) query, minimal memory
    final existingRows = await db.rawQuery(
      'SELECT code_sklad, code_product FROM product_balances',
    );
    final existingKeys = existingRows
        .map((r) => '${r['code_sklad']}_${r['code_product']}')
        .toSet();

    // Deduplicate incoming balances
    final uniqueBalances = <String, ProductBalance>{};
    for (final balance in balances) {
      final key = '${balance.codeSklad}_${balance.codeProduct}';
      uniqueBalances[key] = balance;
    }
    final newKeys = uniqueBalances.keys.toSet();

    // Calculate deltas
    final toDelete = existingKeys.difference(newKeys);
    final toInsert = newKeys.difference(existingKeys);
    final toUpdate = newKeys.intersection(existingKeys);

    int insertedCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;

    // Use batch for efficiency
    final batch = db.batch();

    // Delete removed balances
    for (final key in toDelete) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final codeSklad = parts[0];
        final codeProduct = parts.sublist(1).join('_');
        batch.delete(
          'product_balances',
          where: 'code_sklad = ? AND code_product = ?',
          whereArgs: [codeSklad, codeProduct],
        );
        deletedCount++;
      }
    }

    // Insert new balances
    for (final key in toInsert) {
      final balance = uniqueBalances[key]!;
      batch.insert('product_balances', {
        'code_sklad': balance.codeSklad,
        'code_product': balance.codeProduct,
        'name_product': balance.nameProduct,
        'have': balance.have,
        'reserved': balance.reserved,
        'available': balance.available,
        'weight': balance.weight,
        'capacity': balance.capacity,
        'code_project': balance.codeProject,
        'vendor_code': balance.vendorCode,
        'product_brand': balance.productBrand,
        'product_series': balance.productSeries,
        'created_at': now,
        'updated_at': now,
      });
      insertedCount++;
    }

    // Update existing balances
    for (final key in toUpdate) {
      final balance = uniqueBalances[key]!;
      batch.update(
        'product_balances',
        {
          'name_product': balance.nameProduct,
          'have': balance.have,
          'reserved': balance.reserved,
          'available': balance.available,
          'weight': balance.weight,
          'capacity': balance.capacity,
          'code_project': balance.codeProject,
          'vendor_code': balance.vendorCode,
          'product_brand': balance.productBrand,
          'product_series': balance.productSeries,
          'updated_at': now,
        },
        where: 'code_sklad = ? AND code_product = ?',
        whereArgs: [balance.codeSklad, balance.codeProduct],
      );
      updatedCount++;
    }

    await batch.commit(noResult: true);
    stopwatch.stop();

    if (kDebugMode) {
      print(
        '[DeltaSync] ProductBalances: +$insertedCount, ~$updatedCount, -$deletedCount (${stopwatch.elapsedMilliseconds}ms)',
      );
    }

    return {
      'inserted': insertedCount,
      'updated': updatedCount,
      'deleted': deletedCount,
      'duration_ms': stopwatch.elapsedMilliseconds,
    };
  }

  Future<List<ProductBalance>> getProductBalances({
    String? warehouseCode,
    String? productBrand,
    String? productSeries,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (warehouseCode != null) {
      conditions.add('code_sklad = ?');
      whereArgs.add(warehouseCode);
    }
    if (productBrand != null) {
      conditions.add('product_brand = ?');
      whereArgs.add(productBrand);
    }
    if (productSeries != null) {
      conditions.add('product_series = ?');
      whereArgs.add(productSeries);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery('''
      SELECT * FROM product_balances
      $whereClause
      ORDER BY code_sklad ASC, product_brand ASC, product_series ASC, name_product ASC
    ''', whereArgs);

    return result
        .map(
          (row) => ProductBalance(
            codeSklad: row['code_sklad'] as String,
            codeProduct: row['code_product'] as String,
            nameProduct: row['name_product'] as String,
            have: row['have'] as int,
            reserved: row['reserved'] as int,
            available: row['available'] as int,
            weight: row['weight'] as double,
            capacity: row['capacity'] as double,
            codeProject: row['code_project'] as String,
            vendorCode: row['vendor_code'] as String,
            productBrand: row['product_brand'] as String,
            productSeries: row['product_series'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  Future<ProductBalance?> getProductBalanceByCodes(
    String warehouseCode,
    String productCode,
  ) async {
    final db = await database;
    final result = await db.query(
      'product_balances',
      where: 'code_sklad = ? AND code_product = ?',
      whereArgs: [warehouseCode, productCode],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return ProductBalance(
      codeSklad: row['code_sklad'] as String,
      codeProduct: row['code_product'] as String,
      nameProduct: row['name_product'] as String,
      have: row['have'] as int,
      reserved: row['reserved'] as int,
      available: row['available'] as int,
      weight: row['weight'] as double,
      capacity: row['capacity'] as double,
      codeProject: row['code_project'] as String,
      vendorCode: row['vendor_code'] as String,
      productBrand: row['product_brand'] as String,
      productSeries: row['product_series'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<void> saveProductBalance(ProductBalance balance) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('product_balances', {
      'code_sklad': balance.codeSklad,
      'code_product': balance.codeProduct,
      'name_product': balance.nameProduct,
      'have': balance.have,
      'reserved': balance.reserved,
      'available': balance.available,
      'weight': balance.weight,
      'capacity': balance.capacity,
      'code_project': balance.codeProject,
      'vendor_code': balance.vendorCode,
      'product_brand': balance.productBrand,
      'product_series': balance.productSeries,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProductBalance(
    String warehouseCode,
    String productCode,
    ProductBalance balance,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'product_balances',
      {
        'code_sklad': balance.codeSklad,
        'code_product': balance.codeProduct,
        'name_product': balance.nameProduct,
        'have': balance.have,
        'reserved': balance.reserved,
        'available': balance.available,
        'weight': balance.weight,
        'capacity': balance.capacity,
        'code_project': balance.codeProject,
        'vendor_code': balance.vendorCode,
        'product_brand': balance.productBrand,
        'product_series': balance.productSeries,
        'updated_at': now,
      },
      where: 'code_sklad = ? AND code_product = ?',
      whereArgs: [warehouseCode, productCode],
    );
  }

  Future<void> deleteProductBalance(
    String warehouseCode,
    String productCode,
  ) async {
    final db = await database;
    await db.delete(
      'product_balances',
      where: 'code_sklad = ? AND code_product = ?',
      whereArgs: [warehouseCode, productCode],
    );
  }

  /// Get cached trading points with permissions and visit data using optimized JOIN query
  Future<List<TradingPointWithPermissions>> getTradingPointsWithPermissions(
    String userCode,
  ) async {
    try {
      // Ensure tables exist before query to prevent "no such table" errors
      await ensureSalesReqPermissionsTableExists();

      final db = await database;

      // Joriy hafta kunini aniqlash
      final now = DateTime.now();
      final currentWeekdayCode = now.weekday; // 1 = Monday, 7 = Sunday

      if (kDebugMode) {
        print(
          'DEBUG: Getting trading points for user: $userCode, weekday: $currentWeekdayCode',
        );
      }

      final result = await db.rawQuery(
        '''
        SELECT
          c.*,
          srp.id as permissions_id,
          srp.user_code,
          srp.skip_tin_duplicate_check,
          srp.allow_creation_without_tin,
          srp.visit,
          srp.strict_sequence,
          srp.unplanned_order,
          srp.planned_route,
          srp.edit_client_coordinates,
          srp.client_zone_access,
          srp.location_update_interval,
          CASE WHEN pr.code_client IS NOT NULL THEN 1 ELSE 0 END as visit_today,
          COALESCE(pr.visit_order, 0) as visit_step_number,
          pr.week_day as planned_week_day
        FROM clients c
        LEFT JOIN sales_req_permissions srp ON srp.user_code = ?
        LEFT JOIN (
          SELECT
            pr1.code_client,
            (SELECT COUNT(*) FROM planned_routes pr2 
             WHERE pr2.user_code = pr1.user_code 
             AND pr2.code_weekday = pr1.code_weekday 
             AND pr2.id <= pr1.id) as visit_order,
            pr1.week_day
          FROM planned_routes pr1
          WHERE pr1.user_code = ? AND pr1.code_weekday = ?
        ) pr ON c.code = pr.code_client
        ORDER BY c.name ASC''',
        [userCode, userCode, currentWeekdayCode],
      );
      if (kDebugMode) {
        print('DEBUG: Query returned ${result.length} trading points');
        if (result.isNotEmpty) {
          final sample = result.first;
          print(
            'DEBUG: Sample result - visit_today: ${sample['visit_today']}, visit_step_number: ${sample['visit_step_number']}',
          );
        }
      }

      final tradingPoints = result.map((row) {
        try {
          return TradingPointWithPermissions.fromMap(row);
        } catch (e) {
          if (kDebugMode) {
            print(
              'ERROR: Failed to parse TradingPointWithPermissions from row: $row, error: $e',
            );
          }
          rethrow;
        }
      }).toList();

      if (kDebugMode) {
        print(
          'DEBUG: Successfully parsed ${tradingPoints.length} TradingPointWithPermissions objects',
        );
      }

      return tradingPoints;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get trading points with permissions: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  // Optimized method to get products with prices using JOINs
  Future<List<ProductWithPrice>> getProductsWithPrices({
    required String priceTypeCode,
    List<String>? warehouseCodes,
    String? searchQuery,
    String? codeProject,
  }) async {
    if (kDebugMode) {
      print('DEBUG: ApiDatabaseService.getProductsWithPrices called');
      print('DEBUG: priceTypeCode = $priceTypeCode');
      print('DEBUG: warehouseCodes = $warehouseCodes');
      print('DEBUG: searchQuery = $searchQuery');
      print('DEBUG: codeProject = $codeProject');
    }

    final db = await database;

    // Build WHERE conditions
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    // Always filter by price type
    whereConditions.add('pp.price_type_code = ?');
    whereArgs.add(priceTypeCode);

    // Filter by project code if provided and not empty
    if (codeProject != null && codeProject.trim().isNotEmpty) {
      whereConditions.add('p.code_project = ?');
      whereArgs.add(codeProject.trim());
    }

    // Filter by warehouse codes if provided and not empty
    if (warehouseCodes != null &&
        warehouseCodes.isNotEmpty &&
        warehouseCodes.any((w) => w.trim().isNotEmpty)) {
      final validCodes = warehouseCodes
          .where((w) => w.trim().isNotEmpty)
          .toList();
      if (validCodes.isNotEmpty) {
        final placeholders = List.filled(validCodes.length, '?').join(', ');
        whereConditions.add('p.warehouse_code IN ($placeholders)');
        whereArgs.addAll(validCodes);
      }
    }

    // Build search condition if provided
    String searchCondition = '';
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final trimmedQuery = searchQuery.trim();
      searchCondition = '''
        AND (
          p.name LIKE ? OR
          p.code LIKE ? OR
          pt.name LIKE ? OR
          CAST(pp.price AS TEXT) LIKE ?
        )
      ''';
      final searchPattern = '%$trimmedQuery%';
      whereArgs.addAll([
        searchPattern,
        searchPattern,
        searchPattern,
        searchPattern,
      ]);
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    // Optimized JOIN query
    final query =
        '''
      SELECT
        p.code as product_code,
        p.name as product_name,
        p.unit as unit,
        p.quantity as quantity,
        p.reserved as reserved,
        p.available as available,
        p.category as category,
        p.barcode as barcode,
        p.have as have,
        p.warehouse_code as warehouse_code,
        COALESCE(uw.name, '') as warehouse_name,
        p.weight as weight,
        p.capacity as capacity,
        p.vendor_code as vendor_code,
        p.product_brand as product_brand,
        p.product_series as product_series,
        p.code_project as code_project,
        pp.price_type_code as price_type_code,
        pt.name as price_type_name,
        pp.price as price,
        pp.currency as currency,
        pp.valid_from as valid_from,
        pp.valid_to as valid_to,
        COALESCE(pb.available, 0) as stock
      FROM product_prices pp
      INNER JOIN products p ON pp.product_code = p.code
      INNER JOIN price_types pt ON pp.price_type_code = pt.code
      LEFT JOIN user_warehouses uw ON p.warehouse_code = uw.code
      LEFT JOIN product_balances pb ON p.code = pb.code_product AND p.warehouse_code = pb.code_sklad
      $whereClause
      $searchCondition
      ORDER BY p.name ASC, p.code ASC
    ''';

    if (kDebugMode) {
      print('DEBUG: Executing query: $query');
      print('DEBUG: Query args: $whereArgs');
    }

    final result = await db.rawQuery(query, whereArgs);

    if (kDebugMode) {
      print('DEBUG: Query returned ${result.length} rows');
      if (result.isNotEmpty) {
        print('DEBUG: First row sample: ${result.first}');
      }
    }

    final productsWithPrices = result
        .map((row) => ProductWithPrice.fromMap(row))
        .toList();

    if (kDebugMode) {
      print(
        'DEBUG: Parsed ${productsWithPrices.length} ProductWithPrice objects',
      );
      if (productsWithPrices.isNotEmpty) {
        print(
          'DEBUG: First product: ${productsWithPrices.first.productName} - ${productsWithPrices.first.price}',
        );
      }
    }

    return productsWithPrices;
  }

  // Client contracts methods
  Future<void> saveClientContracts(List<ClientContract> contracts) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing contracts
    batch.delete('client_contracts');

    // Deduplicate contracts by code_contract to avoid UNIQUE constraint violations
    final uniqueContracts = <String, ClientContract>{};
    for (final contract in contracts) {
      uniqueContracts[contract.codeContract] = contract;
    }

    // Add all inserts to batch
    for (final contract in uniqueContracts.values) {
      batch.insert('client_contracts', {
        'code_contract': contract.codeContract,
        'date_of_contract': contract.dateOfContract?.toIso8601String(),
        'sum_of_contract': contract.sumOfContract,
        'term_of_contract': contract.termOfContract?.toIso8601String(),
        'type_contract': contract.typeContract,
        'numb_reference': contract.numbReference,
        'numb_certificate': contract.numbCertificate,
        'term_reference': contract.termReference?.toIso8601String(),
        'term_certificate': contract.termCertificate?.toIso8601String(),
        'numb_passport': contract.numbPassport,
        'term_passport': contract.termPassport?.toIso8601String(),
        'certificate_unlimited': contract.certificateUnlimited,
        'code_district': contract.codeDistrict,
        'name_district': contract.nameDistrict,
        'code_project': contract.codeProject,
        'code_client': contract.codeClient,
        'active': contract.active ? 1 : 0,
        'status': contract.status,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<ClientContract>> getClientContracts({
    String? clientCode,
    bool? active,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (clientCode != null) {
      conditions.add('code_client = ?');
      whereArgs.add(clientCode);
    }
    if (active != null) {
      conditions.add('active = ?');
      whereArgs.add(active ? 1 : 0);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery('''
      SELECT * FROM client_contracts
      $whereClause
      ORDER BY date_of_contract DESC, code_contract ASC
    ''', whereArgs);

    return result
        .map(
          (row) => ClientContract(
            codeContract: row['code_contract'] as String,
            dateOfContract: row['date_of_contract'] != null
                ? DateTime.parse(row['date_of_contract'] as String)
                : null,
            sumOfContract: (row['sum_of_contract'] as num?)?.toDouble() ?? 0.0,
            termOfContract: row['term_of_contract'] != null
                ? DateTime.parse(row['term_of_contract'] as String)
                : null,
            typeContract: row['type_contract'] as String?,
            numbReference: row['numb_reference'] as String?,
            numbCertificate: row['numb_certificate'] as String?,
            termReference: row['term_reference'] != null
                ? DateTime.parse(row['term_reference'] as String)
                : null,
            termCertificate: row['term_certificate'] != null
                ? DateTime.parse(row['term_certificate'] as String)
                : null,
            numbPassport: row['numb_passport'] as String?,
            termPassport: row['term_passport'] != null
                ? DateTime.parse(row['term_passport'] as String)
                : null,
            certificateUnlimited:
                (row['certificate_unlimited'] as num?)?.toInt() ?? 0,
            codeDistrict: row['code_district'] as String?,
            nameDistrict: row['name_district'] as String?,
            codeProject: row['code_project'] as String?,
            codeClient: row['code_client'] as String,
            active: (row['active'] as num?) == 1,
            status: row['status'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  /// Get client contracts with client names using efficient JOIN query
  /// This method returns ClientContractWithName objects to avoid N+1 queries
  Future<List<ClientContractWithName>> getClientContractsWithNames({
    String? clientCode,
    bool? active,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (clientCode != null) {
      conditions.add('cc.code_client = ?');
      whereArgs.add(clientCode);
    }
    if (active != null) {
      conditions.add('cc.active = ?');
      whereArgs.add(active ? 1 : 0);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery('''
      SELECT
        cc.*,
        c.name as client_name
      FROM client_contracts cc
      LEFT JOIN clients c ON cc.code_client = c.code
      $whereClause
      ORDER BY cc.date_of_contract DESC, cc.code_contract ASC
    ''', whereArgs);

    return result.map((row) => ClientContractWithName.fromMap(row)).toList();
  }

  Future<ClientContract?> getClientContractByCode(String codeContract) async {
    final db = await database;
    final result = await db.query(
      'client_contracts',
      where: 'code_contract = ?',
      whereArgs: [codeContract],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return ClientContract(
      codeContract: row['code_contract'] as String,
      dateOfContract: row['date_of_contract'] != null
          ? DateTime.parse(row['date_of_contract'] as String)
          : null,
      sumOfContract: (row['sum_of_contract'] as num?)?.toDouble() ?? 0.0,
      termOfContract: row['term_of_contract'] != null
          ? DateTime.parse(row['term_of_contract'] as String)
          : null,
      typeContract: row['type_contract'] as String?,
      numbReference: row['numb_reference'] as String?,
      numbCertificate: row['numb_certificate'] as String?,
      termReference: row['term_reference'] != null
          ? DateTime.parse(row['term_reference'] as String)
          : null,
      termCertificate: row['term_certificate'] != null
          ? DateTime.parse(row['term_certificate'] as String)
          : null,
      numbPassport: row['numb_passport'] as String?,
      termPassport: row['term_passport'] != null
          ? DateTime.parse(row['term_passport'] as String)
          : null,
      certificateUnlimited:
          (row['certificate_unlimited'] as num?)?.toInt() ?? 0,
      codeDistrict: row['code_district'] as String?,
      nameDistrict: row['name_district'] as String?,
      codeProject: row['code_project'] as String?,
      codeClient: row['code_client'] as String,
      active: (row['active'] as num?) == 1,
      status: row['status'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<void> saveClientContract(ClientContract contract) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('client_contracts', {
      'code_contract': contract.codeContract,
      'date_of_contract': contract.dateOfContract?.toIso8601String(),
      'sum_of_contract': contract.sumOfContract,
      'term_of_contract': contract.termOfContract?.toIso8601String(),
      'type_contract': contract.typeContract,
      'numb_reference': contract.numbReference,
      'numb_certificate': contract.numbCertificate,
      'term_reference': contract.termReference?.toIso8601String(),
      'term_certificate': contract.termCertificate?.toIso8601String(),
      'numb_passport': contract.numbPassport,
      'term_passport': contract.termPassport?.toIso8601String(),
      'certificate_unlimited': contract.certificateUnlimited,
      'code_district': contract.codeDistrict,
      'name_district': contract.nameDistrict,
      'code_project': contract.codeProject,
      'code_client': contract.codeClient,
      'active': contract.active ? 1 : 0,
      'status': contract.status,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateClientContract(
    String codeContract,
    ClientContract contract,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'client_contracts',
      {
        'date_of_contract': contract.dateOfContract?.toIso8601String(),
        'sum_of_contract': contract.sumOfContract,
        'term_of_contract': contract.termOfContract?.toIso8601String(),
        'type_contract': contract.typeContract,
        'numb_reference': contract.numbReference,
        'numb_certificate': contract.numbCertificate,
        'term_reference': contract.termReference?.toIso8601String(),
        'term_certificate': contract.termCertificate?.toIso8601String(),
        'numb_passport': contract.numbPassport,
        'term_passport': contract.termPassport?.toIso8601String(),
        'certificate_unlimited': contract.certificateUnlimited,
        'code_district': contract.codeDistrict,
        'name_district': contract.nameDistrict,
        'code_project': contract.codeProject,
        'code_client': contract.codeClient,
        'active': contract.active ? 1 : 0,
        'status': contract.status,
        'updated_at': now,
      },
      where: 'code_contract = ?',
      whereArgs: [codeContract],
    );
  }

  Future<void> deleteClientContract(String codeContract) async {
    final db = await database;
    await db.delete(
      'client_contracts',
      where: 'code_contract = ?',
      whereArgs: [codeContract],
    );
  }

  // Main Reports methods
  Future<void> saveMainReports(List<MainReport> reports) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();
    //
    // // Delete all existing reports
    batch.delete('main_reports');
    debugPrint("MainReports deleted successfully");
    // clearMainReport();
    // Deduplicate reports by user_code, date_start, date_end to avoid UNIQUE constraint violations
    final uniqueReports = <String, MainReport>{};
    for (final report in reports) {
      final key = '${report.userCode}_${report.dateStart}_${report.dateEnd}';
      uniqueReports[key] = report;
    }

    // Add all inserts to batch
    for (final report in uniqueReports.values) {
      batch.insert('main_reports', {
        'user_code': report.userCode,
        'date_start': report.dateStart.toIso8601String(),
        'date_end': report.dateEnd.toIso8601String(),
        'count_akb': report.countAKB,
        'count_okb': report.countOKB,
        'cash': report.cash,
        'transfer': report.transfer,
        'sum': report.sum,
        'count_visited': report.countVisited,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
    debugPrint("MainReports created successfully");
  }

  Future<List<MainReport>> getMainReports({String? userCode}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userCode != null) {
      whereClause = 'WHERE user_code = ?';
      whereArgs = [userCode];
    }

    final result = await db.rawQuery('''
      SELECT * FROM main_reports
      $whereClause
      ORDER BY date_start DESC
    ''', whereArgs);

    return result.map((row) => MainReport.fromMap(row)).toList();
  }

  Future<MainReport?> getMainReportById(int id) async {
    final db = await database;
    final result = await db.query(
      'main_reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return MainReport.fromMap(result.first);
  }

  // Business Region Reports methods
  Future<void> saveBusinessRegionReports(
    List<BusinessRegionReport> reports,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing reports
    batch.delete('business_region_reports');

    // Add all inserts to batch
    for (final report in reports) {
      batch.insert('business_region_reports', {
        'main_report_id': report.mainReportId,
        'code': report.code,
        'name': report.name,
        'akb': report.akb,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<BusinessRegionReport>> getBusinessRegionReports({
    int? mainReportId,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (mainReportId != null) {
      whereClause = 'WHERE main_report_id = ?';
      whereArgs = [mainReportId];
    }

    final result = await db.rawQuery('''
      SELECT * FROM business_region_reports
      $whereClause
      ORDER BY name ASC
    ''', whereArgs);

    return result.map((row) => BusinessRegionReport.fromMap(row)).toList();
  }

  // AKB By Categories methods
  Future<void> saveAKBByCategories(List<AKBByCategory> categories) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing categories
    batch.delete('akb_by_categories');

    // Add all inserts to batch
    for (final category in categories) {
      batch.insert('akb_by_categories', {
        'main_report_id': category.mainReportId,
        'code': category.code,
        'name': category.name,
        'akb': category.akb,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<AKBByCategory>> getAKBByCategories({int? mainReportId}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (mainReportId != null) {
      whereClause = 'WHERE main_report_id = ?';
      whereArgs = [mainReportId];
    }

    final result = await db.rawQuery('''
      SELECT * FROM akb_by_categories
      $whereClause
      ORDER BY name ASC
    ''', whereArgs);

    return result.map((row) => AKBByCategory.fromMap(row)).toList();
  }

  // Visit Plans methods
  Future<void> saveVisitPlans(List<VisitPlan> plans) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing plans
    batch.delete('visit_plans');

    // Add all inserts to batch
    for (final plan in plans) {
      batch.insert('visit_plans', {
        'main_report_id': plan.mainReportId,
        'client_code': plan.clientCode,
        'client_name': plan.clientName,
        'planned_date': plan.plannedDate,
        'actual_visit_date': plan.actualVisitDate,
        'is_completed': plan.isCompleted ? 1 : 0,
        'notes': plan.notes,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<VisitPlan>> getVisitPlans({
    int? mainReportId,
    String? clientCode,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (mainReportId != null) {
      conditions.add('main_report_id = ?');
      whereArgs.add(mainReportId);
    }
    if (clientCode != null) {
      conditions.add('client_code = ?');
      whereArgs.add(clientCode);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery('''
      SELECT * FROM visit_plans
      $whereClause
      ORDER BY planned_date ASC
    ''', whereArgs);

    return result.map((row) => VisitPlan.fromMap(row)).toList();
  }

  // Visit Plan Lists methods
  Future<void> saveVisitPlanLists(List<VisitPlanList> lists) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing lists
    batch.delete('visit_plan_lists');

    // Add all inserts to batch
    for (final list in lists) {
      batch.insert('visit_plan_lists', {
        'visit_plan_id': list.visitPlanId,
        'product_code': list.productCode,
        'product_name': list.productName,
        'planned_quantity': list.plannedQuantity,
        'actual_quantity': list.actualQuantity,
        'notes': list.notes,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<VisitPlanList>> getVisitPlanLists({int? visitPlanId}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (visitPlanId != null) {
      whereClause = 'WHERE visit_plan_id = ?';
      whereArgs = [visitPlanId];
    }

    final result = await db.rawQuery('''
      SELECT * FROM visit_plan_lists
      $whereClause
      ORDER BY product_name ASC
    ''', whereArgs);

    return result.map((row) => VisitPlanList.fromMap(row)).toList();
  }

  // Save main reports by clearing all related tables first
  Future<void> saveMainReportsByDelete(List<MainReport> reports) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for clearing and saving
    final batch = db.batch();

    // Clear all report-related tables
    batch.delete('main_reports');
    batch.delete('business_region_reports');
    batch.delete('akb_by_categories');
    batch.delete('visit_plans');
    batch.delete('visit_plan_lists');

    // Deduplicate reports by user_code, date_start, date_end to avoid UNIQUE constraint violations
    final uniqueReports = <String, MainReport>{};
    for (final report in reports) {
      final key = '${report.userCode}_${report.dateStart}_${report.dateEnd}';
      uniqueReports[key] = report;
    }

    // Add all inserts to batch
    for (final report in uniqueReports.values) {
      batch.insert('main_reports', {
        'user_code': report.userCode,
        'date_start': report.dateStart.toIso8601String(),
        'date_end': report.dateEnd.toIso8601String(),
        'count_akb': report.countAKB,
        'count_okb': report.countOKB,
        'cash': report.cash,
        'transfer': report.transfer,
        'sum': report.sum,
        'count_visited': report.countVisited,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  // Clear all data
  Future<void> clearAllData() async {
    // Eski o'rnatilgan bazalarda order_details va shu bilan bog'liq jadvallar
    // bo'lmasligi mumkin (migratsiya tushib qolgan). Tozalashdan oldin ularni
    // mavjudligini ta'minlaymiz, aks holda DELETE FROM "no such table" beradi.
    await ensureOrderDetailsTablesExist();
    final db = await database;
    // Clear sales req permissions and visit steps tables
    await db.delete('sales_req_permissions');
    await db.delete('visit_steps');
    await db.delete('visit_steps_data');

    await db.delete('kpi_data');
    await db.delete('clients');
    await db.delete('client_contracts');
    await db.delete('client_images');
    await db.delete('products');
    await db.delete('price_types');
    await db.delete('product_prices');
    await db.delete('business_regions');
    await db.delete('user_warehouses');
    await db.delete('product_balances');
    await db.delete('product_series');
    await db.delete('product_brands');
    await db.delete('promotion_product_list');
    await db.delete('promotion_bonus_list');
    await db.delete('promotion_class_list');
    await db.delete('promotions');
    await db.delete('main_reports');
    await db.delete('business_region_reports');
    await db.delete('akb_by_categories');
    await db.delete('visit_plans');
    await db.delete('visit_plan_lists');
    await db.delete('order_details');
    await db.delete('order_detail_products');
    await db.delete('order_payments');
    await db.delete('orders');
    await db.delete('order_statuses');
    await db.delete('couriers');
    await db.delete('courier_cars');
    await db.delete('order_couriers');
    // Очистка проектов пользователя / Foydalanuvchi loyihalarini tozalash
    await db.delete('user_projects');
  }

  Future<void> clearMainReport() async {
    final db = await database;

    await db.delete('main_reports');
    await db.delete('business_region_reports');
    await db.delete('akb_by_categories');
    await db.delete('visit_plans');
    await db.delete('visit_plan_lists');
  }

  // Order Status methods
  Future<void> saveOrderStatuses(List<OrderStatus> statuses) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing statuses
    batch.delete('order_statuses');

    // Deduplicate statuses by message to avoid UNIQUE constraint violations
    final uniqueStatuses = <String, OrderStatus>{};
    for (final status in statuses) {
      uniqueStatuses[status.message] = status;
    }

    // Add all inserts to batch
    for (final status in uniqueStatuses.values) {
      batch.insert('order_statuses', {
        'message': status.message,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<OrderStatus>> getOrderStatuses() async {
    final db = await database;
    final result = await db.query('order_statuses', orderBy: 'message ASC');

    return result
        .map(
          (row) => OrderStatus(
            id: row['id'] as int,
            message: row['message'] as String,
          ),
        )
        .toList();
  }

  Future<OrderStatus?> getOrderStatusByMessage(String message) async {
    final db = await database;
    final result = await db.query(
      'order_statuses',
      where: 'message = ?',
      whereArgs: [message],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return OrderStatus(id: row['id'] as int, message: row['message'] as String);
  }

  // Courier methods
  Future<void> saveCourier(String name, String? car) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'couriers',
      {'name': name, 'car': car, 'created_at': now, 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if already exists
    );
  }

  Future<void> saveCourierCar(String car) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'courier_cars',
      {'car': car, 'created_at': now, 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if already exists
    );
  }

  Future<List<String>> getUniqueCourierNames() async {
    final db = await database;
    final result = await db.query(
      'couriers',
      columns: ['name'],
      distinct: true,
    );
    return result.map((row) => row['name'] as String).toList();
  }

  Future<List<String>> getUniqueCourierCars() async {
    final db = await database;
    final result = await db.query(
      'courier_cars',
      columns: ['car'],
      distinct: true,
    );
    return result.map((row) => row['car'] as String).toList();
  }

  // Order methods
  Future<void> saveOrders(List<Order> orders) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing orders
    batch.delete('orders');

    // Deduplicate orders by num_order to avoid UNIQUE constraint violations
    final uniqueOrders = <String, Order>{};
    for (final order in orders) {
      uniqueOrders[order.numOrder] = order;
    }

    // Extract and save unique courier data
    final uniqueCouriers = <String>{};
    final uniqueCourierCars = <String>{};

    for (final order in uniqueOrders.values) {
      if (order.courierName != null && order.courierName!.isNotEmpty) {
        uniqueCouriers.add(order.courierName!);
      }
      if (order.courierCar != null && order.courierCar!.isNotEmpty) {
        uniqueCourierCars.add(order.courierCar!);
      }
    }

    // Save unique couriers and cars
    for (final courierName in uniqueCouriers) {
      final car = uniqueOrders.values
          .firstWhere((order) => order.courierName == courierName)
          .courierCar;
      batch.insert('couriers', {
        'name': courierName,
        'car': car,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final car in uniqueCourierCars) {
      batch.insert('courier_cars', {
        'car': car,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Add all inserts to batch
    for (final order in uniqueOrders.values) {
      batch.insert('orders', {
        'num_order': order.numOrder,
        'date_order': order.dateOrder.toIso8601String(),
        'caption_order': order.captionOrder,
        'type_price_code': order.typePriceCode,
        'status': order.status,
        'comment_supervisor': order.commentSupervisor,
        'comment_forwarder': order.commentForwarder,
        'comment_agent': order.commentAgent,
        'total': order.total,
        'client_code': order.clientCode,
        'client_name': order.clientName,
        'code_org': order.codeOrg,
        'main_status': order.mainStatus,
        'courier_name': order.courierName,
        'courier_car': order.courierCar,
        'shipping_date': order.shippingDate?.toIso8601String(),
        'server': order.server ? 1 : 0,
        'promo': order.promo ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });

      // Save order-courier relationship
      if (order.courierName != null || order.courierCar != null) {
        batch.insert('order_couriers', {
          'order_num': order.numOrder,
          'courier_name': order.courierName,
          'courier_car': order.courierCar,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  Future<List<Order>> getOrders({
    String? clientCode,
    String? mainStatus,
    String? typePriceCode,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (clientCode != null) {
      conditions.add('o.client_code = ?');
      whereArgs.add(clientCode);
    }
    if (mainStatus != null) {
      conditions.add('o.main_status = ?');
      whereArgs.add(mainStatus);
    }
    if (typePriceCode != null) {
      conditions.add('o.type_price_code = ?');
      whereArgs.add(typePriceCode);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery('''
      SELECT o.*, oc.courier_name, oc.courier_car
      FROM orders o
      LEFT JOIN order_couriers oc ON o.num_order = oc.order_num
      $whereClause
      ORDER BY o.date_order DESC, o.num_order ASC
    ''', whereArgs);

    return result
        .map(
          (row) => Order(
            id: row['id'] as int,
            numOrder: row['num_order'] as String,
            dateOrder: DateTime.parse(row['date_order'] as String),
            captionOrder: row['caption_order'] as String,
            typePriceCode: row['type_price_code'] as String,
            status: row['status'] as int,
            commentSupervisor: row['comment_supervisor'] as String?,
            commentForwarder: row['comment_forwarder'] as String?,
            commentAgent: row['comment_agent'] as String?,
            total: (row['total'] as num?)?.toDouble() ?? 0.0,
            clientCode: row['client_code'] as String,
            clientName: row['client_name'] as String,
            codeOrg: row['code_org'] as String,
            mainStatus: row['main_status'] as String,
            courierName: row['courier_name'] as String?,
            courierCar: row['courier_car'] as String?,
            shippingDate: row['shipping_date'] != null 
                ? DateTime.tryParse(row['shipping_date'] as String)
                : null,
            server: (row['server'] as int?) == 1,
            promo: (row['promo'] as int?) == 1,
          ),
        )
        .toList();
  }

  Future<Order?> getOrderByNumOrder(String numOrder) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT o.*, oc.courier_name, oc.courier_car
      FROM orders o
      LEFT JOIN order_couriers oc ON o.num_order = oc.order_num
      WHERE o.num_order = ?
      LIMIT 1
    ''',
      [numOrder],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Order(
      id: row['id'] as int,
      numOrder: row['num_order'] as String,
      dateOrder: DateTime.parse(row['date_order'] as String),
      captionOrder: row['caption_order'] as String,
      typePriceCode: row['type_price_code'] as String,
      status: row['status'] as int,
      commentSupervisor: row['comment_supervisor'] as String?,
      commentForwarder: row['comment_forwarder'] as String?,
      commentAgent: row['comment_agent'] as String?,
      total: (row['total'] as num?)?.toDouble() ?? 0.0,
      clientCode: row['client_code'] as String,
      clientName: row['client_name'] as String,
      codeOrg: row['code_org'] as String,
      mainStatus: row['main_status'] as String,
      courierName: row['courier_name'] as String?,
      courierCar: row['courier_car'] as String?,
      shippingDate: row['shipping_date'] != null 
          ? DateTime.tryParse(row['shipping_date'] as String)
          : null,
      server: (row['server'] as int?) == 1,
      promo: (row['promo'] as int?) == 1,
    );
  }

  Future<void> updateOrderStatus(String numOrder, String mainStatus) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'orders',
      {'main_status': mainStatus, 'updated_at': now},
      where: 'num_order = ?',
      whereArgs: [numOrder],
    );
  }

  Future<void> deleteOrder(String numOrder) async {
    final db = await database;
    await db.delete('orders', where: 'num_order = ?', whereArgs: [numOrder]);
  }

  // Order Details methods
  Future<void> saveOrderDetails(List<OrderDetail> orderDetails) async {
    // Ensure order_details tables exist before performing operations
    await ensureOrderDetailsTablesExist();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Validate input data
    if (orderDetails.isEmpty) {
      return; // Nothing to save
    }

    // Filter out orders with price code "00000000321" - these should not be saved
    final filteredOrderDetails = orderDetails.where((od) {
      if (od.codePrice == '00000000321') {
        if (kDebugMode) {
          print(
            'ApiDatabaseService: Skipping order ${od.numOrder} with price code 00000000321',
          );
        }
        return false;
      }
      return true;
    }).toList();

    // Return early if all orders were filtered out
    if (filteredOrderDetails.isEmpty) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: All orders filtered out (price code 00000000321)',
        );
      }
      return;
    }

    // Validate each order detail
    for (final orderDetail in filteredOrderDetails) {
      if (orderDetail.numOrder.isEmpty) {
        throw ArgumentError('OrderDetail numOrder cannot be empty');
      }
      if (orderDetail.codePrice.isEmpty) {
        throw ArgumentError('OrderDetail codePrice cannot be empty');
      }
      if (orderDetail.codeSklad.isEmpty) {
        throw ArgumentError('OrderDetail codeSklad cannot be empty');
      }
      if (orderDetail.codeOrg.isEmpty) {
        throw ArgumentError('OrderDetail codeOrg cannot be empty');
      }

      // Validate products
      for (final product in orderDetail.productRows) {
        if (product.codeProduct.isEmpty) {
          throw ArgumentError(
            'Product codeProduct cannot be empty for order ${orderDetail.numOrder}',
          );
        }
        if (product.nameProduct.isEmpty) {
          throw ArgumentError(
            'Product nameProduct cannot be empty for order ${orderDetail.numOrder}',
          );
        }
        if (product.amount <= 0) {
          throw ArgumentError(
            'Product amount must be positive for order ${orderDetail.numOrder}',
          );
        }
        if (product.price < 0) {
          throw ArgumentError(
            'Product price cannot be negative for order ${orderDetail.numOrder}',
          );
        }
      }

      // Validate payments
      for (final payment in orderDetail.creditDetailsList) {
        if (payment.dateOfPayment.isEmpty) {
          throw ArgumentError(
            'Payment dateOfPayment cannot be empty for order ${orderDetail.numOrder}',
          );
        }
        if (payment.total < 0) {
          throw ArgumentError(
            'Payment total cannot be negative for order ${orderDetail.numOrder}',
          );
        }
      }
    }

    // Validate foreign key references for all orders
    final orderNumbers = filteredOrderDetails.map((od) => od.numOrder).toSet();
    for (final numOrder in orderNumbers) {
      final orderExists = await db.query(
        'orders',
        where: 'num_order = ?',
        whereArgs: [numOrder],
      );
      if (orderExists.isEmpty) {
        throw Exception('Referenced order $numOrder does not exist');
      }
    }

    // Use transaction for atomicity
    await db.transaction((txn) async {
      try {
        // Use batch operations for much better performance
        final batch = txn.batch();

        // Delete all existing order details (this method replaces all data)
        batch.delete('order_details');
        batch.delete('order_detail_products');
        batch.delete('order_payments');

        // Deduplicate order details by num_order to avoid UNIQUE constraint violations
        final uniqueOrderDetails = <String, OrderDetail>{};
        for (final orderDetail in filteredOrderDetails) {
          uniqueOrderDetails[orderDetail.numOrder] = orderDetail;
        }

        // Add all inserts to batch
        for (final orderDetail in uniqueOrderDetails.values) {
          final orderDetailId = await txn.insert('order_details', {
            'num_order': orderDetail.numOrder,
            'credit': orderDetail.credit ? 1 : 0,
            'code_price': orderDetail.codePrice,
            'date_order': orderDetail.dateOrder.toIso8601String(),
            'code_sklad': orderDetail.codeSklad,
            'comment_supervisor': orderDetail.commentSupervisor,
            'comment_forwarder': orderDetail.commentForwarder,
            'comment_agent': orderDetail.commentAgent,
            'shipping_date': orderDetail.shippingDate,
            'order_type': orderDetail.orderType,
            'code_org': orderDetail.codeOrg,
            'created_at': now,
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Insert product rows with price type information
          for (final product in orderDetail.productRows) {
            batch.insert('order_detail_products', {
              'order_detail_id': orderDetailId,
              'code_product': product.codeProduct,
              'name_product': product.nameProduct,
              'amount': product.amount,
              'price': product.price,
              'total': product.total,
              'discount_rate': product.discountRate,
              'weight': product.weight,
              'capacity': product.capacity,
              'price_type_code': product.priceTypeCode,
              'price_type_name': product.priceTypeName,
              'created_at': now,
              'updated_at': now,
            });
          }

          // Insert payment rows
          for (final payment in orderDetail.creditDetailsList) {
            batch.insert('order_payments', {
              'order_detail_id': orderDetailId,
              'date_of_payment': payment.dateOfPayment,
              'total': payment.total,
              'created_at': now,
              'updated_at': now,
            });
          }
        }

        // Execute batch operation
        await batch.commit(noResult: true);
      } catch (e) {
        // Log error and rethrow
        if (kDebugMode) print('Error saving order details batch: $e');
        rethrow;
      }
    });
  }

  Future<List<OrderDetail>> getOrderDetails({String? numOrder}) async {
    // Ensure order_details tables exist before performing operations
    await ensureOrderDetailsTablesExist();

    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (numOrder != null) {
      whereClause = 'WHERE od.num_order = ?';
      whereArgs = [numOrder];
    }

    final result = await db.rawQuery('''
      SELECT od.*, odp.*, op.*
      FROM order_details od
      LEFT JOIN order_detail_products odp ON od.id = odp.order_detail_id
      LEFT JOIN order_payments op ON od.id = op.order_detail_id
      $whereClause
      ORDER BY od.date_order DESC, od.num_order ASC
    ''', whereArgs);

    final orderDetailsMap = <String, OrderDetail>{};

    for (final row in result) {
      final orderNum = row['num_order'] as String;

      if (!orderDetailsMap.containsKey(orderNum)) {
        orderDetailsMap[orderNum] = OrderDetail(
          id: row['id'] as int? ?? 0,
          numOrder: orderNum,
          credit: (row['credit'] as int?) == 1,
          codePrice: row['code_price'] as String,
          dateOrder: DateTime.parse(row['date_order'] as String),
          codeSklad: row['code_sklad'] as String,
          commentSupervisor: row['comment_supervisor'] as String?,
          commentForwarder: row['comment_forwarder'] as String?,
          commentAgent: row['comment_agent'] as String?,
          shippingDate: row['shipping_date'] as String,
          orderType: row['order_type'] as int,
          codeOrg: row['code_org'] as String,
          productRows: [],
          creditDetailsList: [],
        );
      }

      final orderDetail = orderDetailsMap[orderNum]!;

      // Add product if exists - load price type from order_detail_products table
      if (row['code_product'] != null) {
        final product = OrderDetailProduct(
          id: row['odp.id'] as int? ?? 0,
          codeProduct: row['code_product'] as String,
          nameProduct: row['name_product'] as String,
          amount: row['amount'] as int,
          price: (row['price'] as num?)?.toDouble() ?? 0.0,
          total: (row['total'] as num?)?.toDouble() ?? 0.0,
          discountRate: (row['discount_rate'] as num?)?.toDouble() ?? 0.0,
          weight: (row['weight'] as num?)?.toDouble() ?? 0.0,
          capacity: (row['capacity'] as num?)?.toDouble() ?? 0.0,
          priceTypeCode: row['price_type_code'] as String?,
          priceTypeName: row['price_type_name'] as String?,
        );

        if (!orderDetail.productRows.any(
          (p) => p.codeProduct == product.codeProduct,
        )) {
          orderDetail.productRows.add(product);
        }
      }

      // Add payment if exists
      if (row['date_of_payment'] != null) {
        final payment = OrderPayment(
          id: row['op.id'] as int? ?? 0,
          dateOfPayment: row['date_of_payment'] as String,
          total: (row['op.total'] as num?)?.toDouble() ?? 0.0,
        );

        if (!orderDetail.creditDetailsList.any(
          (p) => p.dateOfPayment == payment.dateOfPayment,
        )) {
          orderDetail.creditDetailsList.add(payment);
        }
      }
    }

    return orderDetailsMap.values.toList();
  }

  Future<OrderDetail?> getOrderDetailByNumOrder(String numOrder) async {
    // Ensure order_details tables exist before performing operations
    await ensureOrderDetailsTablesExist();

    final orderDetails = await getOrderDetails(numOrder: numOrder);
    return orderDetails.isNotEmpty ? orderDetails.first : null;
  }

  Future<void> saveOrderDetail(
    OrderDetail orderDetail, {
    bool validateOrderExists = false,
  }) async {
    // Ensure order_details tables exist before performing operations
    await ensureOrderDetailsTablesExist();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Validate input data
    if (orderDetail.numOrder.isEmpty) {
      throw ArgumentError('OrderDetail numOrder cannot be empty');
    }
    if (orderDetail.codePrice.isEmpty) {
      throw ArgumentError('OrderDetail codePrice cannot be empty');
    }
    if (orderDetail.codeSklad.isEmpty) {
      throw ArgumentError('OrderDetail codeSklad cannot be empty');
    }
    if (orderDetail.codeOrg.isEmpty) {
      throw ArgumentError('OrderDetail codeOrg cannot be empty');
    }

    // Validate foreign key references (optional - skip when caching server data)
    if (validateOrderExists) {
      final orderExists = await db.query(
        'orders',
        where: 'num_order = ?',
        whereArgs: [orderDetail.numOrder],
      );
      if (orderExists.isEmpty) {
        throw Exception(
          'Referenced order ${orderDetail.numOrder} does not exist',
        );
      }
    }

    // Use transaction for atomicity
    await db.transaction((txn) async {
      try {
        final orderDetailId = await txn.insert('order_details', {
          'num_order': orderDetail.numOrder,
          'credit': orderDetail.credit ? 1 : 0,
          'code_price': orderDetail.codePrice,
          'date_order': orderDetail.dateOrder.toIso8601String(),
          'code_sklad': orderDetail.codeSklad,
          'comment_supervisor': orderDetail.commentSupervisor,
          'comment_forwarder': orderDetail.commentForwarder,
          'comment_agent': orderDetail.commentAgent,
          'shipping_date': orderDetail.shippingDate,
          'order_type': orderDetail.orderType,
          'code_org': orderDetail.codeOrg,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Save products
        for (final product in orderDetail.productRows) {
          if (product.codeProduct.isEmpty) {
            throw ArgumentError('Product codeProduct cannot be empty');
          }
          if (product.nameProduct.isEmpty) {
            throw ArgumentError('Product nameProduct cannot be empty');
          }
          if (product.amount <= 0) {
            throw ArgumentError('Product amount must be positive');
          }
          if (product.price < 0) {
            throw ArgumentError('Product price cannot be negative');
          }

          await txn.insert('order_detail_products', {
            'order_detail_id': orderDetailId,
            'code_product': product.codeProduct,
            'name_product': product.nameProduct,
            'amount': product.amount,
            'price': product.price,
            'total': product.total,
            'discount_rate': product.discountRate,
            'weight': product.weight,
            'capacity': product.capacity,
            'price_type_code': product.priceTypeCode,
            'price_type_name': product.priceTypeName,
            'created_at': now,
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Save payments
        for (final payment in orderDetail.creditDetailsList) {
          if (payment.dateOfPayment.isEmpty) {
            throw ArgumentError('Payment dateOfPayment cannot be empty');
          }
          if (payment.total < 0) {
            throw ArgumentError('Payment total cannot be negative');
          }

          await txn.insert('order_payments', {
            'order_detail_id': orderDetailId,
            'date_of_payment': payment.dateOfPayment,
            'total': payment.total,
            'created_at': now,
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        // Log error and rethrow
        if (kDebugMode)
          print('Error saving order detail ${orderDetail.numOrder}: $e');
        rethrow;
      }
    });
  }

  Future<void> updateOrderDetail(
    String numOrder,
    OrderDetail orderDetail,
  ) async {
    // Ensure order_details tables exist before performing operations
    await ensureOrderDetailsTablesExist();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Validate input data
    if (numOrder.isEmpty) {
      throw ArgumentError('numOrder cannot be empty');
    }
    if (orderDetail.numOrder.isEmpty) {
      throw ArgumentError('OrderDetail numOrder cannot be empty');
    }
    if (orderDetail.codePrice.isEmpty) {
      throw ArgumentError('OrderDetail codePrice cannot be empty');
    }
    if (orderDetail.codeSklad.isEmpty) {
      throw ArgumentError('OrderDetail codeSklad cannot be empty');
    }
    if (orderDetail.codeOrg.isEmpty) {
      throw ArgumentError('OrderDetail codeOrg cannot be empty');
    }

    // Validate that the order detail exists
    final existingOrderDetail = await db.query(
      'order_details',
      where: 'num_order = ?',
      whereArgs: [numOrder],
    );
    if (existingOrderDetail.isEmpty) {
      throw Exception('Order detail with num_order $numOrder does not exist');
    }

    // Validate foreign key references
    final orderExists = await db.query(
      'orders',
      where: 'num_order = ?',
      whereArgs: [orderDetail.numOrder],
    );
    if (orderExists.isEmpty) {
      throw Exception(
        'Referenced order ${orderDetail.numOrder} does not exist',
      );
    }

    // Use transaction for atomicity
    await db.transaction((txn) async {
      try {
        await txn.update(
          'order_details',
          {
            'num_order':
                orderDetail.numOrder, // Allow updating the order number
            'credit': orderDetail.credit ? 1 : 0,
            'code_price': orderDetail.codePrice,
            'date_order': orderDetail.dateOrder.toIso8601String(),
            'code_sklad': orderDetail.codeSklad,
            'comment_supervisor': orderDetail.commentSupervisor,
            'comment_forwarder': orderDetail.commentForwarder,
            'comment_agent': orderDetail.commentAgent,
            'shipping_date': orderDetail.shippingDate,
            'order_type': orderDetail.orderType,
            'code_org': orderDetail.codeOrg,
            'updated_at': now,
          },
          where: 'num_order = ?',
          whereArgs: [numOrder],
        );

        // Get the order detail ID
        final orderDetailResult = await txn.query(
          'order_details',
          where: 'num_order = ?',
          whereArgs: [orderDetail.numOrder],
        );
        if (orderDetailResult.isNotEmpty) {
          final orderDetailId = orderDetailResult.first['id'] as int;

          // Delete existing products and payments
          await txn.delete(
            'order_detail_products',
            where: 'order_detail_id = ?',
            whereArgs: [orderDetailId],
          );
          await txn.delete(
            'order_payments',
            where: 'order_detail_id = ?',
            whereArgs: [orderDetailId],
          );

          // Re-insert products with validation
          for (final product in orderDetail.productRows) {
            if (product.codeProduct.isEmpty) {
              throw ArgumentError('Product codeProduct cannot be empty');
            }
            if (product.nameProduct.isEmpty) {
              throw ArgumentError('Product nameProduct cannot be empty');
            }
            if (product.amount <= 0) {
              throw ArgumentError('Product amount must be positive');
            }
            if (product.price < 0) {
              throw ArgumentError('Product price cannot be negative');
            }

            await txn.insert('order_detail_products', {
              'order_detail_id': orderDetailId,
              'code_product': product.codeProduct,
              'name_product': product.nameProduct,
              'amount': product.amount,
              'price': product.price,
              'total': product.total,
              'discount_rate': product.discountRate,
              'weight': product.weight,
              'capacity': product.capacity,
              'price_type_code': product.priceTypeCode,
              'price_type_name': product.priceTypeName,
              'created_at': now,
              'updated_at': now,
            });
          }

          // Re-insert payments with validation
          for (final payment in orderDetail.creditDetailsList) {
            if (payment.dateOfPayment.isEmpty) {
              throw ArgumentError('Payment dateOfPayment cannot be empty');
            }
            if (payment.total < 0) {
              throw ArgumentError('Payment total cannot be negative');
            }

            await txn.insert('order_payments', {
              'order_detail_id': orderDetailId,
              'date_of_payment': payment.dateOfPayment,
              'total': payment.total,
              'created_at': now,
              'updated_at': now,
            });
          }
        }
      } catch (e) {
        // Log error and rethrow
        if (kDebugMode) print('Error updating order detail $numOrder: $e');
        rethrow;
      }
    });
  }

  Future<void> deleteOrderDetail(String numOrder) async {
    // Ensure order_details tables exist before performing operations
    await ensureOrderDetailsTablesExist();

    final db = await database;

    // Validate input
    if (numOrder.isEmpty) {
      throw ArgumentError('numOrder cannot be empty');
    }

    // Check if order detail exists
    final existingOrderDetail = await db.query(
      'order_details',
      where: 'num_order = ?',
      whereArgs: [numOrder],
    );
    if (existingOrderDetail.isEmpty) {
      throw Exception('Order detail with num_order $numOrder does not exist');
    }

    // Use transaction for atomicity
    await db.transaction((txn) async {
      try {
        // Foreign key constraints will handle cascading deletes for related records
        await txn.delete(
          'order_details',
          where: 'num_order = ?',
          whereArgs: [numOrder],
        );
      } catch (e) {
        // Log error and rethrow
        if (kDebugMode) print('Error deleting order detail $numOrder: $e');
        rethrow;
      }
    });
  }

  /// Save sales req permissions
  Future<void> saveSalesReqPermissions(
    List<SalesReqPermissions> permissions,
  ) async {
    // Ensure tables exist before saving
    await ensureSalesReqPermissionsTableExists();

    final db = await database;

    for (final permission in permissions) {
      final id = await db.insert(
        'sales_req_permissions',
        permission.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save visit steps if any
      if (permission.visitSteps.isNotEmpty) {
        await saveVisitSteps(permission.visitSteps, id);
      }
    }
  }

  /// Get sales req permissions by user code
  Future<SalesReqPermissions?> getSalesReqPermissions(String userCode) async {
    final db = await database;
    final maps = await db.query(
      'sales_req_permissions',
      where: 'user_code = ?',
      whereArgs: [userCode],
    );

    if (maps.isEmpty) return null;

    final permission = SalesReqPermissions.fromMap(maps.first);
    if (kDebugMode)
      print(
        '_______ getting salse req premissions: Fetched SalesReqPermissions: ${permission.userCode}',
      );
    // Get associated visit steps
    final visitStepsMaps = await db.query(
      'visit_steps',
      where: 'sales_req_permissions_id = ?',
      whereArgs: [permission.id],
    );

    final visitSteps = visitStepsMaps
        .map((map) => VisitStep.fromMap(map))
        .toList();
    return permission.copyWith(visitSteps: visitSteps);
  }

  /// Get all sales req permissions
  Future<List<SalesReqPermissions>> getAllSalesReqPermissions() async {
    final db = await database;
    final maps = await db.query('sales_req_permissions');

    final permissions = <SalesReqPermissions>[];
    for (final map in maps) {
      final permission = SalesReqPermissions.fromMap(map);

      // Get associated visit steps
      final visitStepsMaps = await db.query(
        'visit_steps',
        where: 'sales_req_permissions_id = ?',
        whereArgs: [permission.id],
      );

      final visitSteps = visitStepsMaps
          .map((map) => VisitStep.fromMap(map))
          .toList();
      permissions.add(permission.copyWith(visitSteps: visitSteps));
    }

    return permissions;
  }

  /// Save visit steps (legacy method - kept for backward compatibility)
  /// Note: This method is deprecated. Use saveVisitSteps(List<VisitStep> visitSteps, int salesReqPermissionsId) instead.
  @deprecated
  Future<void> saveVisitStepsLegacy(List<VisitStep> visitSteps) async {
    final db = await database;
    final batch = db.batch();

    for (final step in visitSteps) {
      batch.insert(
        'visit_steps',
        step.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Delete sales req permissions by user code
  Future<void> deleteSalesReqPermissions(String userCode) async {
    final db = await database;
    await db.delete(
      'sales_req_permissions',
      where: 'user_code = ?',
      whereArgs: [userCode],
    );
  }

  /// Clear all sales req permissions data
  Future<void> clearSalesReqPermissions() async {
    final db = await database;
    await db.delete('visit_steps');
    await db.delete('sales_req_permissions');
  }

  /// Visit Steps CRUD methods

  /// Save visit steps for a specific sales req permissions
  Future<void> saveVisitSteps(
    List<VisitStep> visitSteps,
    int salesReqPermissionsId,
  ) async {
    // Ensure tables exist before saving
    await ensureSalesReqPermissionsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete existing visit steps for this permissions
    batch.delete(
      'visit_steps',
      where: 'sales_req_permissions_id = ?',
      whereArgs: [salesReqPermissionsId],
    );

    // Deduplicate visit steps by step_code to avoid UNIQUE constraint violations
    final uniqueVisitSteps = <int, VisitStep>{};
    for (final visitStep in visitSteps) {
      uniqueVisitSteps[visitStep.stepCode] = visitStep;
    }

    // Add all inserts to batch
    for (final visitStep in uniqueVisitSteps.values) {
      batch.insert('visit_steps', {
        'sales_req_permissions_id': salesReqPermissionsId,
        'step_code': visitStep.stepCode,
        'step_name': visitStep.stepName,
        'step_required': visitStep.stepRequired ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  /// Get visit steps by sales req permissions id
  Future<List<VisitStep>> getVisitSteps(int salesReqPermissionsId) async {
    final db = await database;
    final result = await db.query(
      'visit_steps',
      where: 'sales_req_permissions_id = ?',
      whereArgs: [salesReqPermissionsId],
      orderBy: 'step_code ASC',
    );

    return result
        .map(
          (row) => VisitStep(
            id: row['id'] as int?,
            salesReqPermissionsId: row['sales_req_permissions_id'] as int?,
            stepCode: row['step_code'] as int,
            stepName: row['step_name'] as String,
            stepRequired: (row['step_required'] as int?) == 1,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  /// Get visit step by id
  Future<VisitStep?> getVisitStepById(int id) async {
    final db = await database;
    final result = await db.query(
      'visit_steps',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return VisitStep(
      id: row['id'] as int?,
      salesReqPermissionsId: row['sales_req_permissions_id'] as int?,
      stepCode: row['step_code'] as int,
      stepName: row['step_name'] as String,
      stepRequired: (row['step_required'] as int?) == 1,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Update visit step
  Future<void> updateVisitStep(int id, VisitStep visitStep) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'visit_steps',
      {
        'step_code': visitStep.stepCode,
        'step_name': visitStep.stepName,
        'step_required': visitStep.stepRequired ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete visit step by id
  Future<void> deleteVisitStep(int id) async {
    final db = await database;
    await db.delete('visit_steps', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all visit steps for a specific sales req permissions
  Future<void> deleteVisitStepsByPermissionsId(
    int salesReqPermissionsId,
  ) async {
    final db = await database;
    await db.delete(
      'visit_steps',
      where: 'sales_req_permissions_id = ?',
      whereArgs: [salesReqPermissionsId],
    );
  }

  /// Get all visit steps (for admin/debug purposes)
  Future<List<VisitStep>> getAllVisitSteps() async {
    final db = await database;
    final result = await db.query(
      'visit_steps',
      orderBy: 'sales_req_permissions_id ASC, step_code ASC',
    );

    return result
        .map(
          (row) => VisitStep(
            id: row['id'] as int?,
            salesReqPermissionsId: row['sales_req_permissions_id'] as int?,
            stepCode: row['step_code'] as int,
            stepName: row['step_name'] as String,
            stepRequired: (row['step_required'] as int?) == 1,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  /// Get visit steps count for a specific permissions
  Future<int> getVisitStepsCount(int salesReqPermissionsId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM visit_steps WHERE sales_req_permissions_id = ?',
      [salesReqPermissionsId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Visit Steps Data CRUD methods

  /// Save visit step data
  Future<void> saveVisitStepData(VisitData visitData) async {
    // Ensure tables exist before saving
    await ensureSalesReqPermissionsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('visit_steps_data', {
      'visit_id': visitData.visitId,
      'client_code': visitData.clientCode,
      'step_code': visitData.stepCode,
      'step_name': visitData.stepName,
      'data_type': visitData.dataType,
      'data_content': visitData.dataContent,
      'timestamp': visitData.timestamp.toIso8601String(),
      'is_synced': visitData.isSynced ? 1 : 0,
      'synced_at': visitData.syncedAt?.toIso8601String(),
      'sync_error': visitData.syncError,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Save multiple visit step data entries
  Future<void> saveVisitStepDataBatch(List<VisitData> visitDataList) async {
    // Ensure tables exist before saving
    await ensureSalesReqPermissionsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final visitData in visitDataList) {
      batch.insert('visit_steps_data', {
        'visit_id': visitData.visitId,
        'client_code': visitData.clientCode,
        'step_code': visitData.stepCode,
        'step_name': visitData.stepName,
        'data_type': visitData.dataType,
        'data_content': visitData.dataContent,
        'timestamp': visitData.timestamp.toIso8601String(),
        'is_synced': visitData.isSynced ? 1 : 0,
        'synced_at': visitData.syncedAt?.toIso8601String(),
        'sync_error': visitData.syncError,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get visit step data by visit ID
  Future<List<VisitData>> getVisitStepDataByVisitId(String visitId) async {
    final db = await database;
    final result = await db.query(
      'visit_steps_data',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'timestamp ASC',
    );

    return result.map((row) => VisitData.fromMap(row)).toList();
  }

  /// Get visit step data by user (across all visits)
  Future<List<VisitData>> getVisitStepDataByUser(String userCode) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT vsd.* FROM visit_steps_data vsd
      INNER JOIN clients c ON vsd.client_code = c.code
      WHERE c.owner_name = ? OR c.responsible_person = ?
      ORDER BY vsd.timestamp DESC
    ''',
      [userCode, userCode],
    );

    return result.map((row) => VisitData.fromMap(row)).toList();
  }

  /// Get visit step data by client code
  Future<List<VisitData>> getVisitStepDataByClient(String clientCode) async {
    final db = await database;
    final result = await db.query(
      'visit_steps_data',
      where: 'client_code = ?',
      whereArgs: [clientCode],
      orderBy: 'timestamp DESC',
    );

    return result.map((row) => VisitData.fromMap(row)).toList();
  }

  /// Get pending sync visit step data
  Future<List<VisitData>> getPendingSyncVisitStepData() async {
    final db = await database;
    final result = await db.query(
      'visit_steps_data',
      where: 'is_synced = 0',
      orderBy: 'timestamp ASC',
    );

    return result.map((row) => VisitData.fromMap(row)).toList();
  }

  /// Update visit step data sync status
  Future<void> updateVisitStepDataSyncStatus(
    int id,
    bool isSynced, {
    String? syncError,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'visit_steps_data',
      {
        'is_synced': isSynced ? 1 : 0,
        'synced_at': isSynced ? now : null,
        'sync_error': syncError,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get visit step data statistics
  Future<Map<String, dynamic>> getVisitStepDataStats() async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM visit_steps_data',
    );
    final syncedResult = await db.rawQuery(
      'SELECT COUNT(*) as synced FROM visit_steps_data WHERE is_synced = 1',
    );
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as pending FROM visit_steps_data WHERE is_synced = 0',
    );
    final errorResult = await db.rawQuery(
      'SELECT COUNT(*) as errors FROM visit_steps_data WHERE sync_error IS NOT NULL',
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'synced': Sqflite.firstIntValue(syncedResult) ?? 0,
      'pending': Sqflite.firstIntValue(pendingResult) ?? 0,
      'errors': Sqflite.firstIntValue(errorResult) ?? 0,
    };
  }

  /// Delete old visit step data (cleanup)
  Future<void> deleteOldVisitStepData({
    Duration olderThan = const Duration(days: 30),
  }) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(olderThan).toIso8601String();

    await db.delete(
      'visit_steps_data',
      where: 'created_at < ? AND is_synced = 1',
      whereArgs: [cutoffDate],
    );
  }

  /// Delete visit step data by visit ID
  Future<void> deleteVisitStepDataByVisitId(String visitId) async {
    final db = await database;
    await db.delete(
      'visit_steps_data',
      where: 'visit_id = ?',
      whereArgs: [visitId],
    );
  }

  /// Delete visit step data by client code
  Future<void> deleteVisitStepDataByClient(String clientCode) async {
    final db = await database;
    await db.delete(
      'visit_steps_data',
      where: 'client_code = ?',
      whereArgs: [clientCode],
    );
  }

  /// Delete visit step data by visit ID and step code
  Future<void> deleteVisitStepDataByStepCode(
    String visitId,
    int stepCode,
  ) async {
    final db = await database;
    await db.delete(
      'visit_steps_data',
      where: 'visit_id = ? AND step_code = ?',
      whereArgs: [visitId, stepCode],
    );
  }

  /// Delete a specific visit step data record by ID
  Future<void> deleteVisitStepData(int id) async {
    final db = await database;
    await db.delete('visit_steps_data', where: 'id = ?', whereArgs: [id]);
  }

  /// Save planned routes data
  Future<void> savePlannedRoutes(List<PlannedRoute> routes) async {
    // Ensure tables exist before saving
    await ensureSalesReqPermissionsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing routes for the user(s) being saved
    final userCodes = routes.map((r) => r.userCode).toSet();
    for (final userCode in userCodes) {
      batch.delete(
        'planned_routes',
        where: 'user_code = ?',
        whereArgs: [userCode],
      );
    }

    // Deduplicate routes by (user_code, code_weekday, code_client) to avoid UNIQUE constraint violations
    final uniqueRoutes = <String, PlannedRoute>{};
    for (final route in routes) {
      final key = '${route.userCode}_${route.codeWeekday}_${route.codeClient}';
      uniqueRoutes[key] = route;
    }

    // Add all inserts to batch
    for (final route in uniqueRoutes.values) {
      batch.insert('planned_routes', {
        'user_code': route.userCode,
        'code_weekday': route.codeWeekday,
        'week_day': route.weekDay,
        'code_client': route.codeClient,
        'client_name': route.clientName,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Execute batch operation
    await batch.commit(noResult: true);
  }

  /// Get planned routes for a specific user
  Future<List<PlannedRoute>> getPlannedRoutes(String userCode) async {
    final db = await database;
    final result = await db.query(
      'planned_routes',
      where: 'user_code = ?',
      whereArgs: [userCode],
      orderBy: 'code_weekday ASC, client_name ASC',
    );

    return result.map((row) => PlannedRoute.fromMap(row)).toList();
  }

  /// Get all planned routes
  Future<List<PlannedRoute>> getAllPlannedRoutes() async {
    final db = await database;
    final result = await db.query(
      'planned_routes',

      orderBy: 'code_weekday ASC, client_name ASC',
    );

    return result.map((row) => PlannedRoute.fromMap(row)).toList();
  }

  /// Get planned routes for a specific user and weekday
  Future<List<PlannedRoute>> getPlannedRoutesByWeekday(
    String userCode,
    int codeWeekday,
  ) async {
    final db = await database;
    final result = await db.query(
      'planned_routes',
      where: 'user_code = ? AND code_weekday = ?',
      whereArgs: [userCode, codeWeekday],
      orderBy: 'client_name ASC',
    );

    return result.map((row) => PlannedRoute.fromMap(row)).toList();
  }

  /// Get planned routes for a specific client
  Future<List<PlannedRoute>> getPlannedRoutesByClient(
    String userCode,
    String codeClient,
  ) async {
    final db = await database;
    final result = await db.query(
      'planned_routes',
      where: 'user_code = ? AND code_client = ?',
      whereArgs: [userCode, codeClient],
      orderBy: 'code_weekday ASC',
    );

    return result.map((row) => PlannedRoute.fromMap(row)).toList();
  }

  /// Get all unique weekdays for a user
  Future<List<int>> getUniqueWeekdays(String userCode) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT code_weekday FROM planned_routes WHERE user_code = ? ORDER BY code_weekday ASC',
      [userCode],
    );

    return result.map((row) => row['code_weekday'] as int).toList();
  }

  /// Delete planned routes for a specific user
  Future<void> deletePlannedRoutes(String userCode) async {
    final db = await database;
    await db.delete(
      'planned_routes',
      where: 'user_code = ?',
      whereArgs: [userCode],
    );
  }

  /// Delete all planned routes data
  Future<void> clearPlannedRoutes() async {
    final db = await database;
    await db.delete('planned_routes');
  }

  // ===== CREATE ORDER CRUD METHODS =====

  /// Save create order with related data
  Future<void> saveCreateOrder(CreateOrder order) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use transaction for atomicity
    await db.transaction((txn) async {
      try {
        // Insert main order
        final orderId = await txn.insert('create_order', {
          'code_agent': order.codeAgent,
          'code_client': order.codeClient,
          'code_price': order.codePrice,
          'payment': order.payment,
          'shipping_date': order.shippingDate.toIso8601String(),
          'comment_supervisor': order.commentSupervisor,
          'comment_forwarder': order.commentForwarder,
          'comment': order.comment,
          'create_date': order.createDate.toIso8601String(),
          'longitude': order.longitude,
          'latitude': order.latitude,
          'weight': order.weight,
          'capacity': order.capacity,
          'credit': order.credit ? 1 : 0,
          'code_project': order.codeProject,
          'order_type': order.orderType,
          'code_org': order.codeOrg,
          'code_sklad': order.codeSklad,
          'code_contract': order.codeContract,
          'has_promo': order.hasPromo ? 1 : 0,
          'is_synced': order.isSynced ? 1 : 0,
          'synced_at': order.syncedAt?.toIso8601String(),
          'sync_error': order.syncError,
          'created_at': now,
          'updated_at': now,
        });

        // Insert products
        for (final product in order.products) {
          await txn.insert('create_order_products', {
            'create_order_id': orderId,
            'code_sklad': product.codeSklad,
            'code_product': product.codeProduct,
            'amount': product.amount,
            'price': product.price,
            'total': product.total,
            'weight': product.weight,
            'capacity': product.capacity,
            'payment_type': product.paymentType,
            'discount_sum': product.discountSum,
            'discount_rate': product.discountRate,
            'gift_amount': product.giftAmount,
            'promo': product.promo ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          });
        }

        // Insert competitive intelligence
        for (final ci in order.competitiveIntelligence) {
          await txn.insert('competitive_intelligence', {
            'create_order_id': orderId,
            'competitor': ci.competitor,
            'product': ci.product,
            'price': ci.price,
            'created_at': now,
            'updated_at': now,
          });
        }

        // Insert credit details
        for (final cd in order.creditDetails) {
          await txn.insert('credit_details', {
            'create_order_id': orderId,
            'date_of_payment': cd.dateOfPayment.toIso8601String(),
            'total': cd.total,
            'created_at': now,
            'updated_at': now,
          });
        }
      } catch (e) {
        if (kDebugMode) print('Error saving create order: $e');
        rethrow;
      }
    });
  }

  /// Get create orders by agent code
  Future<List<CreateOrder>> getCreateOrders(
    String codeAgent, {
    bool? isSynced,
  }) async {
    final db = await database;
    String whereClause = 'WHERE code_agent = ?';
    List<dynamic> whereArgs = [codeAgent];

    if (isSynced != null) {
      whereClause += ' AND is_synced = ?';
      whereArgs.add(isSynced ? 1 : 0);
    }

    final orderResults = await db.rawQuery('''
      SELECT * FROM create_order
      $whereClause
      ORDER BY create_date DESC
    ''', whereArgs);

    final orders = <CreateOrder>[];

    for (final orderRow in orderResults) {
      final orderId = orderRow['id'] as int;

      // Get products
      final productResults = await db.query(
        'create_order_products',
        where: 'create_order_id = ?',
        whereArgs: [orderId],
      );

      // Get competitive intelligence
      final ciResults = await db.query(
        'competitive_intelligence',
        where: 'create_order_id = ?',
        whereArgs: [orderId],
      );

      // Get credit details
      final cdResults = await db.query(
        'credit_details',
        where: 'create_order_id = ?',
        whereArgs: [orderId],
      );

      final products = productResults
          .map(
            (row) => CreateOrderProduct(
              id: row['id'] as int?,
              createOrderId: row['create_order_id'] as int?,
              codeSklad: row['code_sklad'] as String,
              codeProduct: row['code_product'] as String,
              vendorCode: row['vendor_code'] as String,
              amount: row['amount'] as int,
              price: (row['price'] as num?)?.toDouble() ?? 0.0,
              total: (row['total'] as num?)?.toDouble() ?? 0.0,
              weight: (row['weight'] as num?)?.toDouble() ?? 0.0,
              capacity: (row['capacity'] as num?)?.toDouble() ?? 0.0,
              paymentType: row['payment_type'] as int,
              discountSum: (row['discount_sum'] as num?)?.toDouble() ?? 0.0,
              discountRate: (row['discount_rate'] as num?)?.toDouble() ?? 0.0,
              giftAmount: row['gift_amount'] as int,
              promo: (row['promo'] as int?) == 1,
            ),
          )
          .toList();

      final competitiveIntelligence = ciResults
          .map(
            (row) => CompetitiveIntelligence(
              id: row['id'] as int?,
              createOrderId: row['create_order_id'] as int?,
              competitor: row['competitor'] as String,
              product: row['product'] as String,
              price: (row['price'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      final creditDetails = cdResults
          .map(
            (row) => CreditDetail(
              id: row['id'] as int?,
              createOrderId: row['create_order_id'] as int?,
              dateOfPayment: DateTime.parse(row['date_of_payment'] as String),
              total: (row['total'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      orders.add(
        CreateOrder(
          id: orderRow['id'] as int?,
          codeAgent: orderRow['code_agent'] as String,
          codeClient: orderRow['code_client'] as String,
          codePrice: orderRow['code_price'] as String,
          payment: orderRow['payment'] as String,
          shippingDate: DateTime.parse(orderRow['shipping_date'] as String),
          commentSupervisor: orderRow['comment_supervisor'] as String?,
          commentForwarder: orderRow['comment_forwarder'] as String?,
          comment: orderRow['comment'] as String?,
          createDate: DateTime.parse(orderRow['create_date'] as String),
          longitude: (orderRow['longitude'] as num?)?.toDouble() ?? 0.0,
          latitude: (orderRow['latitude'] as num?)?.toDouble() ?? 0.0,
          weight: (orderRow['weight'] as num?)?.toDouble() ?? 0.0,
          capacity: (orderRow['capacity'] as num?)?.toDouble() ?? 0.0,
          credit: (orderRow['credit'] as int?) == 1,
          codeProject: orderRow['code_project'] as String,
          orderType: orderRow['order_type'] as int,
          codeOrg: orderRow['code_org'] as String,
          codeSklad: orderRow['code_sklad'] as String,
          codeContract: orderRow['code_contract'] as String?,
          hasPromo: (orderRow['has_promo'] as int?) == 1,
          isSynced: (orderRow['is_synced'] as int?) == 1,
          syncedAt: orderRow['synced_at'] != null
              ? DateTime.parse(orderRow['synced_at'] as String)
              : null,
          syncError: orderRow['sync_error'] as String?,
          products: products,
          competitiveIntelligence: competitiveIntelligence,
          creditDetails: creditDetails,
        ),
      );
    }

    return orders;
  }

  /// Get create order by ID
  Future<CreateOrder?> getCreateOrderById(int id) async {
    final db = await database;
    final orderResults = await db.query(
      'create_order',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (orderResults.isEmpty) return null;

    final orders = await getCreateOrders(
      '',
      isSynced: null,
    ); // Get all and filter
    return orders.firstWhere((order) => order.id == id);
  }

  /// Update create order sync status
  Future<void> updateCreateOrderSyncStatus(
    int id,
    bool isSynced, {
    String? syncError,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'create_order',
      {
        'is_synced': isSynced ? 1 : 0,
        'synced_at': isSynced ? now : null,
        'sync_error': syncError,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete create order
  Future<void> deleteCreateOrder(int id) async {
    final db = await database;
    await db.delete('create_order', where: 'id = ?', whereArgs: [id]);
  }

  /// Get unsynced create orders
  Future<List<CreateOrder>> getUnsyncedCreateOrders() async {
    final db = await database;
    final orderResults = await db.query(
      'create_order',
      where: 'is_synced = 0',
      orderBy: 'create_date ASC',
    );

    final orders = <CreateOrder>[];

    for (final orderRow in orderResults) {
      final orderId = orderRow['id'] as int;

      // Get products
      final productResults = await db.query(
        'create_order_products',
        where: 'create_order_id = ?',
        whereArgs: [orderId],
      );

      // Get competitive intelligence
      final ciResults = await db.query(
        'competitive_intelligence',
        where: 'create_order_id = ?',
        whereArgs: [orderId],
      );

      // Get credit details
      final cdResults = await db.query(
        'credit_details',
        where: 'create_order_id = ?',
        whereArgs: [orderId],
      );

      final products = productResults
          .map(
            (row) => CreateOrderProduct(
              id: row['id'] as int?,
              createOrderId: row['create_order_id'] as int?,
              codeSklad: row['code_sklad'] as String,
              codeProduct: row['code_product'] as String,
              vendorCode: row['vendor_code'] as String,
              amount: row['amount'] as int,
              price: (row['price'] as num?)?.toDouble() ?? 0.0,
              total: (row['total'] as num?)?.toDouble() ?? 0.0,
              weight: (row['weight'] as num?)?.toDouble() ?? 0.0,
              capacity: (row['capacity'] as num?)?.toDouble() ?? 0.0,
              paymentType: row['payment_type'] as int,
              discountSum: (row['discount_sum'] as num?)?.toDouble() ?? 0.0,
              discountRate: (row['discount_rate'] as num?)?.toDouble() ?? 0.0,
              giftAmount: row['gift_amount'] as int,
              promo: (row['promo'] as int?) == 1,
            ),
          )
          .toList();

      final competitiveIntelligence = ciResults
          .map(
            (row) => CompetitiveIntelligence(
              id: row['id'] as int?,
              createOrderId: row['create_order_id'] as int?,
              competitor: row['competitor'] as String,
              product: row['product'] as String,
              price: (row['price'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      final creditDetails = cdResults
          .map(
            (row) => CreditDetail(
              id: row['id'] as int?,
              createOrderId: row['create_order_id'] as int?,
              dateOfPayment: DateTime.parse(row['date_of_payment'] as String),
              total: (row['total'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      orders.add(
        CreateOrder(
          id: orderRow['id'] as int?,
          codeAgent: orderRow['code_agent'] as String,
          codeClient: orderRow['code_client'] as String,
          codePrice: orderRow['code_price'] as String,
          payment: orderRow['payment'] as String,
          shippingDate: DateTime.parse(orderRow['shipping_date'] as String),
          commentSupervisor: orderRow['comment_supervisor'] as String?,
          commentForwarder: orderRow['comment_forwarder'] as String?,
          comment: orderRow['comment'] as String?,
          createDate: DateTime.parse(orderRow['create_date'] as String),
          longitude: (orderRow['longitude'] as num?)?.toDouble() ?? 0.0,
          latitude: (orderRow['latitude'] as num?)?.toDouble() ?? 0.0,
          weight: (orderRow['weight'] as num?)?.toDouble() ?? 0.0,
          capacity: (orderRow['capacity'] as num?)?.toDouble() ?? 0.0,
          credit: (orderRow['credit'] as int?) == 1,
          codeProject: orderRow['code_project'] as String,
          orderType: orderRow['order_type'] as int,
          codeOrg: orderRow['code_org'] as String,
          codeSklad: orderRow['code_sklad'] as String,
          codeContract: orderRow['code_contract'] as String?,
          hasPromo: (orderRow['has_promo'] as int?) == 1,
          isSynced: (orderRow['is_synced'] as int?) == 1,
          syncedAt: orderRow['synced_at'] != null
              ? DateTime.parse(orderRow['synced_at'] as String)
              : null,
          syncError: orderRow['sync_error'] as String?,
          products: products,
          competitiveIntelligence: competitiveIntelligence,
          creditDetails: creditDetails,
        ),
      );
    }

    return orders;
  }

  /// Clear all create order data
  Future<void> clearCreateOrderData() async {
    final db = await database;
    await db.delete('create_order');
    await db.delete('create_order_products');
    await db.delete('competitive_intelligence');
    await db.delete('credit_details');
  }

  /// Update client coordinates in the database
  /// This method updates the latitude and longitude of a specific client
  Future<void> updateClientCoordinates(
    String clientCode,
    double latitude,
    double longitude,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'clients',
      {'latitude': latitude, 'longitude': longitude, 'updated_at': now},
      where: 'code = ?',
      whereArgs: [clientCode],
    );

    if (kDebugMode) {
      print(
        'Updated coordinates for client $clientCode: lat=$latitude, lng=$longitude',
      );
    }
  }

  /// Local-cache mirror of the V2 `PATCH /api/mobile/v2/customers/
  /// {code_1c}/` response. Updates only the fields the V2 endpoint
  /// owns (name / inn / phone / address); other columns are
  /// untouched so coordinates / classifiers / 1C codes stay
  /// authoritative until the next SOAP sync.
  ///
  /// `null` arguments leave the column alone (matches PATCH
  /// semantics on the server side).
  Future<void> updateClientProfile({
    required String clientCode,
    String? name,
    String? inn,
    String? phone,
    String? address,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (name != null) 'name': name,
      if (inn != null) 'inn': inn,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };
    if (values.length == 1) {
      // Only the timestamp would change — no-op.
      return;
    }
    await db.update(
      'clients',
      values,
      where: 'code = ?',
      whereArgs: [clientCode],
    );
    if (kDebugMode) {
      print(
        'Updated profile for client $clientCode: '
        'fields=${values.keys.where((k) => k != "updated_at").join(",")}',
      );
    }
  }

  /// Ensure sales req permissions table exists (for migration issues)
  Future<void> ensureSalesReqPermissionsTableExists() async {
    final db = await database;

    // Check if sales_req_permissions table exists
    final salesReqPermissionsTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sales_req_permissions'",
    );

    if (salesReqPermissionsTable.isEmpty) {
      // Create sales_req_permissions table
      await db.execute('''
        CREATE TABLE sales_req_permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_code TEXT UNIQUE NOT NULL,
          skip_tin_duplicate_check INTEGER NOT NULL DEFAULT 0,
          allow_creation_without_tin INTEGER NOT NULL DEFAULT 0,
          visit INTEGER NOT NULL DEFAULT 0,
          strict_sequence INTEGER NOT NULL DEFAULT 0,
          unplanned_order INTEGER NOT NULL DEFAULT 0,
          planned_route INTEGER NOT NULL DEFAULT 0,
          edit_client_coordinates INTEGER NOT NULL DEFAULT 0,
          client_zone_access INTEGER NOT NULL DEFAULT 0,
          location_update_interval INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    } else {
      // Check if edit_client_coordinates column exists, add it if not
      final columns = await db.rawQuery(
        "PRAGMA table_info(sales_req_permissions)",
      );
      final hasEditClientCoordinates = columns.any(
        (col) => col['name'] == 'edit_client_coordinates',
      );

      if (!hasEditClientCoordinates) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN edit_client_coordinates INTEGER NOT NULL DEFAULT 0',
        );
      }

      // Check if client_zone_access column exists, add it if not
      final hasClientZoneAccess = columns.any(
        (col) => col['name'] == 'client_zone_access',
      );
      if (!hasClientZoneAccess) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN client_zone_access INTEGER NOT NULL DEFAULT 0',
        );
      }

      // Check if location_update_interval column exists, add it if not
      final hasLocationUpdateInterval = columns.any(
        (col) => col['name'] == 'location_update_interval',
      );
      if (!hasLocationUpdateInterval) {
        await db.execute(
          'ALTER TABLE sales_req_permissions ADD COLUMN location_update_interval INTEGER NOT NULL DEFAULT 0',
        );
      }
    }

    // Check if visit_steps table exists
    final visitStepsTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='visit_steps'",
    );

    if (visitStepsTable.isEmpty) {
      // Create visit_steps table
      await db.execute('''
        CREATE TABLE visit_steps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sales_req_permissions_id INTEGER NOT NULL,
          step_code INTEGER NOT NULL,
          step_name TEXT NOT NULL,
          step_required INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP),
          updated_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP),
          FOREIGN KEY (sales_req_permissions_id) REFERENCES sales_req_permissions (id) ON DELETE CASCADE
        )
      ''');
    }

    // Check if visit_steps_data table exists
    final visitStepsDataTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='visit_steps_data'",
    );

    if (visitStepsDataTable.isEmpty) {
      // Create visit_steps_data table
      await db.execute('''
        CREATE TABLE visit_steps_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_id TEXT NOT NULL,
          client_code TEXT NOT NULL,
          step_code INTEGER NOT NULL,
          step_name TEXT NOT NULL,
          data_type TEXT NOT NULL,
          data_content TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          synced_at TEXT,
          sync_error TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }

    // Check if planned_routes table exists
    final plannedRoutesTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='planned_routes'",
    );

    if (plannedRoutesTable.isEmpty) {
      // Create planned_routes table
      await db.execute('''
        CREATE TABLE planned_routes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_code TEXT NOT NULL,
          code_weekday INTEGER NOT NULL,
          week_day TEXT NOT NULL,
          code_client TEXT NOT NULL,
          client_name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(user_code, code_weekday, code_client)
        )
      ''');
    }

    // Create indexes if they don't exist
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_req_permissions_user_code ON sales_req_permissions(user_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_sales_req_permissions_id ON visit_steps(sales_req_permissions_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_step_code ON visit_steps(step_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_visit_id ON visit_steps_data(visit_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_client_code ON visit_steps_data(client_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_step_code ON visit_steps_data(step_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_data_type ON visit_steps_data(data_type)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_is_synced ON visit_steps_data(is_synced)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_visit_steps_data_timestamp ON visit_steps_data(timestamp)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_planned_routes_user_code ON planned_routes(user_code)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_planned_routes_code_weekday ON planned_routes(code_weekday)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_planned_routes_code_client ON planned_routes(code_client)',
      );
    } catch (e) {
      // Indexes might already exist, ignore error
      if (kDebugMode)
        print(
          'Warning: Could not create indexes, they might already exist: $e',
        );
    }
  }

  // ===== USER ORGANIZATIONS CRUD METHODS =====

  /// Save user organizations data
  /// This method saves organizations associated with a specific user
  /// Ensures table exists before operations and handles errors gracefully
  Future<void> saveUserOrganizations(
    String userCode,
    List<UserOrganization> organizations,
  ) async {
    try {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Saving ${organizations.length} user organizations for user: $userCode',
        );
      }

      // Ensure table exists before performing operations
      await ensureUserOrganizationsTableExists();

      final db = await database;
      final now = DateTime.now().toIso8601String();

      // Use batch operations for much better performance
      final batch = db.batch();

      // Delete all existing organizations for this user
      batch.delete(
        'user_organizations',
        where: 'user_code = ?',
        whereArgs: [userCode],
      );

      // Deduplicate organizations by code to avoid UNIQUE constraint violations
      final uniqueOrganizations = <String, UserOrganization>{};
      for (final organization in organizations) {
        uniqueOrganizations[organization.code] = organization;
      }

      // Add all inserts to batch with REPLACE conflict algorithm
      // This handles cases where the same organization code exists for different users
      for (final organization in uniqueOrganizations.values) {
        batch.insert('user_organizations', {
          'code': organization.code,
          'name': organization.name,
          'user_code': userCode,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Execute batch operation
      await batch.commit(noResult: true);

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Successfully saved ${uniqueOrganizations.length} user organizations',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error saving user organizations: $e');
      }
      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }

  /// Get user organizations for a specific user
  Future<List<UserOrganization>> getUserOrganizations(String userCode) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    final result = await db.query(
      'user_organizations',
      where: 'user_code = ?',
      whereArgs: [userCode],
      orderBy: 'name ASC',
    );

    return result
        .map(
          (row) => UserOrganization(
            id: row['id'] as int?,
            code: row['code'] as String,
            name: row['name'] as String,
            userCode: row['user_code'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  /// Get user organization by code
  Future<UserOrganization?> getUserOrganizationByCode(String code) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    final result = await db.query(
      'user_organizations',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return UserOrganization(
      id: row['id'] as int?,
      code: row['code'] as String,
      name: row['name'] as String,
      userCode: row['user_code'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Save single user organization
  Future<void> saveUserOrganization(UserOrganization organization) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('user_organizations', {
      'code': organization.code,
      'name': organization.name,
      'user_code': organization.userCode,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update user organization
  Future<void> updateUserOrganization(
    String code,
    UserOrganization organization,
  ) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'user_organizations',
      {'name': organization.name, 'updated_at': now},
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  /// Delete user organization by code
  Future<void> deleteUserOrganization(String code) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    await db.delete('user_organizations', where: 'code = ?', whereArgs: [code]);
  }

  /// Delete all user organizations for a specific user
  Future<void> deleteUserOrganizationsByUserCode(String userCode) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    await db.delete(
      'user_organizations',
      where: 'user_code = ?',
      whereArgs: [userCode],
    );
  }

  /// Get all user organizations (for admin/debug purposes)
  Future<List<UserOrganization>> getAllUserOrganizations() async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    final result = await db.query(
      'user_organizations',
      orderBy: 'user_code ASC, name ASC',
    );

    return result
        .map(
          (row) => UserOrganization(
            id: row['id'] as int?,
            code: row['code'] as String,
            name: row['name'] as String,
            userCode: row['user_code'] as String,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
            updatedAt: row['updated_at'] != null
                ? DateTime.parse(row['updated_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  /// Get user organizations count for a specific user
  Future<int> getUserOrganizationsCount(String userCode) async {
    // Ensure table exists before performing operations
    await ensureUserOrganizationsTableExists();

    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM user_organizations WHERE user_code = ?',
      [userCode],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Generic method to ensure a table exists
  /// This method checks if the table exists and creates it if not
  Future<void> ensureTableExists(
    String tableName,
    String createTableSql, [
    List<String>? indexSqls,
  ]) async {
    final db = await database;

    // Check if table exists
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );

    if (tableExists.isEmpty) {
      // Create table
      await db.execute(createTableSql);

      // Create indexes if provided
      if (indexSqls != null) {
        for (final indexSql in indexSqls) {
          await db.execute(indexSql);
        }
      }

      if (kDebugMode) {
        print('Created $tableName table');
      }
    }
  }

  /// Get table creation SQL for all tables
  /// This method returns a map of table names to their creation SQL and indexes
  Map<String, Map<String, dynamic>> getTableCreationSql() {
    return {
      'kpi_data': {
        'sql': '''
          CREATE TABLE kpi_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_code TEXT NOT NULL,
            plan TEXT NOT NULL,
            fact TEXT NOT NULL,
            total_percent TEXT NOT NULL,
            total_forecast TEXT NOT NULL,
            total_percent_forecast_fact TEXT NOT NULL,
            akb_plan TEXT NOT NULL,
            akb_fact TEXT NOT NULL,
            akb_percent TEXT NOT NULL,
            okb TEXT NOT NULL,
            update_date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'business_regions': {
        'sql': '''
          CREATE TABLE business_regions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'user_warehouses': {
        'sql': '''
          CREATE TABLE user_warehouses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            organization TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'product_brands': {
        'sql': '''
          CREATE TABLE product_brands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'product_series': {
        'sql': '''
          CREATE TABLE product_series (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brand_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (brand_name) REFERENCES product_brands (name) ON DELETE CASCADE,
            UNIQUE(name, brand_name)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_product_series_brand_name ON product_series(brand_name)',
        ],
      },
      'product_balances': {
        'sql': '''
          CREATE TABLE product_balances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code_sklad TEXT NOT NULL,
            code_product TEXT NOT NULL,
            name_product TEXT NOT NULL,
            have INTEGER NOT NULL,
            reserved INTEGER NOT NULL,
            available INTEGER NOT NULL,
            weight REAL NOT NULL,
            capacity REAL NOT NULL,
            code_project TEXT NOT NULL,
            vendor_code TEXT NOT NULL,
            product_brand TEXT NOT NULL,
            product_series TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (code_sklad) REFERENCES user_warehouses (code) ON DELETE CASCADE,
            FOREIGN KEY (code_product) REFERENCES products (code) ON DELETE CASCADE,
            FOREIGN KEY (product_brand) REFERENCES product_brands (name) ON DELETE CASCADE,
            UNIQUE(code_sklad, code_product)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_product_balances_code_sklad ON product_balances(code_sklad)',
          'CREATE INDEX idx_product_balances_code_product ON product_balances(code_product)',
          'CREATE INDEX idx_product_balances_product_brand ON product_balances(product_brand)',
          'CREATE INDEX idx_product_balances_product_series ON product_balances(product_series)',
        ],
      },
      'clients': {
        'sql': '''
          CREATE TABLE clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            code_1c TEXT NOT NULL DEFAULT '',
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            phone TEXT,
            inn TEXT,
            contact_person TEXT,
            latitude REAL DEFAULT 0.0,
            longitude REAL DEFAULT 0.0,
            region TEXT,
            district TEXT,
            status TEXT DEFAULT 'active',
            last_visit_date TEXT,
            has_orders INTEGER DEFAULT 0,
            has_contracts INTEGER DEFAULT 0,
            is_visited INTEGER DEFAULT 0,
            has_contract INTEGER DEFAULT 0,
            owner_name TEXT,
            signboard TEXT,
            reference_point TEXT,
            responsible_person TEXT,
            responsible_person_phone TEXT,
            trade_point_type TEXT,
            credit_limit REAL DEFAULT 0.0,
            accumulated_credit REAL DEFAULT 0.0,
            code_region TEXT REFERENCES business_regions(code) ON DELETE SET NULL,
            channel_code TEXT,
            trading_point_type_code TEXT,
            client_class TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_clients_code_region ON clients(code_region)',
          'CREATE INDEX idx_clients_channel_code ON clients(channel_code)',
          'CREATE INDEX idx_clients_trading_point_type_code ON clients(trading_point_type_code)',
          'CREATE INDEX idx_clients_client_class ON clients(client_class)',
        ],
      },
      'client_contracts': {
        'sql': '''
          CREATE TABLE client_contracts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code_contract TEXT UNIQUE NOT NULL,
            date_of_contract TEXT,
            sum_of_contract REAL NOT NULL,
            term_of_contract TEXT,
            type_contract TEXT,
            numb_reference TEXT,
            numb_certificate TEXT,
            term_reference TEXT,
            term_certificate TEXT,
            numb_passport TEXT,
            term_passport TEXT,
            certificate_unlimited INTEGER NOT NULL,
            code_district TEXT,
            name_district TEXT,
            code_project TEXT,
            code_client TEXT NOT NULL,
            active INTEGER NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (code_client) REFERENCES clients (code) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_client_contracts_code_contract ON client_contracts(code_contract)',
          'CREATE INDEX idx_client_contracts_code_client ON client_contracts(code_client)',
          'CREATE INDEX idx_client_contracts_active ON client_contracts(active)',
          'CREATE INDEX idx_client_contracts_status ON client_contracts(status)',
        ],
      },
      'products': {
        'sql': '''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            unit TEXT NOT NULL,
            quantity REAL DEFAULT 0.0,
            reserved REAL DEFAULT 0.0,
            available REAL DEFAULT 0.0,
            category TEXT,
            barcode TEXT,
            have INTEGER DEFAULT 0,
            warehouse_code TEXT,
            weight REAL DEFAULT 0.0,
            capacity REAL DEFAULT 0.0,
            vendor_code TEXT,
            product_brand TEXT,
            product_series TEXT,
            code_project TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_products_warehouse_code ON products(warehouse_code)',
          'CREATE INDEX idx_products_code_project ON products(code_project)',
        ],
      },
      'price_types': {
        'sql': '''
          CREATE TABLE price_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            is_default INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'product_prices': {
        'sql': '''
          CREATE TABLE product_prices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_code TEXT NOT NULL,
            price_type_code TEXT NOT NULL,
            price REAL NOT NULL,
            currency TEXT DEFAULT 'UZS',
            valid_from TEXT,
            valid_to TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (product_code) REFERENCES products (code) ON DELETE CASCADE,
            FOREIGN KEY (price_type_code) REFERENCES price_types (code) ON DELETE CASCADE,
            UNIQUE(product_code, price_type_code)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_product_prices_price_type_code ON product_prices(price_type_code)',
          'CREATE INDEX idx_product_prices_product_code ON product_prices(product_code)',
        ],
      },
      'promotions': {
        'sql': '''
          CREATE TABLE promotions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            min_promo_product_count INTEGER NOT NULL,
            bonus_count INTEGER NOT NULL,
            date_start TEXT NOT NULL,
            date_end TEXT NOT NULL,
            last_synced TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_promotions_code ON promotions(code)',
          'CREATE INDEX idx_promotions_active ON promotions(is_active)',
          'CREATE INDEX idx_promotions_date_range ON promotions(date_start, date_end)',
        ],
      },
      'promotion_product_list': {
        'sql': '''
          CREATE TABLE promotion_product_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            promotion_code TEXT NOT NULL,
            product_code TEXT NOT NULL,
            product_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
            UNIQUE(promotion_code, product_code)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)',
        ],
      },
      'promotion_bonus_list': {
        'sql': '''
          CREATE TABLE promotion_bonus_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            promotion_code TEXT NOT NULL,
            product_code TEXT NOT NULL,
            product_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
            UNIQUE(promotion_code, product_code)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)',
        ],
      },
      'promotion_class_list': {
        'sql': '''
          CREATE TABLE promotion_class_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            promotion_code TEXT NOT NULL,
            class_code TEXT NOT NULL,
            class_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
            UNIQUE(promotion_code, class_code)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)',
        ],
      },
      'main_reports': {
        'sql': '''
          CREATE TABLE main_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_code TEXT NOT NULL,
            date_start TEXT NOT NULL,
            date_end TEXT NOT NULL,
            count_akb INTEGER NOT NULL,
            count_okb INTEGER NOT NULL,
            cash REAL NOT NULL,
            transfer REAL NOT NULL,
            sum REAL NOT NULL,
            count_visited INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_main_reports_user_code ON main_reports(user_code)',
          'CREATE INDEX idx_main_reports_date_range ON main_reports(date_start, date_end)',
        ],
      },
      'business_region_reports': {
        'sql': '''
          CREATE TABLE business_region_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            main_report_id INTEGER NOT NULL,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            akb INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_business_region_reports_main_report_id ON business_region_reports(main_report_id)',
        ],
      },
      'akb_by_categories': {
        'sql': '''
          CREATE TABLE akb_by_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            main_report_id INTEGER NOT NULL,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            akb INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_akb_by_categories_main_report_id ON akb_by_categories(main_report_id)',
        ],
      },
      'visit_plans': {
        'sql': '''
          CREATE TABLE visit_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            main_report_id INTEGER NOT NULL,
            client_code TEXT NOT NULL,
            client_name TEXT NOT NULL,
            planned_date TEXT NOT NULL,
            actual_visit_date TEXT,
            is_completed INTEGER DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (main_report_id) REFERENCES main_reports (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_visit_plans_main_report_id ON visit_plans(main_report_id)',
          'CREATE INDEX idx_visit_plans_client_code ON visit_plans(client_code)',
        ],
      },
      'visit_plan_lists': {
        'sql': '''
          CREATE TABLE visit_plan_lists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            visit_plan_id INTEGER NOT NULL,
            product_code TEXT NOT NULL,
            product_name TEXT NOT NULL,
            planned_quantity INTEGER NOT NULL,
            actual_quantity INTEGER,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (visit_plan_id) REFERENCES visit_plans (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_visit_plan_lists_visit_plan_id ON visit_plan_lists(visit_plan_id)',
        ],
      },
      'order_statuses': {
        'sql': '''
          CREATE TABLE order_statuses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_order_statuses_message ON order_statuses(message)',
        ],
      },
      'couriers': {
        'sql': '''
          CREATE TABLE couriers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            car TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': ['CREATE INDEX idx_couriers_name ON couriers(name)'],
      },
      'courier_cars': {
        'sql': '''
          CREATE TABLE courier_cars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            car TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': ['CREATE INDEX idx_courier_cars_car ON courier_cars(car)'],
      },
      'order_couriers': {
        'sql': '''
          CREATE TABLE order_couriers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_num TEXT NOT NULL,
            courier_name TEXT,
            courier_car TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (order_num) REFERENCES orders (num_order) ON DELETE CASCADE,
            FOREIGN KEY (courier_name) REFERENCES couriers (name) ON DELETE SET NULL,
            FOREIGN KEY (courier_car) REFERENCES courier_cars (car) ON DELETE SET NULL,
            UNIQUE(order_num)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_order_couriers_order_num ON order_couriers(order_num)',
        ],
      },
      'orders': {
        'sql': '''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            num_order TEXT UNIQUE NOT NULL,
            date_order TEXT NOT NULL,
            caption_order TEXT NOT NULL,
            type_price_code TEXT NOT NULL,
            status INTEGER NOT NULL,
            comment_supervisor TEXT,
            comment_forwarder TEXT,
            comment_agent TEXT,
            total REAL NOT NULL,
            client_code TEXT NOT NULL,
            client_name TEXT NOT NULL,
            code_org TEXT NOT NULL,
            main_status TEXT NOT NULL,
            courier_name TEXT,
            courier_car TEXT,
            server INTEGER NOT NULL DEFAULT 0,
            promo INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (type_price_code) REFERENCES price_types (code) ON DELETE CASCADE,
            FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE,
            FOREIGN KEY (main_status) REFERENCES order_statuses (message) ON DELETE SET NULL,
            FOREIGN KEY (courier_name) REFERENCES couriers (name) ON DELETE SET NULL,
            FOREIGN KEY (courier_car) REFERENCES courier_cars (car) ON DELETE SET NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_orders_num_order ON orders(num_order)',
          'CREATE INDEX idx_orders_client_code ON orders(client_code)',
          'CREATE INDEX idx_orders_type_price_code ON orders(type_price_code)',
          'CREATE INDEX idx_orders_main_status ON orders(main_status)',
        ],
      },
      'order_details': {
        'sql': '''
          CREATE TABLE order_details (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            num_order TEXT UNIQUE NOT NULL,
            credit INTEGER NOT NULL DEFAULT 0,
            code_price TEXT NOT NULL,
            date_order TEXT NOT NULL,
            code_sklad TEXT NOT NULL,
            comment_supervisor TEXT,
            comment_forwarder TEXT,
            comment_agent TEXT,
            shipping_date TEXT NOT NULL,
            order_type INTEGER NOT NULL DEFAULT 0,
            code_org TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (num_order) REFERENCES orders (num_order) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_order_details_num_order ON order_details(num_order)',
        ],
      },
      'order_detail_products': {
        'sql': '''
          CREATE TABLE order_detail_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_detail_id INTEGER NOT NULL,
            code_product TEXT NOT NULL,
            name_product TEXT NOT NULL,
            amount INTEGER NOT NULL,
            price REAL NOT NULL,
            total REAL NOT NULL,
            discount_rate REAL NOT NULL DEFAULT 0.0,
            weight REAL NOT NULL DEFAULT 0.0,
            capacity REAL NOT NULL DEFAULT 0.0,
            price_type_code TEXT,
            price_type_name TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (order_detail_id) REFERENCES order_details (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_order_detail_products_order_detail_id ON order_detail_products(order_detail_id)',
        ],
      },
      'order_payments': {
        'sql': '''
          CREATE TABLE order_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_detail_id INTEGER NOT NULL,
            date_of_payment TEXT NOT NULL,
            total REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (order_detail_id) REFERENCES order_details (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_order_payments_order_detail_id ON order_payments(order_detail_id)',
        ],
      },
      'sales_channels': {
        'sql': '''
          CREATE TABLE sales_channels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            upper_group TEXT,
            is_group INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'trading_point_types': {
        'sql': '''
          CREATE TABLE trading_point_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            channel_group TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_trading_point_types_channel_group ON trading_point_types(channel_group)',
        ],
      },
      'client_classes': {
        'sql': '''
          CREATE TABLE client_classes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            class_code TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'sales_req_permissions': {
        'sql': '''
          CREATE TABLE sales_req_permissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_code TEXT UNIQUE NOT NULL,
            skip_tin_duplicate_check INTEGER NOT NULL DEFAULT 0,
            allow_creation_without_tin INTEGER NOT NULL DEFAULT 0,
            visit INTEGER NOT NULL DEFAULT 0,
            strict_sequence INTEGER NOT NULL DEFAULT 0,
            unplanned_order INTEGER NOT NULL DEFAULT 0,
            planned_route INTEGER NOT NULL DEFAULT 0,
            edit_client_coordinates INTEGER NOT NULL DEFAULT 0,
            client_zone_access INTEGER NOT NULL DEFAULT 0,
            location_update_interval INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_sales_req_permissions_user_code ON sales_req_permissions(user_code)',
        ],
      },
      'visit_steps': {
        'sql': '''
          CREATE TABLE visit_steps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sales_req_permissions_id INTEGER NOT NULL,
            step_code INTEGER NOT NULL,
            step_name TEXT NOT NULL,
            step_required INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (sales_req_permissions_id) REFERENCES sales_req_permissions (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_visit_steps_sales_req_permissions_id ON visit_steps(sales_req_permissions_id)',
          'CREATE INDEX idx_visit_steps_step_code ON visit_steps(step_code)',
        ],
      },
      'visit_steps_data': {
        'sql': '''
          CREATE TABLE visit_steps_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            visit_id TEXT NOT NULL,
            client_code TEXT NOT NULL,
            step_code INTEGER NOT NULL,
            step_name TEXT NOT NULL,
            data_type TEXT NOT NULL,
            data_content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0,
            synced_at TEXT,
            sync_error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_visit_steps_data_visit_id ON visit_steps_data(visit_id)',
          'CREATE INDEX idx_visit_steps_data_client_code ON visit_steps_data(client_code)',
          'CREATE INDEX idx_visit_steps_data_step_code ON visit_steps_data(step_code)',
          'CREATE INDEX idx_visit_steps_data_data_type ON visit_steps_data(data_type)',
          'CREATE INDEX idx_visit_steps_data_is_synced ON visit_steps_data(is_synced)',
          'CREATE INDEX idx_visit_steps_data_timestamp ON visit_steps_data(timestamp)',
        ],
      },
      'planned_routes': {
        'sql': '''
          CREATE TABLE planned_routes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_code TEXT NOT NULL,
            code_weekday INTEGER NOT NULL,
            week_day TEXT NOT NULL,
            code_client TEXT NOT NULL,
            client_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(user_code, code_weekday, code_client)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_planned_routes_user_code ON planned_routes(user_code)',
          'CREATE INDEX idx_planned_routes_code_weekday ON planned_routes(code_weekday)',
          'CREATE INDEX idx_planned_routes_code_client ON planned_routes(code_client)',
        ],
      },
      'create_order': {
        'sql': '''
          CREATE TABLE create_order (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code_agent TEXT NOT NULL,
            code_client TEXT NOT NULL,
            code_price TEXT NOT NULL,
            payment TEXT NOT NULL,
            shipping_date TEXT NOT NULL,
            comment_supervisor TEXT,
            comment_forwarder TEXT,
            comment TEXT,
            create_date TEXT NOT NULL,
            longitude REAL NOT NULL,
            latitude REAL NOT NULL,
            weight REAL NOT NULL,
            capacity REAL NOT NULL,
            credit INTEGER NOT NULL DEFAULT 0,
            code_project TEXT NOT NULL,
            order_type INTEGER NOT NULL DEFAULT 0,
            code_org TEXT NOT NULL,
            code_sklad TEXT NOT NULL,
            code_contract TEXT,
            has_promo INTEGER NOT NULL DEFAULT 0,
            is_synced INTEGER NOT NULL DEFAULT 0,
            synced_at TEXT,
            sync_error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_create_order_code_agent ON create_order(code_agent)',
          'CREATE INDEX idx_create_order_code_client ON create_order(code_client)',
          'CREATE INDEX idx_create_order_is_synced ON create_order(is_synced)',
          'CREATE INDEX idx_create_order_create_date ON create_order(create_date)',
        ],
      },
      'create_order_products': {
        'sql': '''
          CREATE TABLE create_order_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            create_order_id INTEGER NOT NULL,
            code_sklad TEXT NOT NULL,
            code_product TEXT NOT NULL,
            amount INTEGER NOT NULL,
            price REAL NOT NULL,
            total REAL NOT NULL,
            weight REAL NOT NULL,
            capacity REAL NOT NULL,
            payment_type INTEGER NOT NULL,
            discount_sum REAL NOT NULL DEFAULT 0.0,
            discount_rate REAL NOT NULL DEFAULT 0.0,
            gift_amount INTEGER NOT NULL DEFAULT 0,
            promo INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_create_order_products_create_order_id ON create_order_products(create_order_id)',
          'CREATE INDEX idx_create_order_products_code_product ON create_order_products(code_product)',
        ],
      },
      'competitive_intelligence': {
        'sql': '''
          CREATE TABLE competitive_intelligence (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            create_order_id INTEGER NOT NULL,
            competitor TEXT NOT NULL,
            product TEXT NOT NULL,
            price REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_competitive_intelligence_create_order_id ON competitive_intelligence(create_order_id)',
        ],
      },
      'credit_details': {
        'sql': '''
          CREATE TABLE credit_details (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            create_order_id INTEGER NOT NULL,
            date_of_payment TEXT NOT NULL,
            total REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (create_order_id) REFERENCES create_order (id) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_credit_details_create_order_id ON credit_details(create_order_id)',
        ],
      },
      'user_organizations': {
        'sql': '''
          CREATE TABLE user_organizations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            user_code TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_user_organizations_code ON user_organizations(code)',
          'CREATE INDEX idx_user_organizations_user_code ON user_organizations(user_code)',
        ],
      },
      'user_projects': {
        'sql': '''
          CREATE TABLE user_projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            user_code TEXT NOT NULL,
            id_uuid TEXT,
            id_1c TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(code, user_code)
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_user_projects_code ON user_projects(code)',
          'CREATE INDEX idx_user_projects_user_code ON user_projects(user_code)',
        ],
      },
      'client_images': {
        'sql': '''
          CREATE TABLE client_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_code TEXT NOT NULL,
            image_url TEXT,
            image_sm_url TEXT,
            image_md_url TEXT,
            image_lg_url TEXT,
            image_thumbnail_url TEXT,
            image_dimensions TEXT,
            image_sm_dimensions TEXT,
            image_md_dimensions TEXT,
            image_lg_dimensions TEXT,
            image_thumbnail_dimensions TEXT,
            is_main INTEGER DEFAULT 0,
            category TEXT,
            note TEXT,
            status_code TEXT,
            status_name TEXT,
            source_name TEXT,
            source_type TEXT,
            created_at_server TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE
          )
        ''',
        'indexes': [
          'CREATE INDEX idx_client_images_client_code ON client_images(client_code)',
          'CREATE INDEX idx_client_images_is_main ON client_images(is_main)',
          'CREATE INDEX idx_client_images_status_code ON client_images(status_code)',
          'CREATE INDEX idx_client_images_created_at_server ON client_images(created_at_server)',
        ],
      },
      'map_tokens': {
        'sql': '''
          CREATE TABLE map_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            yandex_token TEXT,
            google_token TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''',
        'indexes': <String>[],
      },
      'sync_metadata': {
        'sql': '''
          CREATE TABLE sync_metadata (
            table_name TEXT PRIMARY KEY,
            last_sync_at TEXT NOT NULL,
            records_count INTEGER DEFAULT 0,
            sync_duration_ms INTEGER DEFAULT 0
          )
        ''',
        'indexes': <String>[],
      },
    };
  }

  // ===========================================================================
  // SYNC METADATA METHODS - For conditional sync optimization
  // ===========================================================================

  /// Gets the last sync timestamp for a specific table.
  ///
  /// Returns null if the table has never been synced.
  Future<DateTime?> getLastSyncTime(String tableName) async {
    try {
      final db = await database;
      final result = await db.query(
        'sync_metadata',
        where: 'table_name = ?',
        whereArgs: [tableName],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final lastSyncAt = result.first['last_sync_at'] as String?;
      return lastSyncAt != null ? DateTime.parse(lastSyncAt) : null;
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error getting last sync time for $tableName: $e',
        );
      }
      return null;
    }
  }

  /// Updates the sync metadata for a table after successful sync.
  ///
  /// Parameters:
  /// - [tableName] - Name of the synced table
  /// - [recordsCount] - Number of records synced
  /// - [durationMs] - Duration of sync operation in milliseconds
  Future<void> updateSyncMetadata(
    String tableName, {
    int recordsCount = 0,
    int durationMs = 0,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.insert('sync_metadata', {
        'table_name': tableName,
        'last_sync_at': now,
        'records_count': recordsCount,
        'sync_duration_ms': durationMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Updated sync metadata for $tableName (records: $recordsCount, duration: ${durationMs}ms)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error updating sync metadata for $tableName: $e',
        );
      }
    }
  }

  /// Checks if a table needs synchronization based on max age.
  ///
  /// Parameters:
  /// - [tableName] - Name of the table to check
  /// - [maxAge] - Maximum age before re-sync is required
  ///
  /// Returns: true if sync is needed, false if recent sync exists
  Future<bool> shouldSync(String tableName, Duration maxAge) async {
    final lastSync = await getLastSyncTime(tableName);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Gets all sync metadata for debugging and monitoring.
  Future<List<Map<String, dynamic>>> getAllSyncMetadata() async {
    try {
      final db = await database;
      return await db.query('sync_metadata', orderBy: 'last_sync_at DESC');
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error getting all sync metadata: $e');
      }
      return [];
    }
  }

  /// Clears sync metadata for a specific table (forces re-sync).
  Future<void> clearSyncMetadata(String tableName) async {
    try {
      final db = await database;
      await db.delete(
        'sync_metadata',
        where: 'table_name = ?',
        whereArgs: [tableName],
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error clearing sync metadata for $tableName: $e',
        );
      }
    }
  }

  /// Clears all sync metadata (forces full re-sync).
  Future<void> clearAllSyncMetadata() async {
    try {
      final db = await database;
      await db.delete('sync_metadata');
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error clearing all sync metadata: $e');
      }
    }
  }

  /// Ensure user_organizations table exists (for migration issues)
  /// This method checks if the table exists and creates it if not
  Future<void> ensureUserOrganizationsTableExists() async {
    final tableInfo = getTableCreationSql()['user_organizations'];
    if (tableInfo != null) {
      await ensureTableExists(
        'user_organizations',
        tableInfo['sql'] as String,
        tableInfo['indexes'] as List<String>,
      );
    }
  }

  /// Wipes locally-cached customer data so a `customer_scope=project`
  /// project switch does not leak the previous project's rows.
  ///
  /// Used by `ProjectContext.setActiveProject` — see
  /// `lib/src/core/services/project_context.dart`.
  ///
  /// Safe to call on org-scope tenants too (no-op effect: list re-fetch
  /// brings the same rows back).
  Future<void> clearCustomerCacheForProjectSwitch() async {
    try {
      final db = await database;
      await db.delete('clients');
      await db.delete('client_images');
      await db.delete('client_contracts');
      if (kDebugMode) {
        print(
            'ApiDatabaseService: cleared customer caches for project switch');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'ApiDatabaseService: failed to clear customer caches on project switch: $e');
      }
    }
  }

  /// Проверка и создание таблицы user_projects (для миграции)
  /// user_projects jadvali mavjudligini tekshirish va yaratish (migratsiya uchun)
  /// Ensure user_projects table exists (for migration issues)
  Future<void> ensureUserProjectsTableExists() async {
    final tableInfo = getTableCreationSql()['user_projects'];
    if (tableInfo != null) {
      await ensureTableExists(
        'user_projects',
        tableInfo['sql'] as String,
        tableInfo['indexes'] as List<String>,
      );
    }
  }

  // ===== USER PROJECTS CRUD METHODS =====
  // Методы CRUD для проектов пользователя
  // Foydalanuvchi loyihalari uchun CRUD metodlari

  /// Сохранить проекты пользователя (пакетная операция)
  /// Foydalanuvchi loyihalarini saqlash (batch operatsiya)
  /// Save user projects (batch operation with delete+insert for atomicity)
  Future<void> saveUserProjects(
    String userCode,
    List<UserProject> projects,
  ) async {
    try {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Saving ${projects.length} user projects for user: $userCode',
        );
      }

      // Убедиться, что таблица существует / Jadval mavjudligini tekshirish
      await ensureUserProjectsTableExists();

      final db = await database;
      final now = DateTime.now().toIso8601String();

      // Пакетная операция для производительности / Tezlik uchun batch operatsiya
      final batch = db.batch();

      // Удалить все существующие проекты для этого пользователя
      // Bu foydalanuvchining barcha mavjud loyihalarini o'chirish
      batch.delete(
        'user_projects',
        where: 'user_code = ?',
        whereArgs: [userCode],
      );

      // Дедупликация по code для избежания нарушений UNIQUE
      // UNIQUE constraint buzilishini oldini olish uchun code bo'yicha deduplikatsiya
      final uniqueProjects = <String, UserProject>{};
      for (final project in projects) {
        uniqueProjects[project.code] = project;
      }

      // Добавить все вставки в батч / Barcha insertlarni batchga qo'shish
      for (final project in uniqueProjects.values) {
        batch.insert('user_projects', {
          'code': project.code,
          'name': project.name,
          'user_code': userCode,
          'id_uuid': project.idUuid,
          'id_1c': project.id1c,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Выполнить батч / Batchni bajarish
      await batch.commit(noResult: true);

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Successfully saved ${uniqueProjects.length} user projects',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error saving user projects: $e');
      }
      rethrow;
    }
  }

  /// Получить проекты пользователя по user_code
  /// user_code bo'yicha foydalanuvchi loyihalarini olish
  /// Get user projects for a specific user
  Future<List<UserProject>> getUserProjects(String userCode) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    final result = await db.query(
      'user_projects',
      where: 'user_code = ?',
      whereArgs: [userCode],
      orderBy: 'name ASC',
    );

    return result.map((row) => UserProject.fromMap(row)).toList();
  }

  /// Получить проект по коду / Kod bo'yicha loyihani olish
  /// Get user project by code
  Future<UserProject?> getUserProjectByCode(String code) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    final result = await db.query(
      'user_projects',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UserProject.fromMap(result.first);
  }

  /// Сохранить один проект (upsert) / Bitta loyihani saqlash (upsert)
  /// Save single user project (upsert)
  Future<void> saveUserProject(UserProject project) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('user_projects', {
      'code': project.code,
      'name': project.name,
      'user_code': project.userCode,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Обновить проект / Loyihani yangilash / Update user project
  Future<void> updateUserProject(String code, UserProject project) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'user_projects',
      {'name': project.name, 'updated_at': now},
      where: 'code = ? AND user_code = ?',
      whereArgs: [code, project.userCode],
    );
  }

  /// Удалить проект по коду / Kod bo'yicha loyihani o'chirish
  /// Delete user project by code
  Future<void> deleteUserProject(String code) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    await db.delete('user_projects', where: 'code = ?', whereArgs: [code]);
  }

  /// Удалить все проекты пользователя / Foydalanuvchining barcha loyihalarini o'chirish
  /// Delete all user projects for a specific user
  Future<void> deleteAllUserProjects(String userCode) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    await db.delete(
      'user_projects',
      where: 'user_code = ?',
      whereArgs: [userCode],
    );
  }

  /// Получить все проекты (для отладки) / Barcha loyihalarni olish (debug uchun)
  /// Get all user projects (for admin/debug purposes)
  Future<List<UserProject>> getAllUserProjects() async {
    await ensureUserProjectsTableExists();

    final db = await database;
    final result = await db.query(
      'user_projects',
      orderBy: 'user_code ASC, name ASC',
    );

    return result.map((row) => UserProject.fromMap(row)).toList();
  }

  /// Количество проектов пользователя / Foydalanuvchi loyihalari soni
  /// Get user projects count for a specific user
  Future<int> getUserProjectsCount(String userCode) async {
    await ensureUserProjectsTableExists();

    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM user_projects WHERE user_code = ?',
      [userCode],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Ensure order_details related tables exist (for migration issues)
  /// This method checks if the tables exist and creates them if not
  Future<void> ensureOrderDetailsTablesExist() async {
    try {
      if (kDebugMode) {
        print('ApiDatabaseService: Ensuring order_details tables exist');
      }

      // Ensure order_details table
      final orderDetailsInfo = getTableCreationSql()['order_details'];
      if (orderDetailsInfo != null) {
        await ensureTableExists(
          'order_details',
          orderDetailsInfo['sql'] as String,
          orderDetailsInfo['indexes'] as List<String>,
        );
      }

      // Ensure order_detail_products table
      final orderDetailProductsInfo =
          getTableCreationSql()['order_detail_products'];
      if (orderDetailProductsInfo != null) {
        await ensureTableExists(
          'order_detail_products',
          orderDetailProductsInfo['sql'] as String,
          orderDetailProductsInfo['indexes'] as List<String>,
        );
      }

      // Ensure order_payments table
      final orderPaymentsInfo = getTableCreationSql()['order_payments'];
      if (orderPaymentsInfo != null) {
        await ensureTableExists(
          'order_payments',
          orderPaymentsInfo['sql'] as String,
          orderPaymentsInfo['indexes'] as List<String>,
        );
      }

      if (kDebugMode) {
        print('ApiDatabaseService: Order_details tables ensured successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Error ensuring order_details tables exist: $e',
        );
      }
      rethrow;
    }
  }

  Future<List<Thumbnail>> getThumbnails() async {
    return <Thumbnail>[];
  }

  /// Get total record count for a specific table
  Future<int> getTableRowCount(String tableName) async {
    try {
      final db = await database;
      // Use rawQuery for better performance and to handle dynamic table names
      final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error getting row count for $tableName: $e');
      return 0;
    }
  }

  // ===========================================================================
  // CONTRACT TYPES METHODS
  // ===========================================================================

  /// Save contract types to local cache
  ///
  /// This method clears existing contract types and saves the new list.
  /// Contract types are retrieved from GetTypeOfContract SOAP API.
  ///
  /// Parameters:
  /// - [contractTypes] - List of ContractType objects
  Future<void> saveContractTypes(List<ContractType> contractTypes) async {
    try {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Saving ${contractTypes.length} contract types',
        );
      }

      final db = await database;
      final now = DateTime.now().toIso8601String();

      // Use transaction for better performance
      await db.transaction((txn) async {
        // Clear existing contract types
        await txn.delete('contract_types');

        // Insert new contract types
        for (final contractType in contractTypes) {
          await txn.insert('contract_types', {
            'code': contractType.code,
            'name': contractType.name,
            'created_at': now,
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Successfully saved ${contractTypes.length} contract types',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error saving contract types: $e');
      }
      rethrow;
    }
  }

  /// Get all cached contract types
  ///
  /// Returns a list of ContractType objects.
  /// Returns empty list if no contract types are cached.
  Future<List<ContractType>> getContractTypes() async {
    try {
      if (kDebugMode) {
        print('ApiDatabaseService: Getting cached contract types');
      }

      final db = await database;
      final results = await db.query(
        'contract_types',
        columns: ['code', 'name', 'created_at', 'updated_at'],
        orderBy: 'name ASC',
      );

      final contractTypes = results
          .map(
            (row) => ContractType(
              code: row['code'] as String,
              name: row['name'] as String,
              createdAt: row['created_at'] != null
                  ? DateTime.tryParse(row['created_at'] as String)
                  : null,
              updatedAt: row['updated_at'] != null
                  ? DateTime.tryParse(row['updated_at'] as String)
                  : null,
            ),
          )
          .toList();

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Retrieved ${contractTypes.length} cached contract types',
        );
      }

      return contractTypes;
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error getting contract types: $e');
      }
      return [];
    }
  }

  /// Check if contract types are cached
  ///
  /// Returns true if there are cached contract types, false otherwise.
  Future<bool> hasContractTypes() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM contract_types');
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error checking contract types: $e');
      }
      return false;
    }
  }

  /// Clear all cached contract types
  Future<void> clearContractTypes() async {
    try {
      final db = await database;
      await db.delete('contract_types');
      if (kDebugMode) {
        print('ApiDatabaseService: Cleared contract types cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error clearing contract types: $e');
      }
      rethrow;
    }
  }

  /// Save district contracting data to cache
  ///
  /// Parameters:
  /// - [districts] - List of DistrictContracting objects
  Future<void> saveDistrictContracting(
    List<DistrictContracting> districts,
  ) async {
    try {
      if (kDebugMode) {
        print(
          'ApiDatabaseService: Saving ${districts.length} district contracting records',
        );
      }

      final db = await database;
      final now = DateTime.now().toIso8601String();

      // Ensure table exists (fallback for migration issues)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS district_contracting (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_district TEXT UNIQUE NOT NULL,
          name_district TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_district_contracting_code ON district_contracting(code_district)',
      );

      await db.transaction((txn) async {
        await txn.delete('district_contracting');

        for (final district in districts) {
          await txn.insert('district_contracting', {
            'code_district': district.codeDistrict,
            'name_district': district.nameDistrict,
            'created_at': now,
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Successfully saved ${districts.length} district contracting records',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error saving district contracting: $e');
      }
      rethrow;
    }
  }

  /// Get all cached district contracting data
  ///
  /// Returns a list of DistrictContracting objects.
  /// Returns empty list if no districts are cached.
  Future<List<DistrictContracting>> getDistrictContracting() async {
    try {
      if (kDebugMode) {
        print('ApiDatabaseService: Getting cached district contracting data');
      }

      final db = await database;
      final results = await db.query(
        'district_contracting',
        columns: ['code_district', 'name_district', 'created_at', 'updated_at'],
        orderBy: 'name_district ASC',
      );

      final districts = results
          .map(
            (row) => DistrictContracting(
              codeDistrict: row['code_district'] as String,
              nameDistrict: row['name_district'] as String,
              createdAt: row['created_at'] != null
                  ? DateTime.tryParse(row['created_at'] as String)
                  : null,
              updatedAt: row['updated_at'] != null
                  ? DateTime.tryParse(row['updated_at'] as String)
                  : null,
            ),
          )
          .toList();

      if (kDebugMode) {
        print(
          'ApiDatabaseService: Retrieved ${districts.length} cached district contracting records',
        );
      }

      return districts;
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error getting district contracting: $e');
      }
      return [];
    }
  }

  /// Check if district contracting data is cached
  ///
  /// Returns true if there are cached districts, false otherwise.
  Future<bool> hasDistrictContracting() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM district_contracting',
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error checking district contracting: $e');
      }
      return false;
    }
  }

  /// Clear all cached district contracting data
  Future<void> clearDistrictContracting() async {
    try {
      final db = await database;
      await db.delete('district_contracting');
      if (kDebugMode) {
        print('ApiDatabaseService: Cleared district contracting cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error clearing district contracting: $e');
      }
      rethrow;
    }
  }


  // ============================================================================
  // Sales Classifiers Methods
  // ============================================================================

  /// Save sales channels to database
  /// Uses batch operations for optimal performance
  Future<void> saveSalesChannels(List<SalesChannel> channels) async {
    final db = await database;
    final batch = db.batch();

    // Delete all existing channels
    batch.delete('sales_channels');

    // Insert new channels
    for (final channel in channels) {
      batch.insert('sales_channels', channel.toDatabaseMap());
    }

    await batch.commit(noResult: true);

    if (kDebugMode) {
      print('ApiDatabaseService: Saved ${channels.length} sales channels');
    }
  }

  /// Save trading point types to database
  /// Uses batch operations for optimal performance
  Future<void> saveTradingPointTypes(List<TradingPointType> types) async {
    final db = await database;
    final batch = db.batch();

    // Delete all existing types
    batch.delete('trading_point_types');

    // Insert new types
    for (final type in types) {
      batch.insert('trading_point_types', type.toDatabaseMap());
    }

    await batch.commit(noResult: true);

    if (kDebugMode) {
      print('ApiDatabaseService: Saved ${types.length} trading point types');
    }
  }

  /// Save client classes to database
  /// Uses batch operations for optimal performance
  Future<void> saveClientClasses(List<ClientClass> classes) async {
    final db = await database;
    final batch = db.batch();

    // Delete all existing classes
    batch.delete('client_classes');

    // Insert new classes
    for (final classItem in classes) {
      batch.insert('client_classes', classItem.toDatabaseMap());
    }

    await batch.commit(noResult: true);

    if (kDebugMode) {
      print('ApiDatabaseService: Saved ${classes.length} client classes');
    }
  }

  /// Get all sales channels from database
  Future<List<SalesChannel>> getSalesChannels() async {
    try {
      final db = await database;
      final results = await db.query(
        'sales_channels',
        orderBy: 'name ASC',
      );

      return results.map((row) => SalesChannel.fromJson(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error getting sales channels: $e');
      }
      return [];
    }
  }

  /// Get all trading point types from database
  /// Optionally filter by channel group for cascading dropdown
  Future<List<TradingPointType>> getTradingPointTypes({
    String? channelGroup,
  }) async {
    try {
      final db = await database;
      
      List<Map<String, dynamic>> results;
      if (channelGroup != null && channelGroup.isNotEmpty) {
        results = await db.query(
          'trading_point_types',
          where: 'channel_group = ?',
          whereArgs: [channelGroup],
          orderBy: 'name ASC',
        );
      } else {
        results = await db.query(
          'trading_point_types',
          orderBy: 'name ASC',
        );
      }

      return results.map((row) => TradingPointType.fromJson(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error getting trading point types: $e');
      }
      return [];
    }
  }

  /// Get all client classes from database
  Future<List<ClientClass>> getClientClasses() async {
    try {
      final db = await database;
      final results = await db.query(
        'client_classes',
        orderBy: 'class_code ASC',
      );

      return results.map((row) => ClientClass.fromJson(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error getting client classes: $e');
      }
      return [];
    }
  }

  /// Ensure sales classifiers tables exist (for migration)
  Future<void> ensureSalesClassifiersTablesExist() async {
    try {
      // Ensure sales_channels table
      final channelsInfo = getTableCreationSql()['sales_channels'];
      if (channelsInfo != null) {
        await ensureTableExists(
          'sales_channels',
          channelsInfo['sql'] as String,
          channelsInfo['indexes'] as List<String>,
        );
      }

      // Ensure trading_point_types table
      final typesInfo = getTableCreationSql()['trading_point_types'];
      if (typesInfo != null) {
        await ensureTableExists(
          'trading_point_types',
          typesInfo['sql'] as String,
          typesInfo['indexes'] as List<String>,
        );
      }

      // Ensure client_classes table
      final classesInfo = getTableCreationSql()['client_classes'];
      if (classesInfo != null) {
        await ensureTableExists(
          'client_classes',
          classesInfo['sql'] as String,
          classesInfo['indexes'] as List<String>,
        );
      }

      // Add new columns to clients table if they don't exist
      final db = await database;
      await _addColumnIfNotExists(db, 'clients', 'channel_code', 'TEXT');
      await _addColumnIfNotExists(db, 'clients', 'trading_point_type_code', 'TEXT');
      await _addColumnIfNotExists(db, 'clients', 'client_class', 'TEXT');

      if (kDebugMode) {
        print('ApiDatabaseService: Sales classifiers tables ensured');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error ensuring sales classifiers tables: $e');
      }
    }
  }

  /// Helper method to add column if it doesn't exist
  Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    try {
      // Check if column exists
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists = result.any((row) => row['name'] == columnName);

      if (!columnExists) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
        if (kDebugMode) {
          print('ApiDatabaseService: Added column $columnName to $tableName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiDatabaseService: Error adding column $columnName to $tableName: $e');
      }
    }
  }
}
