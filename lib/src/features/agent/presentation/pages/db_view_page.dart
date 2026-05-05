import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

enum DbSource { main, cache, preferences }

class TableInfo {
  final String name;
  final String displayName;
  final DbSource dbType;
  final List<String> columns;
  int rowCount;

  TableInfo({
    required this.name,
    required this.displayName,
    required this.dbType,
    required this.columns,
    this.rowCount = 0,
  });
}

class DbViewPage extends StatefulWidget {
  const DbViewPage({super.key});

  @override
  State<DbViewPage> createState() => _DbViewPageState();
}

class _DbViewPageState extends State<DbViewPage> {
  final ApiDatabaseService _dbService = sl<ApiDatabaseService>();
  final SharedPreferencesService _prefsService = sl<SharedPreferencesService>();
  final DatabaseHelper _dbHelper = sl<DatabaseHelper>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DbSource? _selectedDbFilter;

  List<TableInfo> _tablesMetadata = [];
  Map<String, List<Map<String, dynamic>>> _tableData = {};
  TableInfo? _selectedTable;
  bool _isLoading = true;
  bool _isLoadingTableData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _discoverAndLoadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TableInfo> get _filteredTables {
    return _tablesMetadata.where((table) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          table.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedDbFilter == null || table.dbType == _selectedDbFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Map<DbSource, List<TableInfo>> get _groupedTables {
    final filtered = _filteredTables;
    return {
      DbSource.main: filtered.where((t) => t.dbType == DbSource.main).toList(),
      DbSource.cache: filtered
          .where((t) => t.dbType == DbSource.cache)
          .toList(),
      DbSource.preferences: filtered
          .where((t) => t.dbType == DbSource.preferences)
          .toList(),
    };
  }

  Future<void> _discoverAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<TableInfo> allTables = [];

      final mainDb = await _dbHelper.database;
      final mainTables = await mainDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      for (var table in mainTables) {
        final tableName = table['name'] as String;
        final columns = await mainDb.rawQuery("PRAGMA table_info($tableName)");
        final countResult = await mainDb.rawQuery(
          "SELECT COUNT(*) as count FROM $tableName",
        );
        final rowCount = countResult.first['count'] as int? ?? 0;
        allTables.add(
          TableInfo(
            name: tableName,
            displayName: tableName,
            dbType: DbSource.main,
            columns: columns.map((c) => c['name'] as String).toList(),
            rowCount: rowCount,
          ),
        );
      }

      final cacheDb = await _dbService.database;
      final cacheTables = await cacheDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      for (var table in cacheTables) {
        final tableName = table['name'] as String;
        final columns = await cacheDb.rawQuery("PRAGMA table_info($tableName)");
        final countResult = await cacheDb.rawQuery(
          "SELECT COUNT(*) as count FROM $tableName",
        );
        final rowCount = countResult.first['count'] as int? ?? 0;
        allTables.add(
          TableInfo(
            name: tableName,
            displayName: tableName,
            dbType: DbSource.cache,
            columns: columns.map((c) => c['name'] as String).toList(),
            rowCount: rowCount,
          ),
        );
      }

      allTables.add(
        TableInfo(
          name: 'preferences',
          displayName: 'Preferences',
          dbType: DbSource.preferences,
          columns: ['Key', 'Value'],
          rowCount: _prefsService.preferences.getKeys().length,
        ),
      );

      allTables.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _tablesMetadata = allTables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Discovery error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTableData(
    TableInfo table, {
    VoidCallback? onComplete,
  }) async {
    if (_tableData.containsKey(table.displayName)) {
      setState(() => _selectedTable = table);
      onComplete?.call();
      return;
    }

    setState(() {
      _isLoadingTableData = true;
      _selectedTable = table;
    });

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
          final prefs = _prefsService.preferences;
          final keys = prefs.getKeys().toList()..sort();
          data = keys
              .map((k) => {'Key': k, 'Value': prefs.get(k)?.toString() ?? 'null'})
              .toList();
          break;
      }

      setState(() {
        _tableData[table.displayName] = data;
        _isLoadingTableData = false;
      });
      onComplete?.call();
    } catch (e) {
      setState(() {
        _tableData[table.displayName] = [
          {'Error': e.toString()},
        ];
        _isLoadingTableData = false;
      });
      onComplete?.call();
    }
  }

  Future<void> _saveOrderDraftToFile() async {
    try {
      final cacheDb = await _dbService.database;
      final results = await cacheDb.query(
        'visit_steps_data',
        where: 'data_type = ?',
        whereArgs: ['order_draft'],
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'orderdraft_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = '${directory.path}/$fileName';

      final jsonData = jsonEncode(results);
      final file = File(filePath);
      await file.writeAsString(jsonData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Draft saved: $fileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Error'}: $e',
            ),
          ),
        );
    }
  }

  String _getDbSourceLabel(DbSource source) {
    switch (source) {
      case DbSource.main:
        return 'Main DB';
      case DbSource.cache:
        return 'Cache DB';
      case DbSource.preferences:
        return 'Preferences';
    }
  }

  Color _getDbSourceColor(DbSource source) {
    switch (source) {
      case DbSource.main:
        return Colors.blue;
      case DbSource.cache:
        return Colors.orange;
      case DbSource.preferences:
        return Colors.purple;
    }
  }

  IconData _getDbSourceIcon(DbSource source) {
    switch (source) {
      case DbSource.main:
        return Icons.storage;
      case DbSource.cache:
        return Icons.cached;
      case DbSource.preferences:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.databaseView),
        actions: [
          if (!isWideScreen)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _showTableSelectorSheet(context),
              tooltip: 'Jadvallar',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _tableData.clear();
              _selectedTable = null;
              _discoverAndLoadData();
            },
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveOrderDraftToFile,
            tooltip: 'Save Order Draft',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : isWideScreen
          ? Row(
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    border: Border(right: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: _buildTableSelectorPanel(),
                ),
                Expanded(child: _buildTableDataPanel()),
              ],
            )
          : _buildTableDataPanel(),
    );
  }

  void _showTableSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Jadvallar', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildTableSelectorPanel(
                scrollController: scrollController,
                onTableSelected: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSelectorPanel({
    ScrollController? scrollController,
    VoidCallback? onTableSelected,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  AppLocalizations.of(context)?.searchHint ??
                  'Jadval qidirish...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: cs.surface,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _buildFilterChip(null, 'Hammasi', Icons.apps),
              const SizedBox(width: 6),
              _buildFilterChip(DbSource.main, 'Main', Icons.storage),
              const SizedBox(width: 6),
              _buildFilterChip(DbSource.cache, 'Cache', Icons.cached),
              const SizedBox(width: 6),
              _buildFilterChip(DbSource.preferences, 'Prefs', Icons.settings),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredTables.length} jadval',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: _buildTableList(
            scrollController: scrollController,
            onTableSelected: onTableSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildTableDataPanel() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_selectedTable == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Jadval tanlang',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (MediaQuery.of(context).size.width <= 600)
              FilledButton.icon(
                onPressed: () => _showTableSelectorSheet(context),
                icon: const Icon(Icons.list),
                label: Text(
                  AppLocalizations.of(context)?.tables ?? 'Jadvallar',
                ),
              ),
          ],
        ),
      );
    }

    return _buildTableView();
  }

  Widget _buildFilterChip(DbSource? source, String label, IconData icon) {
    final isSelected = _selectedDbFilter == source;
    final cs = Theme.of(context).colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedDbFilter = source),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTableList({
    ScrollController? scrollController,
    VoidCallback? onTableSelected,
  }) {
    final grouped = _groupedTables;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (grouped[DbSource.main]!.isNotEmpty)
          _buildTableGroup(
            DbSource.main,
            grouped[DbSource.main]!,
            onTableSelected,
          ),
        if (grouped[DbSource.cache]!.isNotEmpty)
          _buildTableGroup(
            DbSource.cache,
            grouped[DbSource.cache]!,
            onTableSelected,
          ),
        if (grouped[DbSource.preferences]!.isNotEmpty)
          _buildTableGroup(
            DbSource.preferences,
            grouped[DbSource.preferences]!,
            onTableSelected,
          ),
      ],
    );
  }

  Widget _buildTableGroup(
    DbSource source,
    List<TableInfo> tables,
    VoidCallback? onTableSelected,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _getDbSourceColor(source);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(_getDbSourceIcon(source), size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                _getDbSourceLabel(source),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tables.length}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
        ...tables.map((table) => _buildTableTile(table, onTableSelected)),
      ],
    );
  }

  Widget _buildTableTile(TableInfo table, VoidCallback? onTableSelected) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = _selectedTable?.displayName == table.displayName;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withOpacity(0.5)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _loadTableData(table, onComplete: onTableSelected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? cs.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${table.rowCount} qator • ${table.columns.length} ustun',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.chevron_right, size: 18, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final table = _selectedTable!;
    final data = _tableData[table.displayName] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - made responsive with Wrap
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getDbSourceColor(table.dbType).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getDbSourceIcon(table.dbType),
                      size: 18,
                      color: _getDbSourceColor(table.dbType),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      table.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip('${data.length} qator'),
                  _buildInfoChip('${table.columns.length} ustun'),
                  ActionChip(
                    avatar: const Icon(Icons.view_column, size: 14),
                    label: const Text(
                      'Ustunlar',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _showColumnsDialog(table),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Data table
        Expanded(
          child: _isLoadingTableData
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Jadval bo'sh",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: table.columns
                          .map(
                            (col) => DataColumn(
                              label: Text(
                                col,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      rows: data.map((row) {
                        return DataRow(
                          cells: table.columns.map((col) {
                            final value = row[col]?.toString() ?? 'null';
                            return DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onTap: value.length > 30
                                  ? () => _showCellDialog(col, value)
                                  : null,
                            );
                          }).toList(),
                        );
                      }).toList(),
                      columnSpacing: 24,
                      horizontalMargin: 16,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
    );
  }

  void _showColumnsDialog(TableInfo table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${table.name} ustunlari'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: table.columns.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                title: Text(table.columns[index]),
                dense: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Yopish'),
          ),
        ],
      ),
    );
  }

  void _showCellDialog(String column, String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(column),
        content: SingleChildScrollView(child: SelectableText(value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Yopish'),
          ),
        ],
      ),
    );
  }
}
