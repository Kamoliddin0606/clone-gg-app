import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';

/// Service for managing step-specific data operations in visit steps
class VisitStepDataService {
  final VisitDataRepository _visitDataRepository;

  VisitStepDataService(this._visitDataRepository);

  /// Photo Step Operations

  /// Save photo data for a step
  Future<void> savePhotoData({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required String imagePath,
    required String thumbnailPath,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final photoData = VisitData.photo(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      imagePath: imagePath,
      thumbnailPath: thumbnailPath,
      description: description,
      metadata: metadata,
    );

    await _visitDataRepository.saveVisitStepData(photoData);
  }

  /// Get all photos for a specific step
  Future<List<VisitData>> getStepPhotos(String visitId, int stepCode) async {
    final allStepData = await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
    return allStepData.where((data) => data.dataType == 'photo').toList();
  }

  /// Delete a specific photo
  Future<void> deletePhoto(String visitId, int stepCode, String imagePath) async {
    final photos = await getStepPhotos(visitId, stepCode);
    final photoToDelete = photos.firstWhere(
      (photo) => photo.parsedDataContent['image_path'] == imagePath,
      orElse: () => throw Exception('Photo not found'),
    );

    // Delete from database - only this specific photo record
    await _visitDataRepository.deleteVisitStepData(photoToDelete.id!);

    // Delete physical files if they exist
    try {
      final imageFile = File(imagePath);
      final thumbnailPath = photoToDelete.parsedDataContent['thumbnail_path'];
      final thumbnailFile = File(thumbnailPath);

      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    } catch (e) {
      // Log error but don't fail the operation
      if (kDebugMode) print('Error deleting photo files: $e');
    }
  }

  /// Get all client photos for a specific client (stepCode 999)
  Future<List<VisitData>> getClientPhotos(String clientCode) async {
    final allClientData = await _visitDataRepository.getVisitStepDataByClient(clientCode);
    return allClientData.where((data) => data.dataType == 'photo' && data.stepCode == 999).toList();
  }

  /// Audit Step Operations

  /// Save audit data (inventory, prices, etc.)
  Future<void> saveAuditData({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> auditData,
  }) async {
    final auditVisitData = VisitData.audit(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      auditData: auditData,
    );

    await _visitDataRepository.saveVisitStepData(auditVisitData);
  }

  /// Get audit data for a step
  Future<VisitData?> getStepAuditData(String visitId, int stepCode) async {
    final allStepData = await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
    final auditData = allStepData.where((data) => data.dataType == 'audit').toList();
    return auditData.isNotEmpty ? auditData.first : null;
  }

  /// Update audit data for a step
  Future<void> updateAuditData({
    required String visitId,
    required int stepCode,
    required Map<String, dynamic> auditData,
  }) async {
    final existingData = await getStepAuditData(visitId, stepCode);
    if (existingData != null) {
      final updatedData = existingData.copyWith(
        dataContent: jsonEncode(auditData),
        timestamp: DateTime.now(),
      );
      await _visitDataRepository.saveVisitStepData(updatedData);
    }
  }

  /// Order Step Operations

  /// Save order data for a step
  Future<void> saveOrderData({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> orderData,
  }) async {
    final orderVisitData = VisitData.order(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      orderData: orderData,
    );

    await _visitDataRepository.saveVisitStepData(orderVisitData);
  }

  /// Get order data for a step
  Future<VisitData?> getStepOrderData(String visitId, int stepCode) async {
    final allStepData = await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
    final orderData = allStepData.where((data) => data.dataType == 'order').toList();
    return orderData.isNotEmpty ? orderData.first : null;
  }

  /// Update order data for a step
  Future<void> updateOrderData({
    required String visitId,
    required int stepCode,
    required Map<String, dynamic> orderData,
  }) async {
    final existingData = await getStepOrderData(visitId, stepCode);
    if (existingData != null) {
      final updatedData = existingData.copyWith(
        dataContent: jsonEncode(orderData),
        timestamp: DateTime.now(),
      );
      await _visitDataRepository.saveVisitStepData(updatedData);
    }
  }

  /// Form Step Operations

  /// Save form data for a step
  Future<void> saveFormData({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> formData,
  }) async {
    final formVisitData = VisitData.form(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      formData: formData,
    );

    await _visitDataRepository.saveVisitStepData(formVisitData);
  }

  /// Get form data for a step
  Future<VisitData?> getStepFormData(String visitId, int stepCode) async {
    final allStepData = await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
    final formData = allStepData.where((data) => data.dataType == 'form').toList();
    return formData.isNotEmpty ? formData.first : null;
  }

  /// Update form data for a step
  Future<void> updateFormData({
    required String visitId,
    required int stepCode,
    required Map<String, dynamic> formData,
  }) async {
    final existingData = await getStepFormData(visitId, stepCode);
    if (existingData != null) {
      final updatedData = existingData.copyWith(
        dataContent: jsonEncode(formData),
        timestamp: DateTime.now(),
      );
      await _visitDataRepository.saveVisitStepData(updatedData);
    }
  }

  /// Note Step Operations

  /// Save note for a step
  Future<void> saveStepNote({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required String note,
  }) async {
    final noteData = VisitData.note(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      note: note,
    );

    await _visitDataRepository.saveVisitStepData(noteData);
  }

  /// Get notes for a step
  Future<List<VisitData>> getStepNotes(String visitId, int stepCode) async {
    final allStepData = await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
    return allStepData.where((data) => data.dataType == 'note').toList();
  }

  /// Generic Step Data Operations

  /// Get all data for a specific step
  Future<List<VisitData>> getStepData(String visitId, int stepCode) async {
    return await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
  }

  /// Check if step has any data
  Future<bool> hasStepData(String visitId, int stepCode) async {
    return await _visitDataRepository.hasVisitStepData(visitId, stepCode);
  }

  /// Get step data grouped by type
  Future<Map<String, List<VisitData>>> getStepDataGroupedByType(String visitId, int stepCode) async {
    final stepData = await getStepData(visitId, stepCode);
    final grouped = <String, List<VisitData>>{};

    for (final data in stepData) {
      if (!grouped.containsKey(data.dataType)) {
        grouped[data.dataType] = [];
      }
      grouped[data.dataType]!.add(data);
    }

    return grouped;
  }

  /// Delete all data for a specific step
  Future<void> deleteStepData(String visitId, int stepCode) async {
    final stepData = await getStepData(visitId, stepCode);

    // Handle file deletions for photos
    for (final data in stepData.where((d) => d.dataType == 'photo')) {
      try {
        final content = data.parsedDataContent;
        final imagePath = content['image_path'];
        final thumbnailPath = content['thumbnail_path'];

        if (imagePath != null) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }

        if (thumbnailPath != null) {
          final thumbnailFile = File(thumbnailPath);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error deleting photo files for step $stepCode: $e');
      }
    }

    // Delete from database
    await _visitDataRepository.deleteVisitStepDataByVisitId(visitId);
  }

  /// Get visit summary data
  Future<Map<String, dynamic>> getVisitSummary(String visitId) async {
    final visitData = await _visitDataRepository.getVisitStepDataByVisitId(visitId);

    final summary = {
      'totalSteps': visitData.map((d) => d.stepCode).toSet().length,
      'photosCount': visitData.where((d) => d.dataType == 'photo').length,
      'auditRecordsCount': visitData.where((d) => d.dataType == 'audit').length,
      'ordersCount': visitData.where((d) => d.dataType == 'order').length,
      'formsCount': visitData.where((d) => d.dataType == 'form').length,
      'notesCount': visitData.where((d) => d.dataType == 'note').length,
      'lastUpdated': visitData.isNotEmpty
          ? visitData.map((d) => d.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };

    return summary;
  }

  /// Validate step data before completion
  Future<bool> validateStepData(String visitId, int stepCode, String stepName) async {
    final stepData = await getStepData(visitId, stepCode);

    // Basic validation based on step type
    switch (stepName.toLowerCase()) {
      case 'rasmga olish':
      case 'фото':
        // Photo step should have at least one photo
        return stepData.where((d) => d.dataType == 'photo').isNotEmpty;

      case 'audit':
      case 'auditoriya':
        // Audit step should have audit data
        return stepData.where((d) => d.dataType == 'audit').isNotEmpty;

      case 'buyurtma':
      case 'заказ':
        // Order step should have order data
        return stepData.where((d) => d.dataType == 'order').isNotEmpty;

      default:
        // For other steps, just check if there's any data
        return stepData.isNotEmpty;
    }
  }

  /// Export visit data for backup/sync
  Future<Map<String, dynamic>> exportVisitData(String visitId) async {
    final visitData = await _visitDataRepository.getVisitStepDataByVisitId(visitId);

    return {
      'visitId': visitId,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': visitData.map((data) => {
        'id': data.id,
        'stepCode': data.stepCode,
        'stepName': data.stepName,
        'dataType': data.dataType,
        'dataContent': data.parsedDataContent,
        'timestamp': data.timestamp.toIso8601String(),
        'isSynced': data.isSynced,
      }).toList(),
    };
  }

  /// Import visit data from backup
  Future<void> importVisitData(Map<String, dynamic> exportData) async {
    final visitId = exportData['visitId'] as String;
    final dataList = exportData['data'] as List<dynamic>;

    for (final dataMap in dataList) {
      final visitData = VisitData(
        id: dataMap['id'],
        visitId: visitId,
        clientCode: '', // Will be set by caller
        stepCode: dataMap['stepCode'] as int,
        stepName: dataMap['stepName'] as String,
        dataType: dataMap['dataType'] as String,
        dataContent: jsonEncode(dataMap['dataContent']),
        timestamp: DateTime.parse(dataMap['timestamp'] as String),
        isSynced: dataMap['isSynced'] as bool,
      );

      await _visitDataRepository.saveVisitStepData(visitData);
    }
  }
}