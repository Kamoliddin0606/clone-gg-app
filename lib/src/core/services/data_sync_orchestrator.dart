import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/models/data_sync_table.dart';
import 'package:gloria_marketing_flutter/src/core/models/data_sync_group.dart';
import 'package:gloria_marketing_flutter/src/core/models/sync_table_metadata.dart';
import 'package:gloria_marketing_flutter/src/core/models/sync_progress.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_config.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';

/// Central orchestrator for managing table-level data synchronization.
///
/// This service handles:
/// - Individual table synchronization
/// - Automatic dependency resolution
/// - Cascading synchronization to dependent tables
/// - Group and全局 synchronization
/// - Metadata persistence across app sessions
///
/// The orchestrator uses a dependency graph defined in [DataSyncConfig]
/// to ensure tables are synced in the correct order, respecting parent-child
/// relationships.
///
/// **Usage Examples**:
///
/// Sync a single table:
/// ```dart
/// final orchestrator = getIt<DataSyncOrchestrator>();
/// await for (final progress in orchestrator.syncTable('products')) {
///   print('Progress: ${progress.progressPercent}%');
/// }
/// ```
///
/// Sync with automatic cascade:
/// ```dart
/// await for (final progress in orchestrator.syncTableWithCascade('products')) {
///   // This will sync: products → product_prices → promotions
/// }
/// ```
///
/// Sync entire group:
/// ```dart
/// await for (final progress in orchestrator.syncGroup('product_catalog')) {
///   print('Syncing ${progress.tableName}...');
/// }
/// ```
class DataSyncOrchestrator {
  final DataSyncService _dataSyncService;
  final SharedPreferencesService _prefs;

  /// Cache of table metadata loaded from preferences
  final Map<String, SyncTableMetadata> _metadataCache = {};

  /// Currently syncing tables (to prevent concurrent syncs of same table)
  final Set<String> _syncingTables = {};

  /// Stream controllers for active sync operations
  final Map<String, StreamController<SyncProgress>> _activeControllers = {};

  /// Initialization state tracking for async tasks (like metadata loading)
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  /// Creates a new DataSyncOrchestrator
  ///
  /// [_dataSyncService] provides the actual sync functions
  /// [_prefs] used for metadata persistence
  DataSyncOrchestrator({
    required DataSyncService dataSyncService,
    required SharedPreferencesService prefs,
  })  : _dataSyncService = dataSyncService,
        _prefs = prefs {
    _initConfiguration();
    _initializeAsync();
  }

  /// Synchronously initialize configuration (must be ready immediately for UI)
  void _initConfiguration() {
    try {
      final userCode = _prefs.getUserCode() ?? '';
      final password = _prefs.getPassword() ?? '';
      final codeProject = _prefs.getCodeProject() ?? '';
      final codeSklad = _prefs.getWarehouseCode() ?? '';

      DataSyncConfig.initialize(
        _dataSyncService,
        userCode,
        password,
        codeProject,
        codeSklad,
      );

      if (kDebugMode) {
        print('DataSyncOrchestrator: Configuration initialized synchronously');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncOrchestrator: Error in synchronous initialization: $e');
      }
    }
  }

  /// Asynchronous initialization for metadata and validation
  Future<void> _initializeAsync() async {
    try {
      await loadMetadata();

      // Validate dependency graph in debug mode
      if (kDebugMode) {
        try {
          DataSyncConfig.validateDependencyGraph();
        } catch (e) {
          print('DataSyncOrchestrator: Dependency graph validation failed: $e');
        }
      }
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }


  // ==========================================================================
  // SYNC OPERATIONS
  // ==========================================================================


  /// Sync a single table WITHOUT dependency resolution or cascading
  ///
  /// Use this only when you're absolutely sure all dependencies are synced.
  /// For most cases, use [syncTableWithCascade] instead.
  ///
  /// Throws [StateError] if table is already syncing.
  /// Returns stream of [SyncProgress] updates.
  Stream<SyncProgress> syncTable(String tableId) async* {
    final table = DataSyncConfig.getTable(tableId);
    if (table == null) {
      yield SyncProgress.error(tableId, tableId, 'Table not found: $tableId');
      return;
    }

    // Check if already syncing
    if (_syncingTables.contains(tableId)) {
      yield SyncProgress.error(
        tableId,
        table.nameEn,
        'Table is already being synced',
      );
      return;
    }

    try {
      _syncingTables.add(tableId);

      // Update metadata: syncing
      final metadata = _metadataCache[tableId] ?? SyncTableMetadata(tableId: tableId);
      _metadataCache[tableId] = metadata.copyWith(status: SyncStatus.syncing, clearError: true);
      await _saveMetadata(tableId);

      // Emit start progress
      yield SyncProgress.started(tableId, table.nameEn);

      // Execute sync function
      await table.syncFunction();

      // Fetch new record count
      int recordsCount = 0;
      if (table.id == 'users') {
        recordsCount = await sl<DatabaseHelper>().getTableRowCount('users');
      } else {
        recordsCount = await sl<ApiDatabaseService>().getTableRowCount(table.tableName);
      }

      // Update metadata: success
      _metadataCache[tableId] = metadata.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        recordsCount: recordsCount,
        clearError: true,
      );
      await _saveMetadata(tableId);

      // Emit completion
      yield SyncProgress.completed(tableId, table.nameEn);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error syncing table $tableId: $e');
        print('Stack trace: $stackTrace');
      }

      // Update metadata: error
      final metadata = _metadataCache[tableId] ?? SyncTableMetadata(tableId: tableId);
      _metadataCache[tableId] = metadata.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      await _saveMetadata(tableId);

      // Emit error
      yield SyncProgress.error(tableId, table.nameEn, e.toString());
    } finally {
      _syncingTables.remove(tableId);
    }
  }

  /// Sync a table with automatic dependency resolution and optional cascading
  ///
  /// This is the recommended method for syncing tables as it:
  /// 1. Resolves all parent dependencies
  /// 2. Syncs dependencies in correct order
  /// 3. Syncs the target table
  /// 4. (Optional) Cascades sync to child tables
  ///
  /// Parameters:
  /// - [tableId]: ID of table to sync
  /// - [cascadeToChildren]: If true, also sync all dependent children
  /// - [forceSyncDependencies]: If true, re-sync dependencies even if already synced
  ///
  /// Example:
  /// ```dart
  /// // Sync product_prices with dependencies
  /// // Will sync: user_warehouses → products → price_types → product_prices
  /// await for (final progress in orchestrator.syncTableWithCascade('product_prices')) {
  ///   print(progress);
  /// }
  /// ```
  Stream<SyncProgress> syncTableWithCascade(
    String tableId, {
    bool cascadeToChildren = true,
    bool forceSyncDependencies = false,
  }) async* {
    final table = DataSyncConfig.getTable(tableId);
    if (table == null) {
      yield SyncProgress.error(tableId, tableId, 'Table not found: $tableId');
      return;
    }

    // Get dependency tree (including the table itself)
    final dependencyTree = DataSyncConfig.getDependencyTree(tableId);

    // Get cascade tree (children only)
    List<String> cascadeTree = [];
    if (cascadeToChildren) {
      cascadeTree = DataSyncConfig.getCascadeTree(tableId);
    }

    // Combine for total table list
    final allTables = [
      ...dependencyTree,
      ...cascadeTree,
    ];

    final totalTables = allTables.length;
    var completedTables = 0;

    try {
      // Sync dependency tree
      for (final depTableId in dependencyTree) {
        final depTable = DataSyncConfig.getTable(depTableId);
        if (depTable == null) continue;

        // Skip if already synced (unless force)
        if (!forceSyncDependencies) {
          final metadata = getTableMetadata(depTableId);
          if (metadata != null && metadata.lastSyncWasSuccessful) {
            completedTables++;
            continue;
          }
        }

        // Sync this dependency
        await for (final progress in syncTable(depTableId)) {
          // Wrap progress to show cascade info
          yield progress.copyWith(
            cascadingTables: allTables,
            totalTablesInCascade: totalTables,
            completedTablesInCascade: completedTables,
          );

          // Check for error
          if (progress.hasError) {
            // Stop cascade on error
            return;
          }
        }

        completedTables++;
      }

      // Sync cascade tree
      if (cascadeToChildren) {
        for (final cascadeTableId in cascadeTree) {
          final cascadeTable = DataSyncConfig.getTable(cascadeTableId);
          if (cascadeTable == null) continue;

          // Sync this child
          await for (final progress in syncTable(cascadeTableId)) {
            yield progress.copyWith(
              cascadingTables: allTables,
              totalTablesInCascade: totalTables,
              completedTablesInCascade: completedTables,
            );

            if (progress.hasError) {
              // Log error but continue with other children
              if (kDebugMode) {
                print('Error syncing cascade table $cascadeTableId: ${progress.errorMessage}');
              }
            }
          }

          completedTables++;
        }
      }

      // Emit final completion
      yield SyncProgress.completed(tableId, table.nameEn).copyWith(
        cascadingTables: allTables,
        totalTablesInCascade: totalTables,
        completedTablesInCascade: completedTables,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in cascading sync for $tableId: $e');
      }
      yield SyncProgress.error(tableId, table.nameEn, e.toString());
    }
  }

  /// Sync all tables in a group.
  ///
  /// Syncs each table in the group sequentially, respecting dependencies.
  /// 
  /// Parameters:
  /// - [groupId]: ID of the group to sync
  /// - [forceResync]: If true, re-sync all tables even if already synced (default: false)
  ///   Set to true for user-triggered syncs to ensure fresh data.
  Stream<SyncProgress> syncGroup(
    String groupId, {
    bool forceResync = false,
  }) async* {
    final group = DataSyncConfig.getGroup(groupId);
    if (group == null) {
      yield SyncProgress.error(groupId, groupId, 'Group not found: $groupId');
      return;
    }

    final tables = DataSyncConfig.getTablesInGroup(groupId);
    if (tables.isEmpty) {
      yield SyncProgress.error(groupId, group.nameEn, 'No tables in group');
      return;
    }

    // Track overall progress for the group
    final totalTables = tables.length;
    var completedTables = 0;

    for (final table in tables) {
      await for (final progress in syncTableWithCascade(
        table.id,
        cascadeToChildren: false, // Don't cascade outside group
        forceSyncDependencies: forceResync, // Respect force resync flag
      )) {
        // Emit progress with group context
        yield progress.copyWith(
          totalTablesInCascade: totalTables,
          completedTablesInCascade: completedTables,
        );

        if (progress.hasError) {
          // Log but continue with next table in group
          if (kDebugMode) {
            print('Error syncing table ${table.id} in group $groupId: ${progress.errorMessage}');
          }
        }
      }
      completedTables++;
    }

    // Emit final group completion
    yield SyncProgress.completed(groupId, group.nameEn).copyWith(
      totalTablesInCascade: totalTables,
      completedTablesInCascade: totalTables,
    );
  }

  /// Sync all tables in all groups
  ///
  /// This performs a complete data refresh, syncing every table in dependency order.
  Stream<SyncProgress> syncAll() async* {
    final allTables = DataSyncConfig.getAllTables();

    // Build topological sort of all tables
    final sorted = <DataSyncTable>[];
    final visited = <String>{};

    void visit(DataSyncTable table) {
      if (visited.contains(table.id)) return;
      visited.add(table.id);

      // Visit dependencies first
      for (final depId in table.dependsOn) {
        final depTable = DataSyncConfig.getTable(depId);
        if (depTable != null) {
          visit(depTable);
        }
      }

      sorted.add(table);
    }

    // Sort all tables
    for (final table in allTables) {
      visit(table);
    }

    // Sync in order
    for (final table in sorted) {
      await for (final progress in syncTable(table.id)) {
        yield progress;

        if (progress.hasError) {
          // Log but continue
          if (kDebugMode) {
            print('Error syncing table ${table.id} in syncAll: ${progress.errorMessage}');
          }
        }
      }
    }
  }

  // ==========================================================================
  // METADATA OPERATIONS
  // ==========================================================================

  /// Get metadata for a specific table
  SyncTableMetadata? getTableMetadata(String tableId) {
    return _metadataCache[tableId];
  }

  /// Get metadata for all tables
  Map<String, SyncTableMetadata> getAllTableMetadata() {
    return Map.unmodifiable(_metadataCache);
  }

  /// Load all table metadata from SharedPreferences
  Future<void> loadMetadata() async {
    try {
      final allTables = DataSyncConfig.getAllTables();

      for (final table in allTables) {
        final key = _getMetadataKey(table.id);
        final jsonString = _prefs.preferences.getString(key);

        if (jsonString != null && jsonString.isNotEmpty) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            _metadataCache[table.id] = SyncTableMetadata.fromJson(json);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing metadata for ${table.id}: $e');
            }
          }
        }
      }

      if (kDebugMode) {
        print('Loaded metadata for ${_metadataCache.length} tables');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading metadata: $e');
      }
    }
  }

  /// Save metadata for a specific table
  Future<void> _saveMetadata(String tableId) async {
    try {
      final metadata = _metadataCache[tableId];
      if (metadata == null) return;

      final key = _getMetadataKey(tableId);
      final jsonString = jsonEncode(metadata.toJson());
      await _prefs.preferences.setString(key, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving metadata for $tableId: $e');
      }
    }
  }

  /// Get SharedPreferences key for table metadata
  String _getMetadataKey(String tableId) => 'sync_metadata_$tableId';

  /// Refresh record counts for all tables from the database
  Future<void> refreshRecordCounts() async {
    try {
      final allTables = DataSyncConfig.getAllTables();
      final dbHelper = sl<DatabaseHelper>();
      final dbService = sl<ApiDatabaseService>();

      for (final table in allTables) {
        int count = 0;
        try {
          if (table.id == 'users') {
            count = await dbHelper.getTableRowCount('users');
          } else {
            count = await dbService.getTableRowCount(table.tableName);
          }
        } catch (e) {
          if (kDebugMode) print('Error refreshing count for ${table.id}: $e');
          continue;
        }

        final currentMeta = _metadataCache[table.id] ?? SyncTableMetadata(tableId: table.id);
        if (currentMeta.recordsCount != count) {
          _metadataCache[table.id] = currentMeta.copyWith(recordsCount: count);
          await _saveMetadata(table.id);
        }
      }
      if (kDebugMode) print('DataSyncOrchestrator: Record counts refreshed for ${allTables.length} tables');
    } catch (e) {
      if (kDebugMode) print('DataSyncOrchestrator: Error refreshing record counts: $e');
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Resolve dependency order for syncing a table
  ///
  /// Returns list of table IDs in the order they should be synced,
  /// including all parent dependencies.
  List<String> resolveDependencies(String tableId) {
    return DataSyncConfig.getDependencyTree(tableId);
  }

  /// Check if a table can be synced (all dependencies are synced)
  bool canSync(String tableId) {
    final table = DataSyncConfig.getTable(tableId);
    if (table == null) return false;

    // Check all dependencies
    for (final depId in table.dependsOn) {
      final depMetadata = getTableMetadata(depId);
      if (depMetadata == null || !depMetadata.lastSyncWasSuccessful) {
        return false;
      }
    }

    return true;
  }

  /// Check if a table is currently syncing
  bool isSyncing(String tableId) {
    return _syncingTables.contains(tableId);
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _activeControllers.values) {
      controller.close();
    }
    _activeControllers.clear();
    _syncingTables.clear();
  }
}
