import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper User Operations', () {
    late DatabaseHelper dbHelper;
    late String testDbPath;

    setUp(() async {
      // Use a test-specific database
      final dbDir = await getDatabasesPath();
      testDbPath = join(dbDir, 'test_gloria_marketing.db');

      // Delete existing test database
      if (await databaseExists(testDbPath)) {
        await deleteDatabase(testDbPath);
      }

      dbHelper = DatabaseHelper();
      // Force database initialization
      await dbHelper.database;
    });

    tearDown(() async {
      // Clean up database after each test
      final db = await dbHelper.database;
      await db.delete('users');
    });

    test('saveUser saves user data with baseUrl', () async {
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': 'http://example.com/api',
      };

      await dbHelper.saveUser(userData);

      final users = await dbHelper.getAllUsers();
      expect(users.length, 1);
      expect(users.first['code'], '001');
      expect(users.first['username'], 'testuser');
      expect(users.first['base_url'], 'http://example.com/api');
    });

    test('saveUser throws ArgumentError for invalid baseUrl', () async {
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': 'invalid-url',
      };

      expect(() => dbHelper.saveUser(userData), throwsArgumentError);
    });

    test('saveUser accepts empty baseUrl', () async {
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': '',
      };

      await dbHelper.saveUser(userData);

      final users = await dbHelper.getAllUsers();
      expect(users.first['base_url'], '');
    });

    test('getUserByCode returns user with baseUrl', () async {
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': 'http://example.com/api',
      };

      await dbHelper.saveUser(userData);

      final user = await dbHelper.getUserByCode('001');
      expect(user, isNotNull);
      expect(user!['code'], '001');
      expect(user['base_url'], 'http://example.com/api');
    });

    test('getUserByCredentials returns user with baseUrl', () async {
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': 'http://example.com/api',
      };

      await dbHelper.saveUser(userData);

      final user = await dbHelper.getUserByCredentials('testuser', 'password');
      expect(user, isNotNull);
      expect(user!['username'], 'testuser');
      expect(user['base_url'], 'http://example.com/api');
    });

    test('updateUser preserves baseUrl', () async {
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': 'http://example.com/api',
      };

      await dbHelper.saveUser(userData);

      await dbHelper.updateUser('001', {
        'name': 'Updated User',
        'role': 'Boss',
      });

      final user = await dbHelper.getUserByCode('001');
      expect(user!['name'], 'Updated User');
      expect(user['role'], 'Boss');
      expect(user['base_url'], 'http://example.com/api'); // Should be preserved
    });

    test('saveUser handles missing base_url gracefully', () async {
      // Test that when base_url is not provided, it defaults appropriately
      final userData = {
        'code': '001',
        'username': 'testuser',
        'password': 'password',
        'name': 'Test User',
        'role': 'Agent',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        // No base_url provided
      };

      await dbHelper.saveUser(userData);

      final user = await dbHelper.getUserByCode('001');
      expect(user, isNotNull);
      // base_url should either be null (if column doesn't exist) or empty string
      expect(user!['base_url'] == null || user['base_url'] == '', true);
    });
  });
}