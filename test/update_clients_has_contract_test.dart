import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockSoapApiService extends Mock implements SoapApiService {}
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DataSyncService dataSyncService;
  late MockSharedPreferencesService mockPrefs;
  late MockSoapApiService mockApiService;
  late MockApiDatabaseService mockDbService;
  late MockDatabaseHelper mockDbHelper;
  late Database testDb;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    mockApiService = MockSoapApiService();
    mockDbService = MockApiDatabaseService();
    mockDbHelper = MockDatabaseHelper();

    // Create in-memory database for testing
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    // Create test tables
    await testDb.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        has_contract INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await testDb.execute('''
      CREATE TABLE client_contracts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_contract TEXT UNIQUE NOT NULL,
        code_client TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    dataSyncService = DataSyncService(
      prefs: mockPrefs,
      apiService: mockApiService,
      dbService: mockDbService,
      dbHelper: mockDbHelper,
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('updateClientsHasContractField', () {
    test('should update clients with active contracts correctly', () async {
      // Mock the database getter for this test
      when(mockDbService.database).thenAnswer((_) async => testDb);

      // Insert test data
      await testDb.insert('clients', {
        'code': 'C001',
        'name': 'Client 1',
        'has_contract': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('clients', {
        'code': 'C002',
        'name': 'Client 2',
        'has_contract': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('clients', {
        'code': 'C003',
        'name': 'Client 3',
        'has_contract': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert contracts
      await testDb.insert('client_contracts', {
        'code_contract': 'CT001',
        'code_client': 'C001',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('client_contracts', {
        'code_contract': 'CT002',
        'code_client': 'C002',
        'active': 0, // Inactive contract
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Call the method
      await dataSyncService.updateClientsHasContractField();

      // Verify results
      final clients = await testDb.query('clients', orderBy: 'code');

      expect(clients[0]['code'], 'C001');
      expect(clients[0]['has_contract'], 1); // Should be updated to 1

      expect(clients[1]['code'], 'C002');
      expect(clients[1]['has_contract'], 0); // Should remain 0 (inactive contract)

      expect(clients[2]['code'], 'C003');
      expect(clients[2]['has_contract'], 0); // Should be updated to 0 (no active contract)
    });

    test('should handle empty contract list', () async {
      // Mock the database getter for this test
      when(mockDbService.database).thenAnswer((_) async => testDb);

      // Insert test client
      await testDb.insert('clients', {
        'code': 'C001',
        'name': 'Client 1',
        'has_contract': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Call the method (no contracts in database)
      await dataSyncService.updateClientsHasContractField();

      // Verify client has_contract is set to 0
      final clients = await testDb.query('clients');
      expect(clients[0]['has_contract'], 0);
    });

    test('should handle database errors gracefully', () async {
      // Mock database to throw error
      when(mockDbService.database).thenThrow(Exception('Database error'));

      // Method should not throw, just log error
      await expectLater(
        dataSyncService.updateClientsHasContractField(),
        completes,
      );
    });

    test('should only update clients that need changes', () async {
      // Mock the database getter for this test
      when(mockDbService.database).thenAnswer((_) async => testDb);

      // Insert test data
      await testDb.insert('clients', {
        'code': 'C001',
        'name': 'Client 1',
        'has_contract': 1, // Already correct
        'updated_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('clients', {
        'code': 'C002',
        'name': 'Client 2',
        'has_contract': 0, // Needs update
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert contract for C001
      await testDb.insert('client_contracts', {
        'code_contract': 'CT001',
        'code_client': 'C001',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Call the method
      await dataSyncService.updateClientsHasContractField();

      // Verify only C002 was updated
      final clients = await testDb.query('clients', orderBy: 'code');
      expect(clients[0]['has_contract'], 1); // No change
      expect(clients[1]['has_contract'], 0); // Updated to 0
    });

    test('should handle multiple contracts for same client', () async {
      // Mock the database getter for this test
      when(mockDbService.database).thenAnswer((_) async => testDb);

      // Insert test client
      await testDb.insert('clients', {
        'code': 'C001',
        'name': 'Client 1',
        'has_contract': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert multiple contracts for same client
      await testDb.insert('client_contracts', {
        'code_contract': 'CT001',
        'code_client': 'C001',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await testDb.insert('client_contracts', {
        'code_contract': 'CT002',
        'code_client': 'C001',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Call the method
      await dataSyncService.updateClientsHasContractField();

      // Verify client has_contract is set to 1
      final clients = await testDb.query('clients');
      expect(clients[0]['has_contract'], 1);
    });
  });
}