import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ApiDatabaseService dbService;

  setUp(() async {
    dbService = ApiDatabaseService();
    final db = await dbService.database;
    // Create tables for testing
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_num_order ON orders(num_order)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_client_code ON orders(client_code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_type_price_code ON orders(type_price_code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_main_status ON orders(main_status)');
  });

  tearDown(() async {
    // Don't close the database to avoid issues with subsequent tests
  });

  group('Order Database Tests', () {
    test('saveOrders and getOrders work correctly', () async {
      // Create test data
      final orders = [
        Order(
          numOrder: 'GL00-154855',
          dateOrder: DateTime.parse('2025-10-01T10:52:10'),
          captionOrder: 'Заказ клиента GL00-154855 от 01.10.2025 10:52:10',
          typePriceCode: 'Цена PS опт',
          status: 2,
          total: 785200.0,
          clientCode: '00-00054499',
          clientName: 'OVAYXON OOO',
          codeOrg: '00000000001',
          mainStatus: 'Доставлено и ожидает оплаты',
        ),
        Order(
          numOrder: 'GL00-155031',
          dateOrder: DateTime.parse('2025-10-01T13:52:44'),
          captionOrder: 'Заказ клиента GL00-155031 от 01.10.2025 13:52:44',
          typePriceCode: 'Цена PS опт',
          status: 2,
          total: 973520.0,
          clientCode: '00-00051388',
          clientName: 'FRUTTI OOO',
          codeOrg: '00000000001',
          mainStatus: 'Доставлено и ожидает оплаты',
        ),
      ];

      // Save orders
      await dbService.saveOrders(orders);

      // Retrieve all orders
      final retrievedOrders = await dbService.getOrders();

      // Verify
      expect(retrievedOrders.length, 2);
      expect(retrievedOrders.map((o) => o.numOrder).toSet(),
          {'GL00-154855', 'GL00-155031'});
    });

    test('getOrders with filters work correctly', () async {
      // Save test data
      final orders = [
        Order(
          numOrder: 'GL00-154855',
          dateOrder: DateTime.parse('2025-10-01T10:52:10'),
          captionOrder: 'Заказ клиента GL00-154855 от 01.10.2025 10:52:10',
          typePriceCode: 'Цена PS опт',
          status: 2,
          total: 785200.0,
          clientCode: '00-00054499',
          clientName: 'OVAYXON OOO',
          codeOrg: '00000000001',
          mainStatus: 'Доставлено и ожидает оплаты',
        ),
        Order(
          numOrder: 'GL00-155031',
          dateOrder: DateTime.parse('2025-10-01T13:52:44'),
          captionOrder: 'Заказ клиента GL00-155031 от 01.10.2025 13:52:44',
          typePriceCode: 'Цена PS розница',
          status: 2,
          total: 973520.0,
          clientCode: '00-00051388',
          clientName: 'FRUTTI OOO',
          codeOrg: '00000000001',
          mainStatus: 'Доставлено и оплачено',
        ),
      ];
      await dbService.saveOrders(orders);

      // Test filtering by client code
      final clientOrders = await dbService.getOrders(clientCode: '00-00054499');
      expect(clientOrders.length, 1);
      expect(clientOrders.first.numOrder, 'GL00-154855');

      // Test filtering by main status
      final statusOrders = await dbService.getOrders(mainStatus: 'Доставлено и оплачено');
      expect(statusOrders.length, 1);
      expect(statusOrders.first.numOrder, 'GL00-155031');

      // Test filtering by type price code
      final priceOrders = await dbService.getOrders(typePriceCode: 'Цена PS опт');
      expect(priceOrders.length, 1);
      expect(priceOrders.first.numOrder, 'GL00-154855');
    });

    test('getOrderByNumOrder returns correct order', () async {
      // Save test data
      final order = Order(
        numOrder: 'GL00-154855',
        dateOrder: DateTime.parse('2025-10-01T10:52:10'),
        captionOrder: 'Test order',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );
      await dbService.saveOrders([order]);

      // Retrieve by num order
      final retrieved = await dbService.getOrderByNumOrder('GL00-154855');

      // Verify
      expect(retrieved, isNotNull);
      expect(retrieved!.numOrder, 'GL00-154855');
      expect(retrieved.total, 785200.0);
    });

    test('updateOrderStatus works correctly', () async {
      // Save test data
      final order = Order(
        numOrder: 'GL00-154855',
        dateOrder: DateTime.parse('2025-10-01T10:52:10'),
        captionOrder: 'Test order',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );
      await dbService.saveOrders([order]);

      // Update status
      await dbService.updateOrderStatus('GL00-154855', 'Доставлено и оплачено');

      // Retrieve and verify
      final updated = await dbService.getOrderByNumOrder('GL00-154855');
      expect(updated!.mainStatus, 'Доставлено и оплачено');
    });

    test('deleteOrder works correctly', () async {
      // Save test data
      final order = Order(
        numOrder: 'GL00-154855',
        dateOrder: DateTime.parse('2025-10-01T10:52:10'),
        captionOrder: 'Test order',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );
      await dbService.saveOrders([order]);

      // Delete order
      await dbService.deleteOrder('GL00-154855');

      // Verify deletion
      final retrieved = await dbService.getOrderByNumOrder('GL00-154855');
      expect(retrieved, isNull);
    });
  });
}