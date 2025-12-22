import 'package:flutter/material.dart';

/// Represents a logical group of related database tables.
///
/// Groups are used to organize tables in the UI and allow batch synchronization
/// of related data entities.
///
/// Example:
/// ```dart
/// final productCatalogGroup = DataSyncGroup(
///   id: 'product_catalog',
///   nameEn: 'Product Catalog',
///   nameRu: 'Каталог продуктов',
///   nameUz: 'Mahsulot katalogi',
///   icon: Icons.inventory_2,
///   tableIds: ['products', 'product_balances', 'product_brands', 'product_series'],
///   color: Colors.blue,
/// );
/// ```
class DataSyncGroup {
  /// Unique identifier for this group (e.g., 'product_catalog', 'clients')
  final String id;

  /// Display name in English
  final String nameEn;

  /// Display name in Russian
  final String nameRu;

  /// Display name in Uzbek
  final String nameUz;

  /// Icon to represent this group in UI
  final IconData icon;

  /// List of table IDs that belong to this group
  final List<String> tableIds;

  /// Optional color for UI theming
  final Color? color;

  /// Creates a new DataSyncGroup
  const DataSyncGroup({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    required this.icon,
    required this.tableIds,
    this.color,
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

  /// Check if this group contains a specific table
  bool containsTable(String tableId) => tableIds.contains(tableId);

  /// Get the number of tables in this group
  int get tableCount => tableIds.length;

  /// Check if this group is empty
  bool get isEmpty => tableIds.isEmpty;

  /// Check if this group has tables
  bool get isNotEmpty => tableIds.isNotEmpty;

  @override
  String toString() => 'DataSyncGroup(id: $id, tables: ${tableIds.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSyncGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
