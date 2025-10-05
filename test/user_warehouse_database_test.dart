import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ApiDatabaseService dbService;

  setUp(() async {
    dbService = ApiDatabaseService();
    // Clear all data before each test
    await dbService.clearAllData();
  });

  tearDown(() async {
    // Clean up after each test
    await dbService.clearAllData();
  });

  group('UserWarehouse Database Operations', () {
    test('saveUserWarehouses should save multiple warehouses', () async {
      final warehouses = [
        UserWarehouse(code: 'WH001', name: 'Warehouse 1', organization: 'Org1'),
        UserWarehouse(code: 'WH002', name: 'Warehouse 2', organization: 'Org2'),
        UserWarehouse(code: 'WH003', name: 'Warehouse 3', organization: 'Org3'),
      ];

      await dbService.saveUserWarehouses(warehouses);

      final savedWarehouses = await dbService.getUserWarehouses();
      expect(savedWarehouses.length, 3);
      expect(savedWarehouses.map((w) => w.code), containsAll(['WH001', 'WH002', 'WH003']));
      expect(savedWarehouses.map((w) => w.name), containsAll(['Warehouse 1', 'Warehouse 2', 'Warehouse 3']));
      expect(savedWarehouses.map((w) => w.organization), containsAll(['Org1', 'Org2', 'Org3']));
    });

    test('getUserWarehouses should return all warehouses ordered by name', () async {
      final warehouses = [
        UserWarehouse(code: 'WH003', name: 'C Warehouse', organization: 'Org3'),
        UserWarehouse(code: 'WH001', name: 'A Warehouse', organization: 'Org1'),
        UserWarehouse(code: 'WH002', name: 'B Warehouse', organization: 'Org2'),
      ];

      await dbService.saveUserWarehouses(warehouses);

      final savedWarehouses = await dbService.getUserWarehouses();
      expect(savedWarehouses.length, 3);
      expect(savedWarehouses[0].name, 'A Warehouse');
      expect(savedWarehouses[1].name, 'B Warehouse');
      expect(savedWarehouses[2].name, 'C Warehouse');
    });

    test('getUserWarehouseByCode should return correct warehouse', () async {
      final warehouse = UserWarehouse(code: 'WH001', name: 'Test Warehouse', organization: 'Test Org');
      await dbService.saveUserWarehouse(warehouse);

      final retrieved = await dbService.getUserWarehouseByCode('WH001');
      expect(retrieved, isNotNull);
      expect(retrieved!.code, 'WH001');
      expect(retrieved.name, 'Test Warehouse');
      expect(retrieved.organization, 'Test Org');
    });

    test('getUserWarehouseByCode should return null for non-existent code', () async {
      final retrieved = await dbService.getUserWarehouseByCode('NONEXISTENT');
      expect(retrieved, isNull);
    });

    test('saveUserWarehouse should save single warehouse', () async {
      final warehouse = UserWarehouse(code: 'WH001', name: 'Test Warehouse', organization: 'Test Org');

      await dbService.saveUserWarehouse(warehouse);

      final retrieved = await dbService.getUserWarehouseByCode('WH001');
      expect(retrieved, isNotNull);
      expect(retrieved!.code, 'WH001');
      expect(retrieved.name, 'Test Warehouse');
      expect(retrieved.organization, 'Test Org');
    });

    test('saveUserWarehouse should replace existing warehouse with same code', () async {
      final warehouse1 = UserWarehouse(code: 'WH001', name: 'Original Name', organization: 'Org1');
      final warehouse2 = UserWarehouse(code: 'WH001', name: 'Updated Name', organization: 'Org2');

      await dbService.saveUserWarehouse(warehouse1);
      await dbService.saveUserWarehouse(warehouse2);

      final retrieved = await dbService.getUserWarehouseByCode('WH001');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Updated Name');
      expect(retrieved.organization, 'Org2');
    });

    test('updateUserWarehouse should update existing warehouse', () async {
      final original = UserWarehouse(code: 'WH001', name: 'Original Name', organization: 'Org1');
      await dbService.saveUserWarehouse(original);

      final updated = UserWarehouse(code: 'WH001', name: 'Updated Name', organization: 'Org2');
      await dbService.updateUserWarehouse('WH001', updated);

      final retrieved = await dbService.getUserWarehouseByCode('WH001');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Updated Name');
      expect(retrieved.organization, 'Org2');
    });

    test('deleteUserWarehouse should remove warehouse', () async {
      final warehouse = UserWarehouse(code: 'WH001', name: 'Test Warehouse', organization: 'Test Org');
      await dbService.saveUserWarehouse(warehouse);

      // Verify it exists
      var retrieved = await dbService.getUserWarehouseByCode('WH001');
      expect(retrieved, isNotNull);

      // Delete it
      await dbService.deleteUserWarehouse('WH001');

      // Verify it's gone
      retrieved = await dbService.getUserWarehouseByCode('WH001');
      expect(retrieved, isNull);
    });

    test('UserWarehouse model fromMap and toMap should be reversible', () {
      final original = UserWarehouse(
        code: 'WH001',
        name: 'Test Warehouse',
        organization: 'Test Org',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = original.toMap();
      final restored = UserWarehouse.fromMap(map);

      expect(restored.code, original.code);
      expect(restored.name, original.name);
      expect(restored.organization, original.organization);
      expect(restored.createdAt?.toIso8601String(), original.createdAt?.toIso8601String());
      expect(restored.updatedAt?.toIso8601String(), original.updatedAt?.toIso8601String());
    });

    test('UserWarehouse copyWith should work correctly', () {
      final original = UserWarehouse(
        code: 'WH001',
        name: 'Original Name',
        organization: 'Org1',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      final copied = original.copyWith(name: 'New Name', organization: 'Org2', updatedAt: DateTime(2023, 1, 2));

      expect(copied.code, 'WH001');
      expect(copied.name, 'New Name');
      expect(copied.organization, 'Org2');
      expect(copied.createdAt, DateTime(2023, 1, 1));
      expect(copied.updatedAt, DateTime(2023, 1, 2));
    });

    test('UserWarehouse equality should be based on code', () {
      final warehouse1 = UserWarehouse(code: 'WH001', name: 'Name 1', organization: 'Org1');
      final warehouse2 = UserWarehouse(code: 'WH001', name: 'Name 2', organization: 'Org2');
      final warehouse3 = UserWarehouse(code: 'WH002', name: 'Name 1', organization: 'Org1');

      expect(warehouse1 == warehouse2, true);
      expect(warehouse1 == warehouse3, false);
    });
  });
}