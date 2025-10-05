import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_brand.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_series.dart';
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

  group('ProductBalance Database Operations', () {
    test('saveProductBalances should save multiple balances', () async {
      // First create a warehouse
      final warehouse = UserWarehouse(code: 'WH001', name: 'Test Warehouse', organization: 'Test Org');
      await dbService.saveUserWarehouse(warehouse);

      final balances = [
        ProductBalance(
          codeSklad: 'WH001',
          codeProduct: 'P001',
          nameProduct: 'Product 1',
          have: 100,
          reserved: 10,
          available: 90,
          weight: 1.5,
          capacity: 2.0,
          codeProject: 'PRJ001',
          vendorCode: 'V001',
          productBrand: 'Brand1',
          productSeries: 'Series1',
        ),
        ProductBalance(
          codeSklad: 'WH001',
          codeProduct: 'P002',
          nameProduct: 'Product 2',
          have: 200,
          reserved: 20,
          available: 180,
          weight: 2.5,
          capacity: 3.0,
          codeProject: 'PRJ001',
          vendorCode: 'V002',
          productBrand: 'Brand1',
          productSeries: 'Series2',
        ),
      ];

      await dbService.saveProductBalances(balances);

      final savedBalances = await dbService.getProductBalances();
      expect(savedBalances.length, 2);
      expect(savedBalances.map((b) => b.codeProduct), containsAll(['P001', 'P002']));
    });

    test('getProductBalances should filter by warehouse code', () async {
      // Create warehouses
      final warehouse1 = UserWarehouse(code: 'WH001', name: 'Warehouse 1', organization: 'Org1');
      final warehouse2 = UserWarehouse(code: 'WH002', name: 'Warehouse 2', organization: 'Org2');
      await dbService.saveUserWarehouse(warehouse1);
      await dbService.saveUserWarehouse(warehouse2);

      final balances = [
        ProductBalance(
          codeSklad: 'WH001',
          codeProduct: 'P001',
          nameProduct: 'Product 1',
          have: 100,
          reserved: 10,
          available: 90,
          weight: 1.5,
          capacity: 2.0,
          codeProject: 'PRJ001',
          vendorCode: 'V001',
          productBrand: 'Brand1',
          productSeries: 'Series1',
        ),
        ProductBalance(
          codeSklad: 'WH002',
          codeProduct: 'P002',
          nameProduct: 'Product 2',
          have: 200,
          reserved: 20,
          available: 180,
          weight: 2.5,
          capacity: 3.0,
          codeProject: 'PRJ001',
          vendorCode: 'V002',
          productBrand: 'Brand1',
          productSeries: 'Series2',
        ),
      ];

      await dbService.saveProductBalances(balances);

      final wh1Balances = await dbService.getProductBalances(warehouseCode: 'WH001');
      expect(wh1Balances.length, 1);
      expect(wh1Balances[0].codeProduct, 'P001');

      final wh2Balances = await dbService.getProductBalances(warehouseCode: 'WH002');
      expect(wh2Balances.length, 1);
      expect(wh2Balances[0].codeProduct, 'P002');
    });

    test('getProductBalanceByCodes should return correct balance', () async {
      // Create warehouse
      final warehouse = UserWarehouse(code: 'WH001', name: 'Test Warehouse', organization: 'Test Org');
      await dbService.saveUserWarehouse(warehouse);

      final balance = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Test Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Brand1',
        productSeries: 'Series1',
      );
      await dbService.saveProductBalance(balance);

      final retrieved = await dbService.getProductBalanceByCodes('WH001', 'P001');
      expect(retrieved, isNotNull);
      expect(retrieved!.codeProduct, 'P001');
      expect(retrieved.have, 100);
    });

    test('saveProductBalance should replace existing balance', () async {
      // Create warehouse
      final warehouse = UserWarehouse(code: 'WH001', name: 'Test Warehouse', organization: 'Test Org');
      await dbService.saveUserWarehouse(warehouse);

      final balance1 = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Original Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Brand1',
        productSeries: 'Series1',
      );
      final balance2 = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Updated Product',
        have: 200,
        reserved: 20,
        available: 180,
        weight: 2.5,
        capacity: 3.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Brand1',
        productSeries: 'Series1',
      );

      await dbService.saveProductBalance(balance1);
      await dbService.saveProductBalance(balance2);

      final retrieved = await dbService.getProductBalanceByCodes('WH001', 'P001');
      expect(retrieved, isNotNull);
      expect(retrieved!.nameProduct, 'Updated Product');
      expect(retrieved.have, 200);
    });
  });

  group('ProductBrand Database Operations', () {
    test('saveProductBrands should save multiple brands', () async {
      final brands = [
        ProductBrand(name: 'Brand1'),
        ProductBrand(name: 'Brand2'),
        ProductBrand(name: 'Brand3'),
      ];

      await dbService.saveProductBrands(brands);

      final savedBrands = await dbService.getProductBrands();
      expect(savedBrands.length, 3);
      expect(savedBrands.map((b) => b.name), containsAll(['Brand1', 'Brand2', 'Brand3']));
    });

    test('getProductBrandByName should return correct brand', () async {
      final brand = ProductBrand(name: 'TestBrand');
      await dbService.saveProductBrand(brand);

      final retrieved = await dbService.getProductBrandByName('TestBrand');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'TestBrand');
    });
  });

  group('ProductSeries Database Operations', () {
    test('saveProductSeries should save multiple series', () async {
      // First create brands
      final brands = [
        ProductBrand(name: 'Brand1'),
        ProductBrand(name: 'Brand2'),
      ];
      await dbService.saveProductBrands(brands);

      final series = [
        ProductSeries(name: 'Series1', brandName: 'Brand1'),
        ProductSeries(name: 'Series2', brandName: 'Brand1'),
        ProductSeries(name: 'Series3', brandName: 'Brand2'),
      ];

      await dbService.saveProductSeries(series);

      final savedSeries = await dbService.getProductSeries();
      expect(savedSeries.length, 3);
      expect(savedSeries.map((s) => s.name), containsAll(['Series1', 'Series2', 'Series3']));
    });

    test('getProductSeries should filter by brand name', () async {
      // Create brands
      final brands = [
        ProductBrand(name: 'Brand1'),
        ProductBrand(name: 'Brand2'),
      ];
      await dbService.saveProductBrands(brands);

      final series = [
        ProductSeries(name: 'Series1', brandName: 'Brand1'),
        ProductSeries(name: 'Series2', brandName: 'Brand1'),
        ProductSeries(name: 'Series3', brandName: 'Brand2'),
      ];
      await dbService.saveProductSeries(series);

      final brand1Series = await dbService.getProductSeries(brandName: 'Brand1');
      expect(brand1Series.length, 2);
      expect(brand1Series.map((s) => s.name), containsAll(['Series1', 'Series2']));

      final brand2Series = await dbService.getProductSeries(brandName: 'Brand2');
      expect(brand2Series.length, 1);
      expect(brand2Series[0].name, 'Series3');
    });

    test('getProductSeriesByNameAndBrand should return correct series', () async {
      // Create brand
      final brand = ProductBrand(name: 'TestBrand');
      await dbService.saveProductBrand(brand);

      final series = ProductSeries(name: 'TestSeries', brandName: 'TestBrand');
      await dbService.saveProductSerie(series);

      final retrieved = await dbService.getProductSeriesByNameAndBrand('TestSeries', 'TestBrand');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'TestSeries');
      expect(retrieved.brandName, 'TestBrand');
    });
  });

  group('ProductBalance Model Tests', () {
    test('ProductBalance fromMap and toMap should be reversible', () {
      final original = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Test Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Brand1',
        productSeries: 'Series1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = original.toMap();
      final restored = ProductBalance.fromMap(map);

      expect(restored.codeSklad, original.codeSklad);
      expect(restored.codeProduct, original.codeProduct);
      expect(restored.nameProduct, original.nameProduct);
      expect(restored.have, original.have);
      expect(restored.reserved, original.reserved);
      expect(restored.available, original.available);
      expect(restored.weight, original.weight);
      expect(restored.capacity, original.capacity);
      expect(restored.codeProject, original.codeProject);
      expect(restored.vendorCode, original.vendorCode);
      expect(restored.productBrand, original.productBrand);
      expect(restored.productSeries, original.productSeries);
    });

    test('ProductBalance copyWith should work correctly', () {
      final original = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Original Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Brand1',
        productSeries: 'Series1',
      );

      final copied = original.copyWith(
        nameProduct: 'New Product',
        have: 200,
        weight: 2.5,
      );

      expect(copied.codeSklad, 'WH001');
      expect(copied.nameProduct, 'New Product');
      expect(copied.have, 200);
      expect(copied.weight, 2.5);
      expect(copied.reserved, 10); // unchanged
    });
  });
}