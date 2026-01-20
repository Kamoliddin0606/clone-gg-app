import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/domain/entities/server_time_entity.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/domain/repositories/time_verification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/data/models/server_time_model.dart';

/// Implementation of TimeVerificationRepository
/// 
/// Handles SOAP API communication for server time verification
class TimeVerificationRepositoryImpl implements TimeVerificationRepository {
  final ApiService apiService;

  TimeVerificationRepositoryImpl({required this.apiService});

  @override
  Future<ServerTimeEntity> getServerTime() async {
    try {
      if (kDebugMode) {
        print('[TimeVerificationRepository] Fetching server time...');
      }

      // Call GetServerTime SOAP endpoint
      final response = await apiService.getServerTime();
      
      if (kDebugMode) {
        print('[TimeVerificationRepository] Received response, parsing XML...');
      }

      // Parse XML response
      final document = XmlDocument.parse(response);

      // Check for SOAP Fault
      final fault = document.findAllElements('soap:Fault').firstOrNull;
      if (fault != null) {
        final reason = fault
            .findElements('soap:Reason')
            .firstOrNull
            ?.findElements('soap:Text')
            .firstOrNull
            ?.innerText;
        
        if (kDebugMode) {
          print('[TimeVerificationRepository] SOAP Fault detected: $reason');
        }
        
        throw ServerException(reason ?? 'Unknown server error');
      }

      // Parse success response
      final returnElement = document.findAllElements('m:return').firstOrNull;
      if (returnElement == null) {
        throw ServerException('Invalid response format: missing m:return element');
      }

      // Extract DateTime and DateTimeLimit
      final dateTimeElement = returnElement.findElements('m:DateTime').firstOrNull;
      final dateLimitElement = returnElement.findElements('m:DateTimeLimit').firstOrNull;

      if (dateTimeElement == null || dateLimitElement == null) {
        throw ServerException('Invalid response format: missing DateTime or DateTimeLimit');
      }

      final dateTimeStr = dateTimeElement.innerText;
      final dateLimitStr = dateLimitElement.innerText;

      if (kDebugMode) {
        print('[TimeVerificationRepository] Parsed server time: $dateTimeStr');
        print('[TimeVerificationRepository] Parsed time limit: $dateLimitStr');
      }

      // Create model and convert to entity
      final model = ServerTimeModel.fromSoap(
        dateTimeStr: dateTimeStr,
        dateLimitStr: dateLimitStr,
      );

      if (kDebugMode) {
        print('[TimeVerificationRepository] Server time fetched successfully');
        print('[TimeVerificationRepository] Is expired: ${model.isExpired()}');
        if (!model.isExpired()) {
          print('[TimeVerificationRepository] Remaining time: ${model.getRemainingTime()}');
        }
      }

      return model.toEntity();
    } on ConnectivityException {
      if (kDebugMode) {
        print('[TimeVerificationRepository] Connectivity error occurred');
      }
      rethrow;
    } on AllServersUnavailableException {
      if (kDebugMode) {
        print('[TimeVerificationRepository] All servers unavailable');
      }
      rethrow;
    } on ServerException {
      if (kDebugMode) {
        print('[TimeVerificationRepository] Server exception occurred');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationRepository] Unexpected error: $e');
      }
      throw ServerException('Failed to get server time: $e');
    }
  }
}
