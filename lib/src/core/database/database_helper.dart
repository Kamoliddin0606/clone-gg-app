import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/visits/data/local/migrations/v6_to_v7.dart';

// Top-level function for unzipping in background isolate
List<int> unzipDatabase(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final file = archive.first;
  if (file.isFile) {
    return file.content as List<int>;
  } else {
    throw Exception("The zip archive does not contain a file.");
  }
}

class DatabaseHelper {
  static const _dbName = "GloriyaMarketing.db";
  static const _zipAssetName = "GloriyaMarketing.zip";
  // v7: Visits v2 REST pipeline tables (outbox, photo_uploads, visits_v2,
  //     visit_tasks_v2, permissions_cache, catalog_cache).
  //     See lib/src/features/visits/data/local/migrations/v6_to_v7.dart.
  static const _dbVersion = 7;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      // Check if the database exists
      final exists = await databaseExists(path);

      if (!exists) {
        if (kDebugMode) {
          print("Creating new copy from asset...");
        }

        // Make sure the parent directory exists
        try {
          await Directory(dirname(path)).create(recursive: true);
        } catch (_) {}

        // Copy from asset and unzip
        try {
          ByteData data = await rootBundle.load(join("assets", "db", _zipAssetName));
          List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

          // Unzip in background isolate to avoid blocking main thread
          final unzippedBytes = await compute(unzipDatabase, bytes);

          await File(path).writeAsBytes(unzippedBytes, flush: true);
          if (kDebugMode) {
            print("Database copied successfully.");
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error copying database from assets: $e");
          }
          // Create an empty database if asset copying fails
          return await _createEmptyDatabase(path);
        }
      } else {
        if (kDebugMode) {
          print("Opening existing database.");
        }
      }

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Database initialization error: $e");
      }
      // Fallback: create an in-memory database
      return await openDatabase(
        inMemoryDatabasePath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<Database> _createEmptyDatabase(String path) async {
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create basic tables if database is created from scratch
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        warehouse_code TEXT,
        code_project TEXT,
        base_url TEXT NOT NULL,
        telegram_id TEXT,
        chat_id TEXT,
        topic_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default test user
    await db.insert('users', {
      'code': '001',
      'username': 'test',
      'password': 'test',
      'name': 'Test User',
      'role': 'Agent',
      'warehouse_code': 'W001',
      'code_project': 'P001',
      'base_url': 'http://kit.gloriya.uz:5443/EVYAP_UT/EVYAP_UT.1cws',
    });

    // Notification center tables — owned by the notifications feature.
    await NotificationDbDao.createTables(db);

    // Visits v2 — REST pipeline tables. Mirrors the v6→v7 upgrade so fresh
    // installs land on the same schema as upgraded devices.
    await V6ToV7Migration.apply(db);

    if (kDebugMode) {
      print("Empty database created with basic schema.");
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create users table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          name TEXT NOT NULL,
          role TEXT NOT NULL,
          warehouse_code TEXT,
          code_project TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add base_url column to users table
      await db.execute('ALTER TABLE users ADD COLUMN base_url TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 4) {
      // Add Telegram-related columns to users table
      await db.execute('ALTER TABLE users ADD COLUMN telegram_id TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN chat_id TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN topic_id TEXT');
    }
    if (oldVersion < 5) {
      // Notification center tables — see passport-mobile.md §4.
      await NotificationDbDao.createTables(db);
    }
    if (oldVersion < 6) {
      // Phase 2b: snooze support. Column is nullable so existing rows
      // come through as "never snoozed".
      await NotificationDbDao.addSnoozeColumn(db);
    }
    if (oldVersion < 7) {
      await V6ToV7Migration.apply(db);
    }
  }

  // User management methods
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final db = await database;

    // Validate baseUrl if provided
    final baseUrl = userData['base_url'] as String?;
    if (baseUrl != null && baseUrl.isNotEmpty && !_isValidUrl(baseUrl)) {
      throw ArgumentError('Invalid baseUrl format: $baseUrl');
    }

    // Clear all existing users before inserting new one
    // This ensures only one user record exists at any time
    await db.delete('users');

    await db.insert(
      'users',
      {
        ...userData,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByCredentials(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByCode(String code) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'created_at DESC');
  }

  Future<void> updateUser(String code, Map<String, dynamic> userData) async {
    final db = await database;
    await db.update(
      'users',
      {
        ...userData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<void> deleteUser(String code) async {
    final db = await database;
    await db.delete('users', where: 'code = ?', whereArgs: [code]);
  }

  Future<void> clearAllUsersExcept(String code) async {
    final db = await database;
    await db.delete('users', where: 'code != ?', whereArgs: [code]);
  }

  /// Update client coordinates in database
  Future<void> updateClientCoordinates(String clientCode, double latitude, double longitude) async {
    final db = await database;
    await db.update(
      'clients',
      {
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'code = ?',
      whereArgs: [clientCode],
    );
  }

  /// Get total record count for a specific table
  Future<int> getTableRowCount(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error getting row count for $tableName: $e');
      return 0;
    }
  }

  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}