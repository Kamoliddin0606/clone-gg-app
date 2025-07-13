import 'dart:io';
import 'package:archive/archive.dart';
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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      print("Creating new copy from asset...");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset and unzip
      ByteData data = await rootBundle.load(join("assets", "db", _zipAssetName));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      final archive = ZipDecoder().decodeBytes(bytes);
      // Assuming the first file in the zip is the database file
      final file = archive.first;
      
      if (file.isFile) {
        await File(path).writeAsBytes(file.content as List<int>, flush: true);
        print("Database copied successfully.");
      } else {
        throw Exception("The zip archive does not contain a file.");
      }
    } else {
      print("Opening existing database.");
    }

    return await openDatabase(path, version: _dbVersion);
  }
}