import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/models/sync_progress.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/sync_notification_service.dart';

/// Global helper functions for invoking data synchronization from any UI page.
///
/// These functions provide convenient access to [DataSyncOrchestrator]
/// with non-blocking background progress notifications and error handling.
///
/// **Example Usage in Products Page**:
/// ```dart
/// FloatingActionButton(
///   onPressed: () => syncTableFromAnywhere(context, 'products'),
///   child: Icon(Icons.refresh),
/// )
/// ```
///
/// **Example Usage in Clients Page**:
/// ```dart
/// IconButton(
///   icon: Icon(Icons.sync),
///   onPressed: () => syncTableFromAnywhere(context, 'clients'),
/// )
/// ```

/// Sync a table from anywhere in the app with non-blocking progress UI
///
/// This is the most convenient method for triggering table sync from UI.
/// It automatically:
/// - Shows a background progress notification
/// - Handles dependencies (unless disabled)
/// - Cascades to children (unless disabled)
/// - Shows success/error snackbars
///
/// Parameters:
/// - [context]: Build context (for showing snackbars)
/// - [tableId]: ID of table to sync (e.g., 'products', 'clients')
/// - [withCascade]: If true, also sync all dependent children (default: true)
/// - [withDependencies]: If true, auto-sync parent dependencies (default: true)
/// - [showSuccessMessage]: If true, show snackbar on success (default: true)
///
/// Returns [true] if sync completed successfully, [false] if failed.
Future<bool> syncTableFromAnywhere(
  BuildContext context,
  String tableId, {
  bool withCascade = true,
  bool withDependencies = true,
  bool showSuccessMessage = true,
}) async {
  try {
    final orchestrator = sl<DataSyncOrchestrator>();
    final notificationService = sl<SyncNotificationService>();

    // Choose sync method based on parameters
    final Stream<SyncProgress> stream;
    if (withDependencies) {
      stream = orchestrator.syncTableWithCascade(
        tableId,
        cascadeToChildren: withCascade,
      ).asBroadcastStream();
    } else {
      stream = orchestrator.syncTable(tableId).asBroadcastStream();
    }

    // Show background progress notification
    notificationService.showProgress(stream, 'Syncing $tableId');

    // Wait for the stream to complete to determine the result
    final result = await stream.last.then((progress) => !(progress as SyncProgress).hasError);

    // Show success message if requested
    if (result == true && showSuccessMessage) {
      AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Sync of $tableId completed successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return result;
  } catch (e) {
    AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Sync failed: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return false;
  }
}

/// Sync an entire group of tables from anywhere
///
/// Example:
/// ```dart
/// // Sync entire product catalog group
/// await syncGroupFromAnywhere(context, 'product_catalog');
/// ```
Future<bool> syncGroupFromAnywhere(
  BuildContext context,
  String groupId, {
  bool showSuccessMessage = true,
}) async {
  try {
    final orchestrator = sl<DataSyncOrchestrator>();
    final notificationService = sl<SyncNotificationService>();
    final stream = orchestrator.syncGroup(groupId).asBroadcastStream();

    // Show background progress notification
    notificationService.showProgress(stream, 'Syncing Group: $groupId');

    // Wait for the stream to complete to determine the result
    final result = await stream.last.then((progress) => !(progress as SyncProgress).hasError);

    if (result == true && showSuccessMessage) {
      AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Group sync ($groupId) completed successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return result;
  } catch (e) {
    AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Group sync failed: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return false;
  }
}

/// Sync all data from anywhere (complete refresh)
///
/// This performs a full data refresh, syncing all tables in dependency order.
/// Use sparingly as it may take significant time.
///
/// Example:
/// ```dart
/// // Full app data refresh
/// await syncAllDataFromAnywhere(context);
/// ```
Future<bool> syncAllDataFromAnywhere(
  BuildContext context, {
  bool showSuccessMessage = true,
}) async {
  try {
    final orchestrator = sl<DataSyncOrchestrator>();
    final notificationService = sl<SyncNotificationService>();
    final stream = orchestrator.syncAll().asBroadcastStream();

    // Show background progress notification
    notificationService.showProgress(stream, 'Full Data Refresh');

    // Wait for the stream to complete to determine the result
    final result = await stream.last.then((progress) => !(progress as SyncProgress).hasError);

    if (result == true && showSuccessMessage) {
      AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('All data synced successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }

    return result;
  } catch (e) {
    AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Full sync failed: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return false;
  }
}
