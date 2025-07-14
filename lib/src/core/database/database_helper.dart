import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = "GloriyaMarketing.db";
  static const _zipAssetName = "GloriyaMarketing.zip";
  static const _dbVersion = 1;

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
          
          final archive = ZipDecoder().decodeBytes(bytes);
          // Assuming the first file in the zip is the database file
          final file = archive.first;
          
          if (file.isFile) {
            await File(path).writeAsBytes(file.content as List<int>, flush: true);
            if (kDebugMode) {
              print("Database copied successfully.");
            }
          } else {
            throw Exception("The zip archive does not contain a file.");
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
      );
    }
  }

  Future<Database> _createEmptyDatabase(String path) async {
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create basic tables if database is created from scratch
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default test user
    await db.insert('users', {
      'username': 'test',
      'password': 'test',
      'role': 'Agent',
    });

    if (kDebugMode) {
      print("Empty database created with basic schema.");
    }
  }
}