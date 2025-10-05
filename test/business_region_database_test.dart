import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';

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

  group('BusinessRegion Database Operations', () {
    test('saveBusinessRegions should save multiple regions', () async {
      final regions = [
        BusinessRegion(code: 'REG001', name: 'Region 1'),
        BusinessRegion(code: 'REG002', name: 'Region 2'),
        BusinessRegion(code: 'REG003', name: 'Region 3'),
      ];

      await dbService.saveBusinessRegions(regions);

      final savedRegions = await dbService.getBusinessRegions();
      expect(savedRegions.length, 3);
      expect(savedRegions.map((r) => r.code), containsAll(['REG001', 'REG002', 'REG003']));
      expect(savedRegions.map((r) => r.name), containsAll(['Region 1', 'Region 2', 'Region 3']));
    });

    test('getBusinessRegions should return all regions ordered by name', () async {
      final regions = [
        BusinessRegion(code: 'REG003', name: 'C Region'),
        BusinessRegion(code: 'REG001', name: 'A Region'),
        BusinessRegion(code: 'REG002', name: 'B Region'),
      ];

      await dbService.saveBusinessRegions(regions);

      final savedRegions = await dbService.getBusinessRegions();
      expect(savedRegions.length, 3);
      expect(savedRegions[0].name, 'A Region');
      expect(savedRegions[1].name, 'B Region');
      expect(savedRegions[2].name, 'C Region');
    });

    test('getBusinessRegionByCode should return correct region', () async {
      final region = BusinessRegion(code: 'REG001', name: 'Test Region');
      await dbService.saveBusinessRegion(region);

      final retrieved = await dbService.getBusinessRegionByCode('REG001');
      expect(retrieved, isNotNull);
      expect(retrieved!.code, 'REG001');
      expect(retrieved.name, 'Test Region');
    });

    test('getBusinessRegionByCode should return null for non-existent code', () async {
      final retrieved = await dbService.getBusinessRegionByCode('NONEXISTENT');
      expect(retrieved, isNull);
    });

    test('saveBusinessRegion should save single region', () async {
      final region = BusinessRegion(code: 'REG001', name: 'Test Region');

      await dbService.saveBusinessRegion(region);

      final retrieved = await dbService.getBusinessRegionByCode('REG001');
      expect(retrieved, isNotNull);
      expect(retrieved!.code, 'REG001');
      expect(retrieved.name, 'Test Region');
    });

    test('saveBusinessRegion should replace existing region with same code', () async {
      final region1 = BusinessRegion(code: 'REG001', name: 'Original Name');
      final region2 = BusinessRegion(code: 'REG001', name: 'Updated Name');

      await dbService.saveBusinessRegion(region1);
      await dbService.saveBusinessRegion(region2);

      final retrieved = await dbService.getBusinessRegionByCode('REG001');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Updated Name');
    });

    test('updateBusinessRegion should update existing region', () async {
      final original = BusinessRegion(code: 'REG001', name: 'Original Name');
      await dbService.saveBusinessRegion(original);

      final updated = BusinessRegion(code: 'REG001', name: 'Updated Name');
      await dbService.updateBusinessRegion('REG001', updated);

      final retrieved = await dbService.getBusinessRegionByCode('REG001');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Updated Name');
    });

    test('deleteBusinessRegion should remove region', () async {
      final region = BusinessRegion(code: 'REG001', name: 'Test Region');
      await dbService.saveBusinessRegion(region);

      // Verify it exists
      var retrieved = await dbService.getBusinessRegionByCode('REG001');
      expect(retrieved, isNotNull);

      // Delete it
      await dbService.deleteBusinessRegion('REG001');

      // Verify it's gone
      retrieved = await dbService.getBusinessRegionByCode('REG001');
      expect(retrieved, isNull);
    });

    test('BusinessRegion model fromMap and toMap should be reversible', () {
      final original = BusinessRegion(
        code: 'REG001',
        name: 'Test Region',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = original.toMap();
      final restored = BusinessRegion.fromMap(map);

      expect(restored.code, original.code);
      expect(restored.name, original.name);
      expect(restored.createdAt?.toIso8601String(), original.createdAt?.toIso8601String());
      expect(restored.updatedAt?.toIso8601String(), original.updatedAt?.toIso8601String());
    });

    test('BusinessRegion copyWith should work correctly', () {
      final original = BusinessRegion(
        code: 'REG001',
        name: 'Original Name',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      final copied = original.copyWith(name: 'New Name', updatedAt: DateTime(2023, 1, 2));

      expect(copied.code, 'REG001');
      expect(copied.name, 'New Name');
      expect(copied.createdAt, DateTime(2023, 1, 1));
      expect(copied.updatedAt, DateTime(2023, 1, 2));
    });

    test('BusinessRegion equality should be based on code', () {
      final region1 = BusinessRegion(code: 'REG001', name: 'Name 1');
      final region2 = BusinessRegion(code: 'REG001', name: 'Name 2');
      final region3 = BusinessRegion(code: 'REG002', name: 'Name 1');

      expect(region1 == region2, true);
      expect(region1 == region3, false);
    });
  });
}