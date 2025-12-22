import 'package:gloria_marketing_flutter/src/core/models/sync_table_metadata.dart';

/// Progress information for a table synchronization operation.
///
/// This class is used to report real-time progress updates during sync operations,
/// especially useful for UI progress indicators and dialogs.
///
/// Example usage:
/// ```dart
/// // Single table sync
/// final progress = SyncProgress(
///   tableId: 'products',
///   tableName: 'Products',
///   status: SyncStatus.syncing,
///   progress: 0.5,
///   currentStep: 'Fetching data from server...',
/// );
///
/// // Cascading sync with multiple tables
/// final cascadeProgress = SyncProgress(
///   tableId: 'products',
///   tableName: 'Products',
///   status: SyncStatus.syncing,
///   progress: 0.33,
///   cascadingTables: ['products', 'product_prices', 'promotions'],
///   totalTablesInCascade: 3,
///   completedTablesInCascade: 1,
/// );
/// ```
class SyncProgress {
  /// ID of the table being synced
  final String tableId;

  /// Display name of the table
  final String tableName;

  /// Current synchronization status
  final SyncStatus status;

  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Description of current operation (e.g., "Fetching data...", "Saving to database...")
  final String? currentStep;

  /// Error message if sync failed
  final String? errorMessage;

  /// List of table IDs involved in cascading sync (null if single table sync)
  final List<String>? cascadingTables;

  /// Total number of tables in cascade operation
  final int? totalTablesInCascade;

  /// Number of tables completed in cascade operation
  final int? completedTablesInCascade;

  /// Creates a new sync progress instance
  const SyncProgress({
    required this.tableId,
    required this.tableName,
    required this.status,
    this.progress = 0.0,
    this.currentStep,
    this.errorMessage,
    this.cascadingTables,
    this.totalTablesInCascade,
    this.completedTablesInCascade,
  });

  /// Creates a progress instance for idle/waiting state
  factory SyncProgress.idle(String tableId, String tableName) {
    return SyncProgress(
      tableId: tableId,
      tableName: tableName,
      status: SyncStatus.idle,
      progress: 0.0,
    );
  }

  /// Creates a progress instance for sync start
  factory SyncProgress.started(String tableId, String tableName) {
    return SyncProgress(
      tableId: tableId,
      tableName: tableName,
      status: SyncStatus.syncing,
      progress: 0.0,
      currentStep: 'Starting synchronization...',
    );
  }

  /// Creates a progress instance for successful completion
  factory SyncProgress.completed(String tableId, String tableName) {
    return SyncProgress(
      tableId: tableId,
      tableName: tableName,
      status: SyncStatus.success,
      progress: 1.0,
      currentStep: 'Sync completed successfully',
    );
  }

  /// Creates a progress instance for error state
  factory SyncProgress.error(
    String tableId,
    String tableName,
    String errorMessage,
  ) {
    return SyncProgress(
      tableId: tableId,
      tableName: tableName,
      status: SyncStatus.error,
      progress: 0.0,
      errorMessage: errorMessage,
      currentStep: 'Sync failed',
    );
  }

  /// Creates a copy with modified fields
  SyncProgress copyWith({
    String? tableId,
    String? tableName,
    SyncStatus? status,
    double? progress,
    String? currentStep,
    String? errorMessage,
    List<String>? cascadingTables,
    int? totalTablesInCascade,
    int? completedTablesInCascade,
    bool clearError = false,
  }) {
    return SyncProgress(
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cascadingTables: cascadingTables ?? this.cascadingTables,
      totalTablesInCascade: totalTablesInCascade ?? this.totalTablesInCascade,
      completedTablesInCascade: completedTablesInCascade ?? this.completedTablesInCascade,
    );
  }

  /// Check if this is a cascading sync operation
  bool get isCascading => cascadingTables != null && cascadingTables!.isNotEmpty;

  /// Check if sync is complete (success or error)
  bool get isComplete => status == SyncStatus.success || status == SyncStatus.error;

  /// Check if sync is in progress
  bool get isInProgress => status == SyncStatus.syncing;

  /// Check if sync has error
  bool get hasError => status == SyncStatus.error;

  /// Get progress percentage as integer (0-100)
  int get progressPercent => (progress * 100).round();

  /// Get cascade progress description (e.g., "2 of 5 tables completed")
  String? get cascadeProgressDescription {
    if (!isCascading) return null;
    return '$completedTablesInCascade of $totalTablesInCascade tables completed';
  }

  @override
  String toString() {
    final buffer = StringBuffer('SyncProgress(');
    buffer.write('table: $tableId, ');
    buffer.write('status: $status, ');
    buffer.write('progress: ${progressPercent}%');
    if (isCascading) {
      buffer.write(', cascade: $completedTablesInCascade/$totalTablesInCascade');
    }
    if (errorMessage != null) {
      buffer.write(', error: $errorMessage');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
