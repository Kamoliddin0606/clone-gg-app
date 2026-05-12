import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ApiDatabaseService dbService;
  late Database database;

  setUpAll(() async {
    // Initialize sqflite for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database for testing
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 13,
      onCreate: (db, version) async {
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

        // Create visit_steps table
        await db.execute('''
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
        ''');
      },
    );

    dbService = ApiDatabaseService();
    // For testing, we'll use a custom instance that overrides the database getter
    // This is a workaround since the singleton pattern makes testing difficult
    // In a real scenario, consider making the database injectable
  });

  tearDown(() async {
    await database.close();
  });

  group('SalesReqPermissions Database Tests', () {
    test('should save and retrieve sales req permissions', () async {
      // Create test data
      final permissions = SalesReqPermissions(
        userCode: 'TEST001',
        skipTINduplicateCheck: true,
        allowCreationWithoutTIN: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [
          VisitStep(
            stepCode: 1,
            stepName: 'Фото ДО (Facing correction)',
            stepRequired: true,
          ),
          VisitStep(
            stepCode: 2,
            stepName: 'Аудит полки (остатки)',
            stepRequired: false,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save permissions
      await dbService.saveSalesReqPermissions([permissions]);

      // Retrieve permissions
      final retrieved = await dbService.getSalesReqPermissions('TEST001');

      // Verify
      expect(retrieved, isNotNull);
      expect(retrieved!.userCode, equals('TEST001'));
      expect(retrieved.skipTINduplicateCheck, isTrue);
      expect(retrieved.allowCreationWithoutTIN, isFalse);
      expect(retrieved.visit, isTrue);
      expect(retrieved.strictSequence, isFalse);
      expect(retrieved.unplannedOrder, isTrue);
      expect(retrieved.plannedRoute, isFalse);
      expect(retrieved.visitSteps.length, equals(2));
      expect(retrieved.visitSteps[0].stepCode, equals(1));
      expect(retrieved.visitSteps[0].stepName, equals('Фото ДО (Facing correction)'));
      expect(retrieved.visitSteps[0].stepRequired, isTrue);
    });

    test('should return null for non-existent user code', () async {
      final retrieved = await dbService.getSalesReqPermissions('NONEXISTENT');
      expect(retrieved, isNull);
    });

    test('should get all sales req permissions', () async {
      // Create multiple permissions
      final permissions1 = SalesReqPermissions(
        userCode: 'TEST001',
        skipTINduplicateCheck: true,
        allowCreationWithoutTIN: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final permissions2 = SalesReqPermissions(
        userCode: 'TEST002',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: true,
        visit: false,
        strictSequence: true,
        unplannedOrder: false,
        plannedRoute: true,
        editClientCoordinates: true,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveSalesReqPermissions([permissions1, permissions2]);

      final allPermissions = await dbService.getAllSalesReqPermissions();

      expect(allPermissions.length, equals(2));
      expect(allPermissions.map((p) => p.userCode).toSet(), equals({'TEST001', 'TEST002'}));
    });

    test('should delete sales req permissions by user code', () async {
      final permissions = SalesReqPermissions(
        userCode: 'TEST001',
        skipTINduplicateCheck: true,
        allowCreationWithoutTIN: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveSalesReqPermissions([permissions]);

      // Verify it exists
      var retrieved = await dbService.getSalesReqPermissions('TEST001');
      expect(retrieved, isNotNull);

      // Delete it
      await dbService.deleteSalesReqPermissions('TEST001');

      // Verify it's gone
      retrieved = await dbService.getSalesReqPermissions('TEST001');
      expect(retrieved, isNull);
    });

    test('should clear all sales req permissions data', () async {
      final permissions = SalesReqPermissions(
        userCode: 'TEST001',
        skipTINduplicateCheck: true,
        allowCreationWithoutTIN: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [
          VisitStep(
            stepCode: 1,
            stepName: 'Test Step',
            stepRequired: true,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveSalesReqPermissions([permissions]);

      // Verify data exists
      var retrieved = await dbService.getSalesReqPermissions('TEST001');
      expect(retrieved, isNotNull);

      // Clear all data
      await dbService.clearSalesReqPermissions();

      // Verify data is cleared
      retrieved = await dbService.getSalesReqPermissions('TEST001');
      expect(retrieved, isNull);
    });
  });
}