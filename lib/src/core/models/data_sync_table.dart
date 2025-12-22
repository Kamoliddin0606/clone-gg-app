import 'package:flutter/material.dart';

/// Represents a single database table with synchronization configuration.
///
/// This model defines a table that can be synchronized from the server,
/// including its dependencies, cascade relationships, and sync function.
///
/// Example:
/// ```dart
/// final productsTable = DataSyncTable(
///   id: 'products',
///   tableName: 'products',
///   nameEn: 'Products',
///   nameRu: 'Продукты',
///   nameUz: 'Mahsulotlar',
///   icon: Icons.inventory,
///   dependsOn: ['user_warehouses'],
///   cascadeTo: ['product_prices', 'promotions'],
///   groupId: 'product_catalog',
///   syncFunction: () => dataSyncService.syncProducts(...),
/// );
/// ```
class DataSyncTable {
  /// Unique identifier for this table (e.g., 'products', 'clients')
  final String id;

  /// Actual database table name
  final String tableName;

  /// Display name in English
  final String nameEn;

  /// Display name in Russian
  final String nameRu;

  /// Display name in Uzbek
  final String nameUz;

  /// Icon to represent this table in UI
  final IconData icon;

  /// List of table IDs that must be synced before this table
  /// 
  /// Example: product_prices depends on ['products', 'price_types']
  /// This means products and price_types must be synced first
  final List<String> dependsOn;

  /// List of table IDs that should be synced after this table (cascade)
  /// 
  /// Example: products cascades to ['product_prices', 'promotions']
  /// When products is synced with cascade, these tables will also sync
  final List<String> cascadeTo;

  /// The group ID this table belongs to
  final String groupId;

  /// Function to execute for syncing this table
  /// 
  /// This should call the appropriate method from DataSyncService
  final Future<void> Function() syncFunction;

  /// Creates a new DataSyncTable configuration
  const DataSyncTable({
    required this.id,
    required this.tableName,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    required this.icon,
    this.dependsOn = const [],
    this.cascadeTo = const [],
    required this.groupId,
    required this.syncFunction,
  });

  /// Get localized name based on locale
  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return nameRu;
      case 'uz':
        return nameUz;
      case 'en':
      default:
        return nameEn;
    }
  }

  /// Check if this table has any dependencies
  bool get hasDependencies => dependsOn.isNotEmpty;

  /// Check if this table has any cascade targets
  bool get hasCascadeTargets => cascadeTo.isNotEmpty;

  /// Check if this table depends on a specific table
  bool dependsOnTable(String tableId) => dependsOn.contains(tableId);

  /// Check if this table cascades to a specific table
  bool cascadesToTable(String tableId) => cascadeTo.contains(tableId);

  @override
  String toString() => 'DataSyncTable(id: $id, table: $tableName, group: $groupId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSyncTable &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
