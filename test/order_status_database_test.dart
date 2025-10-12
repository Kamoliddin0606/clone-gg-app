import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';

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
      CREATE TABLE IF NOT EXISTS order_statuses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_order_statuses_message ON order_statuses(message)');
  });

  tearDown(() async {
    // Don't close the database to avoid issues with subsequent tests
  });

  group('OrderStatus Database Tests', () {
    test('saveOrderStatuses and getOrderStatuses work correctly', () async {
      // Create test data
      final statuses = [
        OrderStatus(message: 'Новый'),
        OrderStatus(message: 'Доставлено и оплачено'),
        OrderStatus(message: 'В обработке'),
      ];

      // Save statuses
      await dbService.saveOrderStatuses(statuses);

      // Retrieve statuses
      final retrievedStatuses = await dbService.getOrderStatuses();

      // Verify
      expect(retrievedStatuses.length, 3);
      expect(retrievedStatuses.map((s) => s.message).toSet(),
          {'Новый', 'Доставлено и оплачено', 'В обработке'});
    });

    test('getOrderStatusByMessage returns correct status', () async {
      // Save test data
      final status = OrderStatus(message: 'Доставлено и ожидает оплаты');
      await dbService.saveOrderStatuses([status]);

      // Retrieve by message
      final retrieved = await dbService.getOrderStatusByMessage('Доставлено и ожидает оплаты');

      // Verify
      expect(retrieved, isNotNull);
      expect(retrieved!.message, 'Доставлено и ожидает оплаты');
    });

    test('getOrderStatusByMessage returns null for non-existent message', () async {
      final retrieved = await dbService.getOrderStatusByMessage('Non-existent status');

      expect(retrieved, isNull);
    });

    test('saveOrderStatuses handles duplicates correctly', () async {
      // Save initial data
      final initialStatuses = [
        OrderStatus(message: 'Новый'),
        OrderStatus(message: 'Доставлено и оплачено'),
      ];
      await dbService.saveOrderStatuses(initialStatuses);

      // Save data with duplicates (this replaces all existing data)
      final duplicateStatuses = [
        OrderStatus(message: 'Новый'), // Duplicate
        OrderStatus(message: 'В обработке'), // New
      ];
      await dbService.saveOrderStatuses(duplicateStatuses);

      // Retrieve all
      final allStatuses = await dbService.getOrderStatuses();

      // Should have 2 statuses (the save operation replaces all data)
      expect(allStatuses.length, 2);
      expect(allStatuses.map((s) => s.message).toSet(),
          {'Новый', 'В обработке'});
    });
  });
}