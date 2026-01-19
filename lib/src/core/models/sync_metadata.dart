import 'dart:convert';

/// Metadata for tracking sync state and enabling delta updates.
/// 
/// Stores information about the last sync operation for a table,
/// allowing the system to determine what has changed since the last sync.
/// 
/// ## Delta Sync Strategy
/// 1. Compare lastSyncHash with current data hash
/// 2. If hashes match, skip sync entirely
/// 3. If hashes differ, perform incremental update
/// 
/// ## Memory Efficiency
/// - Uses MD5 hash (16 bytes) instead of storing full data
/// - Minimal footprint per table: ~100 bytes
class SyncMetadata {
  /// Unique identifier for the table.
  final String tableId;
  
  /// Timestamp of the last successful sync.
  final DateTime? lastSyncTime;
  
  /// MD5 hash of the data at last sync (for change detection).
  final String? lastSyncHash;
  
  /// Number of records after last sync.
  final int recordCount;
  
  /// Whether the last sync was successful.
  final bool lastSyncSuccess;
  
  /// Error message if last sync failed.
  final String? lastSyncError;
  
  /// Duration of last sync in milliseconds.
  final int? lastSyncDurationMs;

  const SyncMetadata({
    required this.tableId,
    this.lastSyncTime,
    this.lastSyncHash,
    this.recordCount = 0,
    this.lastSyncSuccess = true,
    this.lastSyncError,
    this.lastSyncDurationMs,
  });

  /// Create metadata from a database row.
  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      tableId: map['table_id'] as String,
      lastSyncTime: map['last_sync_time'] != null
          ? DateTime.tryParse(map['last_sync_time'] as String)
          : null,
      lastSyncHash: map['last_sync_hash'] as String?,
      recordCount: (map['record_count'] as int?) ?? 0,
      lastSyncSuccess: (map['last_sync_success'] as int?) == 1,
      lastSyncError: map['last_sync_error'] as String?,
      lastSyncDurationMs: map['last_sync_duration_ms'] as int?,
    );
  }

  /// Convert metadata to a database row.
  Map<String, dynamic> toMap() {
    return {
      'table_id': tableId,
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'last_sync_hash': lastSyncHash,
      'record_count': recordCount,
      'last_sync_success': lastSyncSuccess ? 1 : 0,
      'last_sync_error': lastSyncError,
      'last_sync_duration_ms': lastSyncDurationMs,
    };
  }

  /// Create a copy with updated fields.
  SyncMetadata copyWith({
    String? tableId,
    DateTime? lastSyncTime,
    String? lastSyncHash,
    int? recordCount,
    bool? lastSyncSuccess,
    String? lastSyncError,
    int? lastSyncDurationMs,
  }) {
    return SyncMetadata(
      tableId: tableId ?? this.tableId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncHash: lastSyncHash ?? this.lastSyncHash,
      recordCount: recordCount ?? this.recordCount,
      lastSyncSuccess: lastSyncSuccess ?? this.lastSyncSuccess,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      lastSyncDurationMs: lastSyncDurationMs ?? this.lastSyncDurationMs,
    );
  }

  /// Check if sync is needed based on time threshold.
  /// 
  /// [threshold] - Minimum time between syncs. Default: 5 minutes.
  bool needsSync({Duration threshold = const Duration(minutes: 5)}) {
    if (lastSyncTime == null) return true;
    return DateTime.now().difference(lastSyncTime!) > threshold;
  }

  /// Check if the table has never been synced.
  bool get neverSynced => lastSyncTime == null;

  /// Get human-readable time since last sync.
  String get timeSinceLastSync {
    if (lastSyncTime == null) return 'Never';
    
    final diff = DateTime.now().difference(lastSyncTime!);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'SyncMetadata(tableId: $tableId, lastSync: $timeSinceLastSync, '
        'records: $recordCount, success: $lastSyncSuccess)';
  }
}

/// Result of a delta sync operation.
/// 
/// Contains statistics about what changes were made during the sync.
class SyncDeltaResult {
  /// Number of new records inserted.
  final int insertedCount;
  
  /// Number of existing records updated.
  final int updatedCount;
  
  /// Number of records deleted.
  final int deletedCount;
  
  /// Number of records that were unchanged (skipped).
  final int unchangedCount;
  
  /// Total records after sync.
  final int totalCount;
  
  /// Duration of the sync operation in milliseconds.
  final int durationMs;
  
  /// Whether the sync was successful.
  final bool success;
  
  /// Error message if sync failed.
  final String? error;

  const SyncDeltaResult({
    this.insertedCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
    this.unchangedCount = 0,
    this.totalCount = 0,
    this.durationMs = 0,
    this.success = true,
    this.error,
  });

  /// Create a result for a failed sync.
  factory SyncDeltaResult.error(String message, {int durationMs = 0}) {
    return SyncDeltaResult(
      success: false,
      error: message,
      durationMs: durationMs,
    );
  }

  /// Create a result for a full replacement sync (legacy mode).
  factory SyncDeltaResult.fullReplace({
    required int totalCount,
    required int durationMs,
  }) {
    return SyncDeltaResult(
      insertedCount: totalCount,
      totalCount: totalCount,
      durationMs: durationMs,
    );
  }

  /// Total number of records that were modified.
  int get modifiedCount => insertedCount + updatedCount + deletedCount;

  /// Whether any changes were made.
  bool get hasChanges => modifiedCount > 0;

  /// Percentage of records that were unchanged (0.0 - 1.0).
  double get unchangedRate {
    final total = modifiedCount + unchangedCount;
    return total == 0 ? 1.0 : unchangedCount / total;
  }

  /// Human-readable summary of changes.
  String get summary {
    if (!success) return 'Error: $error';
    if (!hasChanges) return 'No changes ($totalCount records)';
    
    final parts = <String>[];
    if (insertedCount > 0) parts.add('+$insertedCount');
    if (updatedCount > 0) parts.add('~$updatedCount');
    if (deletedCount > 0) parts.add('-$deletedCount');
    
    return '${parts.join(', ')} (${durationMs}ms)';
  }

  @override
  String toString() => 'SyncDeltaResult($summary)';
}

/// Utility class for computing data hashes for delta sync.
/// 
/// Uses a simple hash algorithm for fast comparison.
/// Memory efficient and suitable for sync comparison purposes.
class SyncHashUtil {
  SyncHashUtil._();

  /// Compute hash of a list of items.
  /// 
  /// [items] - List of items to hash.
  /// [keyExtractor] - Function to extract unique key from each item.
  /// 
  /// Returns hash string or null if list is empty.
  static String? computeListHash<T>(
    List<T> items,
    String Function(T) keyExtractor,
  ) {
    if (items.isEmpty) return null;
    
    // Sort by key for consistent hash regardless of order
    final sortedKeys = items.map(keyExtractor).toList()..sort();
    final content = sortedKeys.join(',');
    
    return _simpleHash(content);
  }

  /// Compute hash of a set of strings.
  static String? computeSetHash(Set<String> items) {
    if (items.isEmpty) return null;
    
    final sortedItems = items.toList()..sort();
    final content = sortedItems.join(',');
    
    return _simpleHash(content);
  }

  /// Check if two hashes are equal (null-safe).
  static bool hashesEqual(String? hash1, String? hash2) {
    if (hash1 == null && hash2 == null) return true;
    if (hash1 == null || hash2 == null) return false;
    return hash1 == hash2;
  }

  /// Simple hash function using Dart's built-in hashCode.
  /// Returns hex string representation.
  static String _simpleHash(String input) {
    final bytes = utf8.encode(input);
    int hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
