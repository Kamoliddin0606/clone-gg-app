import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ApiDatabaseService dbService;
  late Database database;

  setUp(() async {
    // Create in-memory database for testing
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 15,
      onCreate: (db, version) async {
        // Create tables manually for testing
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
      },
    );

    dbService = ApiDatabaseService(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('CreateOrder CRUD Operations', () {
    test('should save and retrieve create order with all related data', () async {
      // Create test data
      final now = DateTime.now();
      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'Cash',
        shippingDate: now.add(const Duration(days: 1)),
        commentSupervisor: 'Supervisor comment',
        commentForwarder: 'Forwarder comment',
        comment: 'General comment',
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 100.0,
        capacity: 50.0,
        credit: true,
        codeProject: 'PROJECT001',
        orderType: 1,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: 'CONTRACT001',
        hasPromo: true,
        products: [
          CreateOrderProduct(
            codeSklad: 'SKLAD001',
            codeProduct: 'PROD001',
            amount: 10,
            price: 100.0,
            total: 1000.0,
            weight: 10.0,
            capacity: 5.0,
            paymentType: 1,
            discountSum: 50.0,
            discountRate: 5.0,
            giftAmount: 2,
            promo: true,
          ),
        ],
        competitiveIntelligence: [
          CompetitiveIntelligence(
            competitor: 'COMP001',
            product: 'PROD001',
            price: 95.0,
          ),
        ],
        creditDetails: [
          CreditDetail(
            dateOfPayment: now.add(const Duration(days: 30)),
            total: 500.0,
          ),
        ],
      );

      // Save order
      await dbService.saveCreateOrder(order);

      // Retrieve orders
      final orders = await dbService.getCreateOrders('AGENT001');

      expect(orders.length, 1);
      final retrievedOrder = orders.first;

      expect(retrievedOrder.codeAgent, 'AGENT001');
      expect(retrievedOrder.codeClient, 'CLIENT001');
      expect(retrievedOrder.products.length, 1);
      expect(retrievedOrder.competitiveIntelligence.length, 1);
      expect(retrievedOrder.creditDetails.length, 1);

      // Verify product data
      final product = retrievedOrder.products.first;
      expect(product.codeProduct, 'PROD001');
      expect(product.amount, 10);
      expect(product.price, 100.0);

      // Verify competitive intelligence
      final ci = retrievedOrder.competitiveIntelligence.first;
      expect(ci.competitor, 'COMP001');
      expect(ci.price, 95.0);

      // Verify credit details
      final cd = retrievedOrder.creditDetails.first;
      expect(cd.total, 500.0);
    });

    test('should get unsynced create orders', () async {
      // Create and save two orders - one synced, one not
      final now = DateTime.now();
      final syncedOrder = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'Cash',
        shippingDate: now.add(const Duration(days: 1)),
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 100.0,
        capacity: 50.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 1,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        hasPromo: false,
        isSynced: true, // Already synced
      );

      final unsyncedOrder = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT002',
        codePrice: 'PRICE001',
        payment: 'Card',
        shippingDate: now.add(const Duration(days: 2)),
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 200.0,
        capacity: 100.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 1,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        hasPromo: false,
        isSynced: false, // Not synced
      );

      await dbService.saveCreateOrder(syncedOrder);
      await dbService.saveCreateOrder(unsyncedOrder);

      // Get unsynced orders
      final unsyncedOrders = await dbService.getUnsyncedCreateOrders();

      expect(unsyncedOrders.length, 1);
      expect(unsyncedOrders.first.codeClient, 'CLIENT002');
    });

    test('should update create order sync status', () async {
      // Create and save order
      final now = DateTime.now();
      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'Cash',
        shippingDate: now.add(const Duration(days: 1)),
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 100.0,
        capacity: 50.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 1,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        hasPromo: false,
      );

      await dbService.saveCreateOrder(order);

      // Get the saved order ID
      final orders = await dbService.getCreateOrders('AGENT001');
      final orderId = orders.first.id!;

      // Update sync status
      await dbService.updateCreateOrderSyncStatus(orderId, true, syncError: 'Test error');

      // Verify sync status
      final updatedOrders = await dbService.getCreateOrders('AGENT001');
      expect(updatedOrders.first.isSynced, true);
      expect(updatedOrders.first.syncError, 'Test error');
      expect(updatedOrders.first.syncedAt, isNotNull);
    });

    test('should delete create order and related data', () async {
      // Create and save order with related data
      final now = DateTime.now();
      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'Cash',
        shippingDate: now.add(const Duration(days: 1)),
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 100.0,
        capacity: 50.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 1,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        hasPromo: false,
        products: [
          CreateOrderProduct(
            codeSklad: 'SKLAD001',
            codeProduct: 'PROD001',
            amount: 5,
            price: 50.0,
            total: 250.0,
            weight: 5.0,
            capacity: 2.5,
            paymentType: 1,
          ),
        ],
      );

      await dbService.saveCreateOrder(order);

      // Get the saved order ID
      final orders = await dbService.getCreateOrders('AGENT001');
      final orderId = orders.first.id!;

      // Delete order
      await dbService.deleteCreateOrder(orderId);

      // Verify deletion
      final remainingOrders = await dbService.getCreateOrders('AGENT001');
      expect(remainingOrders.length, 0);
    });

    test('should clear all create order data', () async {
      // Create and save multiple orders
      final now = DateTime.now();
      final order1 = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'Cash',
        shippingDate: now.add(const Duration(days: 1)),
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 100.0,
        capacity: 50.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 1,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        hasPromo: false,
      );

      final order2 = CreateOrder(
        codeAgent: 'AGENT002',
        codeClient: 'CLIENT002',
        codePrice: 'PRICE002',
        payment: 'Card',
        shippingDate: now.add(const Duration(days: 2)),
        createDate: now,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 200.0,
        capacity: 100.0,
        credit: false,
        codeProject: 'PROJECT002',
        orderType: 2,
        codeOrg: 'ORG002',
        codeSklad: 'SKLAD002',
        hasPromo: false,
      );

      await dbService.saveCreateOrder(order1);
      await dbService.saveCreateOrder(order2);

      // Verify orders exist
      final allOrders = await dbService.getCreateOrders('');
      expect(allOrders.length, 2);

      // Clear all data
      await dbService.clearCreateOrderData();

      // Verify all data is cleared
      final remainingOrders = await dbService.getCreateOrders('');
      expect(remainingOrders.length, 0);
    });
  });
}