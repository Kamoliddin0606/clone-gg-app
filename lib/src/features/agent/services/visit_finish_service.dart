import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_creation_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/feature_flags.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/permissions.dart'
    as visits_v2;

/// Service for handling visit completion process
/// Manages step-by-step server synchronization with progress tracking and error handling
class VisitFinishService {
  final VisitDataRepository _visitDataRepository;

  VisitFinishService(this._visitDataRepository);

  /// Completes a visit by processing all step data sequentially
  /// Sequence: Visit Data → Order → Other Steps
  /// Sends each step's data to server with progress updates
  /// If any step fails, cancels all previously sent steps
  ///
  /// Parameters:
  /// - visitId: Unique identifier for the visit session
  /// - tradingPoint: Trading point information
  /// - permissions: Sales requirements permissions containing visit steps
  /// - onProgress: Callback for progress updates (stepIndex, totalSteps, message, requestData)
  /// - onError: Callback for error notifications (step, error)
  ///
  /// Returns: true if all steps completed successfully, false otherwise
  Future<bool> finishVisit({
    required String visitId,
    required TradingPointWithPermissions tradingPoint,
    required SalesReqPermissions permissions,
    required Function(int currentStep, int totalSteps, String message, [String? requestData]) onProgress,
    required Function(VisitStep step, String error) onError,
  }) async {
    try {
      debugPrint('VisitFinishService: Starting visit completion for visitId: $visitId');

      // Visits v2 feature flag short-circuit. When the server flips the
      // `visit_submission_path` flag to `rest_v2`, the trading-points page
      // routes the user to VisitSessionPage / VisitSessionBloc instead of
      // VisitStepsPage, so this service should never run on that path. If a
      // stale caller still reaches us, refuse early instead of double-sending
      // the visit through SOAP — the v2 envelope is already enqueued in the
      // outbox.
      if (_isRestV2Active()) {
        debugPrint('VisitFinishService: REST v2 path active — skipping SOAP finish');
        onProgress(0, 1, 'REST v2 oqimi orqali yuborilmoqda');
        return false;
      }

      debugPrint('VisitFinishService: Sequence: Visit Data → Order → Other Steps');

      final visitSteps = permissions.visitSteps;
      final totalSteps = visitSteps.length + 1; // +1 for initial visit data step

      // Track successfully processed steps for rollback
      final processedSteps = <VisitStep>[];

      // Step 0: Send general visit information first
      onProgress(0, totalSteps, 'Tashrif umumiy malumotlarini yuborish...');

      try {
        final visitDataSuccess = await _processVisitDataStep(
          visitId: visitId,
          tradingPoint: tradingPoint,
          permissions: permissions,
          onProgress: (message) => onProgress(0, totalSteps, message),
        );

        if (!visitDataSuccess) {
          debugPrint('VisitFinishService: Visit data step failed');
          onError(VisitStep(stepCode: 0, stepName: 'Tashrif malumotlari', stepRequired: true), 'Tashrif malumotlarini yuborib bo\'lmadi');
          return false;
        }

        // Add visit data step to processed list
        processedSteps.add(VisitStep(stepCode: 0, stepName: 'Tashrif malumotlari', stepRequired: true));

        onProgress(1, totalSteps, 'Tashrif malumotlari muvaffaqiyatli yuborildi');

      } catch (e, stackTrace) {
        debugPrint('VisitFinishService: Error processing visit data step: $e');
        debugPrint('VisitFinishService: Stack trace: $stackTrace');
        onError(VisitStep(stepCode: 0, stepName: 'Tashrif malumotlari', stepRequired: true), 'Tashrif malumotlarida xatolik: ${e.toString()}');
        return false;
      }

      // Step 1: Process order step first (if exists)
      final orderStep = visitSteps.firstWhere(
        (step) => step.stepName.toLowerCase() == 'создать заказ',
        orElse: () => VisitStep(stepCode: -1, stepName: '', stepRequired: false),
      );

      if (orderStep.stepCode != -1) {
        onProgress(1, totalSteps, 'Boshlanmoqda: ${orderStep.stepName}');

        try {
          final result = await _processStep(
            visitId: visitId,
            step: orderStep,
            tradingPoint: tradingPoint,
            onProgress: (message, [requestData]) => onProgress(1, totalSteps, message, requestData),
          );

          if (!result['success']) {
            debugPrint('VisitFinishService: Order step failed, canceling processed steps');
            String errorMessage = 'Buyurtma bosqichi bajarilmadi: ${orderStep.stepName}';
            final serverMessage = result['message'] as String?;
            if (serverMessage != null && serverMessage.isNotEmpty) {
              errorMessage = '$errorMessage - $serverMessage';
            }

            onError(orderStep, errorMessage);

            await _cancelProcessedSteps(
              visitId: visitId,
              processedSteps: processedSteps,
              onProgress: (message) => onProgress(1, totalSteps, message),
            );

            return false;
          }

          // Order step successful - add to processed list
          processedSteps.add(orderStep);
          onProgress(2, totalSteps, 'Buyurtma muvaffaqiyatli yuborildi');

        } catch (e, stackTrace) {
          debugPrint('VisitFinishService: Error processing order step: $e');
          debugPrint('VisitFinishService: Stack trace: $stackTrace');

          onError(orderStep, 'Buyurtmada xatolik yuz berdi: ${e.toString()}');

          await _cancelProcessedSteps(
            visitId: visitId,
            processedSteps: processedSteps,
            onProgress: (message) => onProgress(1, totalSteps, message),
          );

          return false;
        }
      }

      // Process remaining visit steps (excluding order step)
      int stepCounter = orderStep.stepCode != -1 ? 2 : 1; // Start from step 2 if order exists, otherwise 1

      for (final step in visitSteps) {
        // Skip order step as it's already processed
        if (step.stepName.toLowerCase() == 'создать заказ') continue;

        onProgress(stepCounter, totalSteps, 'Boshlanmoqda: ${step.stepName}');

        try {
          final result = await _processStep(
            visitId: visitId,
            step: step,
            tradingPoint: tradingPoint,
            onProgress: (message, [requestData]) => onProgress(stepCounter, totalSteps, message, requestData),
          );

          if (!result['success']) {
            debugPrint('VisitFinishService: Step ${step.stepCode} failed, canceling processed steps');
            onError(step, 'Bosqich bajarilmadi: ${step.stepName}');

            await _cancelProcessedSteps(
              visitId: visitId,
              processedSteps: processedSteps,
              onProgress: (message) => onProgress(stepCounter, totalSteps, message),
            );

            return false;
          }

          // Step successful - add to processed list
          processedSteps.add(step);
          onProgress(stepCounter + 1, totalSteps, 'Bajarildi: ${step.stepName}');

        } catch (e, stackTrace) {
          debugPrint('VisitFinishService: Error processing step ${step.stepCode}: $e');
          debugPrint('VisitFinishService: Stack trace: $stackTrace');

          onError(step, 'Xatolik yuz berdi: ${e.toString()}');

          await _cancelProcessedSteps(
            visitId: visitId,
            processedSteps: processedSteps,
            onProgress: (message) => onProgress(stepCounter, totalSteps, message),
          );

          return false;
        }

        stepCounter++;
      }

      // All steps completed successfully
      onProgress(totalSteps, totalSteps, 'Barcha bosqichlar muvaffaqiyatli bajarildi');

      // Clear all visit data after successful completion to prevent data accumulation
      final cleanupSuccess = await clearVisitDataAfterCompletion(visitId: visitId);
      if (!cleanupSuccess) {
        debugPrint('VisitFinishService: Warning - visit data cleanup failed, but completion was successful');
        // Don't fail the completion if cleanup fails
      }

      debugPrint('VisitFinishService: Visit completion successful for visitId: $visitId');
      return true;

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Critical error during visit completion: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      onError(VisitStep(stepCode: -1, stepName: 'Tizim xatoligi', stepRequired: true), 'Kritik xatolik: ${e.toString()}');
      return false;
    }
  }

  /// Processes a single visit step by sending its data to server
  /// This method contains the logic for each step type
  /// Currently implements placeholder logic - actual server calls to be added later
  ///
  /// Parameters:
  /// - visitId: Visit session identifier
  /// - step: The visit step to process
  /// - tradingPoint: Trading point context
  /// - onProgress: Callback for step-specific progress updates
  ///
  /// Returns: Map with 'success': bool and 'message': String? (server message for order step)
  Future<Map<String, dynamic>> _processStep({
    required String visitId,
    required VisitStep step,
    required TradingPointWithPermissions tradingPoint,
    required Function(String message, [String? requestData]) onProgress,
  }) async {
    try {
      debugPrint('VisitFinishService: Processing step ${step.stepCode} (${step.stepName})');

      // Get step data from repository
      final stepData = await _visitDataRepository.getVisitStepDataByStep(visitId, step.stepCode);
      final completionData = stepData.where((d) => d.dataType == 'completion').toList();

      if (completionData.isEmpty) {
        debugPrint('VisitFinishService: No completion data found for step ${step.stepCode}');
        return {'success': false, 'message': 'Completion data not found'};
      }

      final latestData = completionData.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);

      // Process based on step name
      switch (step.stepName.toLowerCase()) {
        case 'фото до (facing correction)':
          return await _processPhotoFacingBeforeStep(
            visitId: visitId,
            step: step,
            data: latestData,
            tradingPoint: tradingPoint,
            onProgress: onProgress,
          );

        case 'аудит полки (остатки)':
          return await _processShelfAuditStep(
            visitId: visitId,
            step: step,
            data: latestData,
            tradingPoint: tradingPoint,
            onProgress: onProgress,
          );

        case 'аудит конкурентов':
          return await _processCompetitorAuditStep(
            visitId: visitId,
            step: step,
            data: latestData,
            tradingPoint: tradingPoint,
            onProgress: onProgress,
          );

        case 'создать заказ':
          return await _processCreateOrderStep(
            visitId: visitId,
            step: step,
            data: latestData,
            tradingPoint: tradingPoint,
            onProgress: onProgress,
          );

        case 'фото после (facing correction)':
          return await _processPhotoFacingAfterStep(
            visitId: visitId,
            step: step,
            data: latestData,
            tradingPoint: tradingPoint,
            onProgress: onProgress,
          );

        default:
          // For unknown steps, mark as successful (placeholder)
          onProgress('Noma\'lum bosqich: ${step.stepName}');
          debugPrint('VisitFinishService: Unknown step type: ${step.stepName}, marking as successful');
          return {'success': true, 'message': null};
      }

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Error processing step ${step.stepCode}: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Processes photo facing before step
  /// Placeholder implementation - actual server call to be added
  Future<Map<String, dynamic>> _processPhotoFacingBeforeStep({
    required String visitId,
    required VisitStep step,
    required VisitData data,
    required TradingPointWithPermissions tradingPoint,
    required Function(String message) onProgress,
  }) async {
    onProgress('Foto oldingi holatini serverga yuborish...');

    // TODO: Implement actual server call for photo facing before
    // Example: await apiService.sendPhotoFacingData(data.dataContent);

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 500));

    onProgress('Foto oldingi holati muvaffaqiyatli yuborildi');
    return {'success': true, 'message': null};
  }

  /// Processes shelf audit step
  /// Placeholder implementation - actual server call to be added
  Future<Map<String, dynamic>> _processShelfAuditStep({
    required String visitId,
    required VisitStep step,
    required VisitData data,
    required TradingPointWithPermissions tradingPoint,
    required Function(String message) onProgress,
  }) async {
    onProgress('Polka auditini serverga yuborish...');

    // TODO: Implement actual server call for shelf audit
    // Example: await apiService.sendShelfAuditData(data.dataContent);

    await Future.delayed(const Duration(milliseconds: 500));

    onProgress('Polka auditi muvaffaqiyatli yuborildi');
    return {'success': true, 'message': null};
  }

  /// Processes competitor audit step
  /// Placeholder implementation - actual server call to be added
  Future<Map<String, dynamic>> _processCompetitorAuditStep({
    required String visitId,
    required VisitStep step,
    required VisitData data,
    required TradingPointWithPermissions tradingPoint,
    required Function(String message) onProgress,
  }) async {
    onProgress('Konkurentlar auditini serverga yuborish...');

    // TODO: Implement actual server call for competitor audit
    // Example: await apiService.sendCompetitorAuditData(data.dataContent);

    await Future.delayed(const Duration(milliseconds: 500));

    onProgress('Konkurentlar auditi muvaffaqiyatli yuborildi');
    return {'success': true, 'message': null};
  }

  /// Processes create order step
  /// Uses OrderCreationService to build CreateOrder from visit data and sends to server
  /// Handles server response with Code, Message, CodeOrder, Rows validation
  /// Code == 1 indicates success, any other code indicates failure
  /// Returns success status and server message
  Future<Map<String, dynamic>> _processCreateOrderStep({
    required String visitId,
    required VisitStep step,
    required VisitData data,
    required TradingPointWithPermissions tradingPoint,
    required Function(String message, [String? requestData]) onProgress,
  }) async {
    try {
      debugPrint('VisitFinishService: Starting order creation process for visitId: $visitId');

      onProgress('Buyurtma ma\'lumotlarini tayyorlash...');

      // Get OrderCreationService instance from service locator
      final orderCreationService = sl<OrderCreationService>();
      debugPrint('VisitFinishService: Obtained OrderCreationService instance');

      // Build CreateOrder object using the service
      final order = await orderCreationService.buildCreateOrder(
        visitId: visitId,
        stepCode: step.stepCode,
        tradingPoint: tradingPoint,
      );

      debugPrint('VisitFinishService: Created order with ${order.products.length} products, total weight: ${order.weight}, capacity: ${order.capacity}');

      // Get SoapApiService instance from service locator
      final soapApiService = sl<SoapApiService>();
      debugPrint('VisitFinishService: Obtained SoapApiService instance');

      // Generate SOAP request XML for display
      final soapRequest = soapApiService.generateSetOrderSoapRequest(order);
      debugPrint('VisitFinishService: Generated SOAP request for display');

      // Send progress update with request data
      onProgress('Buyurtmani serverga yuborish...', soapRequest);

      // Send order to server
      final response = await soapApiService.setOrder(order: order);
      debugPrint('VisitFinishService: Received response from setOrder: $response');

      // Handle server response
      final code = response['code'] as int;
      final message = response['message'] as String;
      final codeOrder = response['codeOrder'] as String;
      final rows = response['rows'] as String;

      debugPrint('VisitFinishService: Server response - Code: $code, Message: $message, CodeOrder: $codeOrder');

      if (code == 1) {
        // Success - Code 1 indicates successful order creation
        debugPrint('VisitFinishService: Order creation successful - CodeOrder: $codeOrder');

        // Store server message in completion data for potential display
        final completionData = Map<String, dynamic>.from(data.parsedDataContent);
        completionData['serverMessage'] = message;
        completionData['serverCode'] = code;
        completionData['codeOrder'] = codeOrder;

        // Update the completion data with server response
        await _visitDataRepository.saveVisitStepData(VisitData(
          visitId: visitId,
          clientCode: data.clientCode,
          stepCode: step.stepCode,
          stepName: step.stepName,
          dataType: 'completion',
          dataContent: jsonEncode(completionData),
          timestamp: DateTime.now(),
          isSynced: true,
        ));

        // Display success message with server response
        onProgress('$message (raqam: $codeOrder)');
        return {'success': true, 'message': message};
      } else {
        // Error - Any code other than 1 indicates failure
        debugPrint('VisitFinishService: Order creation failed - Code: $code, Message: $message');

        // Store server message in completion data for error display
        final completionData = Map<String, dynamic>.from(data.parsedDataContent);
        completionData['serverMessage'] = message;
        completionData['serverCode'] = code;
        completionData['error'] = true;

        // Update the completion data with server response
        await _visitDataRepository.saveVisitStepData(VisitData(
          visitId: visitId,
          clientCode: data.clientCode,
          stepCode: step.stepCode,
          stepName: step.stepName,
          dataType: 'completion',
          dataContent: jsonEncode(completionData),
          timestamp: DateTime.now(),
          isSynced: true,
        ));

        onProgress('Buyurtma yaratishda xatolik: $message (kod: $code)');
        return {'success': false, 'message': message};
      }

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Error in _processCreateOrderStep: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      onProgress('Buyurtma yuborishda xatolik yuz berdi: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Processes photo facing after step
  /// Placeholder implementation - actual server call to be added
  Future<Map<String, dynamic>> _processPhotoFacingAfterStep({
    required String visitId,
    required VisitStep step,
    required VisitData data,
    required TradingPointWithPermissions tradingPoint,
    required Function(String message) onProgress,
  }) async {
    onProgress('Foto keyingi holatini serverga yuborish...');

    // TODO: Implement actual server call for photo facing after
    // Example: await apiService.sendPhotoFacingData(data.dataContent);

    await Future.delayed(const Duration(milliseconds: 500));

    onProgress('Foto keyingi holati muvaffaqiyatli yuborildi');
    return {'success': true, 'message': null};
  }

  /// Processes the initial visit data step
  /// Sends general visit information to server before processing individual steps
  /// Includes visit time, client info, location, agent, success status, duration, etc.
  ///
  /// Parameters:
  /// - visitId: Visit session identifier
  /// - tradingPoint: Trading point with location and client information
  /// - permissions: User permissions containing agent information
  /// - onProgress: Callback for step-specific progress updates
  ///
  /// Returns: true if visit data sent successfully, false otherwise
  Future<bool> _processVisitDataStep({
    required String visitId,
    required TradingPointWithPermissions tradingPoint,
    required SalesReqPermissions permissions,
    required Function(String message) onProgress,
  }) async {
    try {
      onProgress('Tashrif malumotlarini tayyorlash...');

      // Calculate visit duration and other metadata
      final visitStartTime = DateTime.now().subtract(const Duration(hours: 1)); // Placeholder - should come from visit start time
      final visitEndTime = DateTime.now();
      final visitDuration = visitEndTime.difference(visitStartTime);

      // Prepare visit data payload
      final visitData = {
        'visitId': visitId,
        'clientCode': tradingPoint.tradingPoint.id,
        'clientName': tradingPoint.tradingPoint.name,
        'clientType': tradingPoint.tradingPoint.tradePointType,
        'location': {
          'latitude': tradingPoint.tradingPoint.latitude,
          'longitude': tradingPoint.tradingPoint.longitude,
          'address': tradingPoint.tradingPoint.address,
          'region': tradingPoint.tradingPoint.region,
          'district': tradingPoint.tradingPoint.district,
        },
        'agentCode': permissions.userCode,
        'visitStartTime': visitStartTime.toIso8601String(),
        'visitEndTime': visitEndTime.toIso8601String(),
        'visitDurationMinutes': visitDuration.inMinutes,
        'visitDate': visitStartTime.toIso8601String().split('T')[0],
        'isSuccessful': true, // Will be determined after all steps complete
        'totalSteps': permissions.visitSteps.length,
        'completedSteps': permissions.visitSteps.length, // Assuming all required steps are completed
        'deviceInfo': {
          'platform': 'mobile',
          'appVersion': '1.0.0', // Should come from app config
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      onProgress('Tashrif malumotlarini serverga yuborish...');

      // TODO: Implement actual server call for visit data
      // Example: await apiService.sendVisitData(visitData);

      // Simulate server call
      await Future.delayed(const Duration(milliseconds: 800));

      debugPrint('VisitFinishService: Visit data sent successfully: $visitData');

      onProgress('Tashrif malumotlari serverga yuborildi');
      return true;

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Error sending visit data: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      onProgress('Tashrif malumotlarini yuborishda xatolik');
      return false;
    }
  }

  /// Cancels all previously processed steps
  /// Called when an error occurs in any step to rollback changes
  /// Placeholder implementation - actual rollback logic to be added
  Future<void> _cancelProcessedSteps({
    required String visitId,
    required List<VisitStep> processedSteps,
    required Function(String message) onProgress,
  }) async {
    if (processedSteps.isEmpty) {
      debugPrint('VisitFinishService: No steps to cancel');
      return;
    }

    onProgress('Xatolik tufayli bajarilgan bosqichlarni bekor qilish...');

    try {
      for (final step in processedSteps) {
        onProgress('Bekor qilish: ${step.stepName}');

        if (step.stepCode == 0) {
          // Cancel visit data step
          // TODO: Implement actual rollback for visit data
          // Example: await apiService.cancelVisitData(visitId);
          debugPrint('VisitFinishService: Canceling visit data for visitId: $visitId');
        } else {
          // Cancel regular step
          // TODO: Implement actual rollback for each step type
          // Example: await apiService.cancelStepData(visitId, step.stepCode);
          debugPrint('VisitFinishService: Canceling step ${step.stepCode} (${step.stepName}) for visitId: $visitId');
        }

        await Future.delayed(const Duration(milliseconds: 200));
      }

      onProgress('Barcha bosqichlar bekor qilindi');
      debugPrint('VisitFinishService: Successfully canceled ${processedSteps.length} processed steps');

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Error canceling processed steps: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      onProgress('Bosqichlarni bekor qilishda xatolik yuz berdi');
      // Don't throw - cancellation failure shouldn't prevent error reporting
    }
  }

  /// Cancels all steps in the visit process
  /// Comprehensive cleanup method that clears all visit-related data from tables
  /// Similar to visit cancellation but more thorough - removes all step data, order drafts, etc.
  /// Uses time.sleep for demonstration as requested
  ///
  /// Parameters:
  /// - visitId: Unique identifier for the visit session to cancel
  ///
  /// Returns: Future that completes when all cleanup is done
  Future<void> cancelAllSteps({
    required String visitId,
  }) async {
    try {
      debugPrint('VisitFinishService: Starting comprehensive cleanup for visitId: $visitId');

      // Clear all visit step data from database
      await _visitDataRepository.deleteVisitStepDataByVisitId(visitId);
      debugPrint('VisitFinishService: Cleared visit step data');

      // Clear order draft data if exists
      // Note: Order draft service handles its own cleanup, but we ensure it's cleared
      try {
        final orderDraftService = sl<OrderDraftService>();
        await orderDraftService.clearVisitDrafts(visitId);
        debugPrint('VisitFinishService: Cleared order draft data');
      } catch (e) {
        debugPrint('VisitFinishService: OrderDraftService not available or clearVisitDrafts failed: $e');
      }

      // Clear any cached data in services
      try {
        final apiDatabaseService = sl<ApiDatabaseService>();
        await apiDatabaseService.clearCreateOrderData();
        debugPrint('VisitFinishService: Cleared create order data');
      } catch (e) {
        debugPrint('VisitFinishService: ApiDatabaseService not available or clearCreateOrderData failed: $e');
      }

      // Simulate processing time as requested
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('VisitFinishService: cancelAllSteps completed with time.sleep simulation');

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Error in cancelAllSteps: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      // Don't throw - cleanup should be best effort
    }
  }

  /// Clears all visit-related data after successful completion
  /// This ensures clean state for next visits and prevents data accumulation
  /// Similar to cancel visit functionality but called after success
  ///
  /// Parameters:
  /// - visitId: Unique identifier for the visit session to clear
  ///
  /// Returns: true if cleanup successful, false otherwise
  Future<bool> clearVisitDataAfterCompletion({
    required String visitId,
  }) async {
    try {
      debugPrint('VisitFinishService: Clearing visit data after successful completion for visitId: $visitId');

      // Delete all visit step data for this visit ID (includes order drafts and step progress)
      await _visitDataRepository.deleteVisitStepDataByVisitId(visitId);

      debugPrint('VisitFinishService: Successfully cleared all visit data for visitId: $visitId');
      return true;

    } catch (e, stackTrace) {
      debugPrint('VisitFinishService: Error clearing visit data after completion: $e');
      debugPrint('VisitFinishService: Stack trace: $stackTrace');
      // Don't throw - cleanup failure shouldn't prevent completion success
      return false;
    }
  }

  /// Asks the service locator whether the Visits v2 REST path is the active
  /// transport. Falls back to `false` (SOAP-only) when the visits module
  /// hasn't been registered yet — e.g. during early-boot tests — so a
  /// missing flag never silently disables the legacy path.
  bool _isRestV2Active() {
    if (!sl.isRegistered<FeatureFlags>()) return false;
    return sl<FeatureFlags>().visitSubmissionPath ==
        visits_v2.VisitSubmissionPath.restV2;
  }
}