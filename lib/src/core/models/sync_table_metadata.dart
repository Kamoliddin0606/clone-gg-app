/// Metadata about a table's synchronization status.
///
/// This class stores information about when a table was last synced,
/// its current status, any errors, and record count.
/// Metadata is persisted to SharedPreferences for cross-session persistence.
///
/// Example usage:
/// ```dart
/// final metadata = SyncTableMetadata(
///   tableId: 'products',
///   lastSyncTime: DateTime.now(),
///   status: SyncStatus.success,
///   recordsCount: 150,
/// );
/// 
/// // Save to SharedPreferences
/// await prefs.setString('sync_meta_products', jsonEncode(metadata.toJson()));
/// 
/// // Load from SharedPreferences
/// final json = jsonDecode(prefs.getString('sync_meta_products')!);
/// final loaded = SyncTableMetadata.fromJson(json);
/// ```
class SyncTableMetadata {
  /// ID of the table this metadata belongs to
  final String tableId;

  /// Last time this table was successfully synced
  final DateTime? lastSyncTime;

  /// Current synchronization status
  final SyncStatus status;

  /// Error message if sync failed
  final String? errorMessage;

  /// Number of records in this table after last sync
  final int recordsCount;

  /// Creates new sync metadata
  const SyncTableMetadata({
    required this.tableId,
    this.lastSyncTime,
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.recordsCount = 0,
  });

  /// Creates metadata from JSON (for SharedPreferences persistence)
  factory SyncTableMetadata.fromJson(Map<String, dynamic> json) {
    return SyncTableMetadata(
      tableId: json['tableId'] as String,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.idle,
      ),
      errorMessage: json['errorMessage'] as String?,
      recordsCount: json['recordsCount'] as int? ?? 0,
    );
  }

  /// Converts metadata to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
      'recordsCount': recordsCount,
    };
  }

  /// Creates a copy with modified fields
  SyncTableMetadata copyWith({
    String? tableId,
    DateTime? lastSyncTime,
    SyncStatus? status,
    String? errorMessage,
    int? recordsCount,
    bool clearError = false,
  }) {
    return SyncTableMetadata(
      tableId: tableId ?? this.tableId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recordsCount: recordsCount ?? this.recordsCount,
    );
  }

  /// Check if this table has ever been synced
  bool get hasBeenSynced => lastSyncTime != null;

  /// Check if last sync was successful
  bool get lastSyncWasSuccessful => status == SyncStatus.success;

  /// Check if there's an error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Check if sync is currently in progress
  bool get isSyncing => status == SyncStatus.syncing;

  /// Get relative time description (e.g., "2 hours ago", "yesterday")
  String getRelativeTime() {
    if (lastSyncTime == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  @override
  String toString() =>
      'SyncTableMetadata(table: $tableId, status: $status, lastSync: ${getRelativeTime()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncTableMetadata &&
          runtimeType == other.runtimeType &&
          tableId == other.tableId &&
          lastSyncTime == other.lastSyncTime &&
          status == other.status;

  @override
  int get hashCode => Object.hash(tableId, lastSyncTime, status);
}

/// Status of a table's synchronization
enum SyncStatus {
  /// Table has not been synced or is waiting to sync
  idle,

  /// Table is currently being synced
  syncing,

  /// Last sync completed successfully
  success,

  /// Last sync failed with an error
  error,
}
