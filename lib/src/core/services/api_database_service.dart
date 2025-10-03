import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';

class ApiDatabaseService {
  static final ApiDatabaseService _instance = ApiDatabaseService._internal();
  static Database? _database;

  ApiDatabaseService._internal();

  factory ApiDatabaseService() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gloria_api_cache.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
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
      ''');

      // Create promotion product list table
      await db.execute('''
        CREATE TABLE promotion_product_list (
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
        CREATE TABLE promotion_bonus_list (
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
        CREATE TABLE promotion_class_list (
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
      await db.execute('CREATE INDEX idx_promotions_active ON promotions(is_active)');
      await db.execute('CREATE INDEX idx_promotions_date_range ON promotions(date_start, date_end)');
      await db.execute('CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)');
      await db.execute('CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)');
      await db.execute('CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)');
    } else if (oldVersion < 4) {
      // Migrate from old promotion_products table to separate tables
      // First, create the new tables
      await db.execute('''
        CREATE TABLE promotion_product_list (
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
        CREATE TABLE promotion_bonus_list (
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
        CREATE TABLE promotion_class_list (
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
        final table = product['product_type'] == 'product' ? 'promotion_product_list' : 'promotion_bonus_list';
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
      await db.execute('CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)');
      await db.execute('CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)');
      await db.execute('CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)');
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

    // Create clients table with new fields
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
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
        code_region TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
        UNIQUE(product_code, price_type_code)
      )
    ''');

    // Create promotions table
    await db.execute('''
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
    ''');

    // Create promotion product list table
    await db.execute('''
      CREATE TABLE promotion_product_list (
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
      CREATE TABLE promotion_bonus_list (
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
      CREATE TABLE promotion_class_list (
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
    await db.execute('CREATE INDEX idx_promotions_active ON promotions(is_active)');
    await db.execute('CREATE INDEX idx_promotions_date_range ON promotions(date_start, date_end)');
    await db.execute('CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code)');
    await db.execute('CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code)');
    await db.execute('CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code)');

    print('API cache database tables created successfully');
  }

  // KPI Data methods
  Future<void> saveKpiData(String userCode, KpiData kpiData) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.delete('kpi_data', where: 'user_code = ?', whereArgs: [userCode]);

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
  }

  Future<KpiData?> getKpiData(String userCode) async {
    final db = await database;
    final result = await db.query(
      'kpi_data',
      where: 'user_code = ?',
      whereArgs: [userCode],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    print(result.isEmpty);
    if (result.isEmpty) return null;

    final row = result.first;
    print('KPI data row: $row');
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

  Future<List<TradingPoint>> getClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'name ASC');

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
            latitude: (row['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 0.0,
            region: row['region'] as String? ?? '',
            district: row['district'] as String? ?? '',
            signboard: row['signboard'] as String? ?? '',
            referencePoint: row['reference_point'] as String? ?? '',
            responsiblePerson: row['responsible_person'] as String? ?? '',
            responsiblePersonPhone:
                row['responsible_person_phone'] as String? ?? '',
            tradePointType: row['trade_point_type'] as String? ?? '',
            creditLimit: (row['credit_limit'] as num?)?.toDouble() ?? 0.0,
            accumulatedCredit:
                (row['accumulated_credit'] as num?)?.toDouble() ?? 0.0,
            codeRegion: row['code_region'] as String? ?? '',
          ),
        )
        .toList();
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

  // Price types methods
  Future<void> savePriceTypes(List<PriceType> priceTypes) async {
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

  // Product prices methods
  Future<void> saveProductPrices(List<ProductPrice> productPrices) async {
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
    print('[$timestamp] DEBUG DB: savePromotions called with ${promotions.length} promotions');

    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use batch operations for much better performance
    final batch = db.batch();

    // Delete all existing promotions and their products
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

    print('[$timestamp] DEBUG DB: After deduplication: ${uniquePromotions.length} unique promotions');

    // Add all inserts to batch
    for (final promotion in uniquePromotions.values) {
      print('[$timestamp] DEBUG DB: Inserting promotion ${promotion.code}: ${promotion.name}');
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

      print('[$timestamp] DEBUG DB: Promotion ${promotion.code} has ${uniqueProductList.length} unique products, ${uniqueBonusList.length} unique bonuses, and ${uniqueClassList.length} unique classes');
    }

    // Execute batch operation
    print('[$timestamp] DEBUG DB: Committing batch');
    await batch.commit(noResult: true);
    print('[$timestamp] DEBUG DB: Batch committed successfully');
  }

  Future<List<PromotionModel>> getPromotions({
    bool onlyActive = true,
    String? searchQuery,
    DateTime? dateFilter,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] DEBUG DB: getPromotions called, onlyActive: $onlyActive, searchQuery: $searchQuery, dateFilter: $dateFilter');

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

    print('[$timestamp] DEBUG DB: Query: SELECT * FROM promotions $whereClause with args: $whereArgs');

    final promotionResults = await db.rawQuery('''
      SELECT * FROM promotions
      $whereClause
      ORDER BY date_start DESC, name ASC
    ''', whereArgs);

    print('[$timestamp] DEBUG DB: Found ${promotionResults.length} promotion records');

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

      print('[$timestamp] DEBUG DB: Promotion $promotionCode has ${productResults.length} products, ${bonusResults.length} bonuses, ${classResults.length} classes');

      final productList = productResults.map((row) => PromotionProduct(
        code: row['product_code'] as String,
        productName: row['product_name'] as String,
      )).toList();

      final bonusList = bonusResults.map((row) => PromotionProduct(
        code: row['product_code'] as String,
        productName: row['product_name'] as String,
      )).toList();

      final classList = classResults.map((row) => PromotionProduct(
        code: row['class_code'] as String,
        productName: row['class_name'] as String,
      )).toList();

      promotions.add(PromotionModel(
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
      ));
    }

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

    final productList = productResults.map((row) => PromotionProduct(
      code: row['product_code'] as String,
      productName: row['product_name'] as String,
    )).toList();

    final bonusList = bonusResults.map((row) => PromotionProduct(
      code: row['product_code'] as String,
      productName: row['product_name'] as String,
    )).toList();

    final classList = classResults.map((row) => PromotionProduct(
      code: row['class_code'] as String,
      productName: row['class_name'] as String,
    )).toList();

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

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('kpi_data');
    await db.delete('clients');
    await db.delete('products');
    await db.delete('price_types');
    await db.delete('product_prices');
    await db.delete('promotion_product_list');
    await db.delete('promotion_bonus_list');
    await db.delete('promotion_class_list');
    await db.delete('promotions');
  }
}
