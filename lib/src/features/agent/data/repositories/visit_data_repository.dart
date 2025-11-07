import 'dart:convert';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';

/// Repository for managing visit step data persistence and synchronization
class VisitDataRepository {
  final ApiDatabaseService _dbService;

  VisitDataRepository(this._dbService);

  /// Save visit step data
  Future<void> saveVisitStepData(VisitData visitData) async {
    await _dbService.saveVisitStepData(visitData);
  }

  /// Save multiple visit step data entries
  Future<void> saveVisitStepDataBatch(List<VisitData> visitDataList) async {
    await _dbService.saveVisitStepDataBatch(visitDataList);
  }

  /// Get visit step data by visit ID
  Future<List<VisitData>> getVisitStepDataByVisitId(String visitId) async {
    return await _dbService.getVisitStepDataByVisitId(visitId);
  }

  /// Get visit step data by client code
  Future<List<VisitData>> getVisitStepDataByClient(String clientCode) async {
    return await _dbService.getVisitStepDataByClient(clientCode);
  }

  /// Get visit step data by user (across all visits)
  Future<List<VisitData>> getVisitStepDataByUser(String userCode) async {
    return await _dbService.getVisitStepDataByUser(userCode);
  }

  /// Get pending sync visit step data
  Future<List<VisitData>> getPendingSyncVisitStepData() async {
    return await _dbService.getPendingSyncVisitStepData();
  }

  /// Update visit step data sync status
  Future<void> updateVisitStepDataSyncStatus(int id, bool isSynced, {String? syncError}) async {
    await _dbService.updateVisitStepDataSyncStatus(id, isSynced, syncError: syncError);
  }

  /// Get visit step data statistics
  Future<Map<String, dynamic>> getVisitStepDataStats() async {
    return await _dbService.getVisitStepDataStats();
  }

  /// Delete old visit step data (cleanup)
  Future<void> deleteOldVisitStepData({Duration olderThan = const Duration(days: 30)}) async {
    await _dbService.deleteOldVisitStepData(olderThan: olderThan);
  }

  /// Delete visit step data by visit ID
  Future<void> deleteVisitStepDataByVisitId(String visitId) async {
    await _dbService.deleteVisitStepDataByVisitId(visitId);
  }

  /// Delete visit step data by client code
  Future<void> deleteVisitStepDataByClient(String clientCode) async {
    await _dbService.deleteVisitStepDataByClient(clientCode);
  }

  /// Delete visit step data by visit ID and step code
  Future<void> deleteVisitStepDataByStepCode(String visitId, int stepCode) async {
    await _dbService.deleteVisitStepDataByStepCode(visitId, stepCode);
  }

  /// Delete a specific visit step data record by ID
  Future<void> deleteVisitStepData(int id) async {
    await _dbService.deleteVisitStepData(id);
  }

  /// Create visit step data for a specific step
  Future<VisitData> createVisitStepData({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required String dataType,
    required dynamic dataContent,
    DateTime? timestamp,
  }) async {
    final visitData = VisitData(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      dataType: dataType,
      dataContent: dataContent is String ? dataContent : jsonEncode(dataContent),
      timestamp: timestamp ?? DateTime.now(),
      isSynced: false,
    );

    await saveVisitStepData(visitData);
    return visitData;
  }

  /// Get visit step data by step code and visit ID
  Future<List<VisitData>> getVisitStepDataByStep(String visitId, int stepCode) async {
    final allData = await getVisitStepDataByVisitId(visitId);
    return allData.where((data) => data.stepCode == stepCode).toList();
  }

  /// Get the latest visit step data for a specific step
  Future<VisitData?> getLatestVisitStepData(String visitId, int stepCode) async {
    final stepData = await getVisitStepDataByStep(visitId, stepCode);
    if (stepData.isEmpty) return null;

    // Sort by timestamp descending and return the latest
    stepData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return stepData.first;
  }

  /// Check if visit step data exists for a specific step
  Future<bool> hasVisitStepData(String visitId, int stepCode) async {
    final stepData = await getVisitStepDataByStep(visitId, stepCode);
    return stepData.isNotEmpty;
  }

  /// Get all visit IDs for a user
  Future<List<String>> getUserVisitIds(String userCode) async {
    final userData = await getVisitStepDataByUser(userCode);
    return userData.map((data) => data.visitId).toSet().toList();
  }

  /// Get visit step data grouped by step code
  Future<Map<int, List<VisitData>>> getVisitStepDataGroupedByStep(String visitId) async {
    final allData = await getVisitStepDataByVisitId(visitId);
    final grouped = <int, List<VisitData>>{};

    for (final data in allData) {
      if (!grouped.containsKey(data.stepCode)) {
        grouped[data.stepCode] = [];
      }
      grouped[data.stepCode]!.add(data);
    }

    // Sort each group by timestamp
    for (final stepData in grouped.values) {
      stepData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return grouped;
  }

  /// Mark all visit step data as synced for a visit
  Future<void> markVisitStepDataAsSynced(String visitId) async {
    final visitData = await getVisitStepDataByVisitId(visitId);
    for (final data in visitData) {
      if (!data.isSynced) {
        await updateVisitStepDataSyncStatus(data.id!, true);
      }
    }
  }

  /// Get unsynced visit step data count
  Future<int> getUnsyncedVisitStepDataCount() async {
    final stats = await getVisitStepDataStats();
    return stats['pending'] as int;
  }

  /// Clear all visit step data (for testing or reset)
  Future<void> clearAllVisitStepData() async {
    await _dbService.clearAllData(); // This includes visit_steps_data
  }

  /// Mark data for offline sync (for error recovery)
  Future<void> markDataForOfflineSync(String operationId) async {
    // Implementation would depend on specific requirements
    // For now, just log that data needs offline sync
    print('Data marked for offline sync: $operationId');
  }

  /// Save data with alternative method (for error recovery)
  Future<void> saveWithAlternativeMethod(String operationId, dynamic errorData) async {
    // Implementation would depend on specific requirements
    // For now, just log the alternative save attempt
    print('Attempting alternative save for operation: $operationId');
  }

  /// Mark operation as skipped (for error recovery)
  Future<void> markOperationAsSkipped(String operationId) async {
    // Implementation would depend on specific requirements
    // For now, just log that operation was skipped
    print('Operation marked as skipped: $operationId');
  }
}