import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

enum DbSource { main, cache, preferences }

class TableInfo {
  final String name;
  final String displayName;
  final DbSource dbType;
  final List<String> columns;

  TableInfo({
    required this.name,
    required this.displayName,
    required this.dbType,
    required this.columns,
  });
}

class DbViewPage extends StatefulWidget {
  const DbViewPage({super.key});

  @override
  State<DbViewPage> createState() => _DbViewPageState();
}

class _DbViewPageState extends State<DbViewPage> with TickerProviderStateMixin {
  TabController? _tabController;
  final ApiDatabaseService _dbService = sl<ApiDatabaseService>();
  final SharedPreferencesService _prefsService = sl<SharedPreferencesService>();
  final DatabaseHelper _dbHelper = sl<DatabaseHelper>();

  // Permission state variables
  bool _isCheckingPermission = false;
  bool _hasStoragePermission = false;

  // Data Discovery
  List<TableInfo> _tablesMetadata = [];
  Map<String, List<Map<String, dynamic>>> _tableData = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _discoverAndLoadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Initialize storage permissions
  Future<void> _initializePermissions() async {
    try {
      setState(() => _isCheckingPermission = true);
      final status = await Permission.storage.status;
      if (status.isGranted) {
        _hasStoragePermission = true;
      } else if (status.isDenied) {
        final result = await Permission.storage.request();
        _hasStoragePermission = result.isGranted;
      }
    } catch (e) {
      if (kDebugMode) print('DEBUG: Error initializing permissions: $e');
    } finally {
      if (mounted) setState(() => _isCheckingPermission = false);
    }
  }

  Future<void> _discoverAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<TableInfo> allTables = [];

      // 1. Discover tables from Main Database
      final mainDb = await _dbHelper.database;
      final mainTables = await mainDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      for (var table in mainTables) {
        final tableName = table['name'] as String;
        final columns = await mainDb.rawQuery("PRAGMA table_info($tableName)");
        allTables.add(TableInfo(
          name: tableName,
          displayName: "[Main] $tableName",
          dbType: DbSource.main,
          columns: columns.map((c) => c['name'] as String).toList(),
        ));
      }

      // 2. Discover tables from Cache Database
      final cacheDb = await _dbService.database;
      final cacheTables = await cacheDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      for (var table in cacheTables) {
        final tableName = table['name'] as String;
        final columns = await cacheDb.rawQuery("PRAGMA table_info($tableName)");
        allTables.add(TableInfo(
          name: tableName,
          displayName: "[Cache] $tableName",
          dbType: DbSource.cache,
          columns: columns.map((c) => c['name'] as String).toList(),
        ));
      }

      // 3. Add virtual/custom tables
      allTables.add(TableInfo(
        name: 'preferences',
        displayName: 'Preferences',
        dbType: DbSource.preferences,
        columns: ['Key', 'Value'],
      ));

      setState(() {
        _tablesMetadata = allTables;
        _tabController = TabController(length: _tablesMetadata.length, vsync: this);
        _isLoading = false;
      });

      if (_tablesMetadata.isNotEmpty) {
        _loadTableData(0);
      }

      _tabController?.addListener(() {
        if (!(_tabController?.indexIsChanging ?? true)) {
          _loadTableData(_tabController!.index);
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = "Discovery error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTableData(int index) async {
    final table = _tablesMetadata[index];
    if (_tableData.containsKey(table.displayName)) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> data = [];
      switch (table.dbType) {
        case DbSource.main:
          final db = await _dbHelper.database;
          data = await db.query(table.name);
          break;
        case DbSource.cache:
          final db = await _dbService.database;
          data = await db.query(table.name);
          break;
        case DbSource.preferences:
          final prefs = {
            'userCode': _prefsService.getUserCode(),
            'userName': _prefsService.getUserName(),
            'warehouseCode': _prefsService.getWarehouseCode(),
            'codeProject': _prefsService.getCodeProject(),
            'serverName': _prefsService.getServerName(),
            'baseUrl': _prefsService.getBaseUrl(),
            'languageCode': _prefsService.getLanguageCode(),
            'isOfflineMode': _prefsService.isOfflineMode(),
          };
          data = prefs.entries.map((e) => {'Key': e.key, 'Value': e.value.toString()}).toList();
          break;
      }

      setState(() {
        _tableData[table.displayName] = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _tableData[table.displayName] = [{'Error': e.toString()}];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOrderDraftToFile() async {
    // Basic implementation to maintain functionality
    try {
      final cacheDb = await _dbService.database;
      final results = await cacheDb.query('visit_steps_data', where: 'data_type = ?', whereArgs: ['order_draft']);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'orderdraft_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = '${directory.path}/$fileName';
      
      final jsonData = jsonEncode(results);
      final file = File(filePath);
      await file.writeAsString(jsonData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Draft saved: $fileName'),
            action: SnackBarAction(label: 'Open', onPressed: () => OpenFile.open(filePath)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.databaseView),
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tablesMetadata.map((t) => Tab(text: t.displayName)).toList(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _discoverAndLoadData,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveOrderDraftToFile,
            tooltip: 'Save Order Draft',
          ),
        ],
      ),
      body: _isLoading && _tablesMetadata.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _tabController == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: _tablesMetadata.map((table) {
                        final data = _tableData[table.displayName] ?? [];
                        return _buildDynamicTable(table, data);
                      }).toList(),
                    ),
    );
  }

  Widget _buildDynamicTable(TableInfo table, List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text("Jadval bo'sh"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: table.columns.map((col) => DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          rows: data.map((row) {
            return DataRow(
              cells: table.columns.map((col) {
                return DataCell(Text(row[col]?.toString() ?? 'null'));
              }).toList(),
            );
          }).toList(),
          columnSpacing: 24,
          horizontalMargin: 16,
        ),
      ),
    );
  }
}