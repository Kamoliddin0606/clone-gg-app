import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gloria_marketing_flutter/src/core/models/faktura_company_details.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_auth_service.dart';

/// Service for fetching company details from Faktura.uz API
class FakturaCompanyService {
  static const String _baseUrl = 'https://api.faktura.uz';
  static const String _companyDetailsEndpoint = '/Api/Company/GetCompanyBasicDetails';

  final FakturaAuthService _authService;

  FakturaCompanyService({required FakturaAuthService authService})
      : _authService = authService;

  /// Fetch company details by INN
  Future<FakturaCompanyDetails> getCompanyDetails(String inn) async {
    if (inn.trim().isEmpty) {
      throw FakturaCompanyException('INN_EMPTY');
    }

    try {
      // Get access token
      final accessToken = await _authService.getAccessToken();

      // Make API request
      final url = Uri.parse('$_baseUrl$_companyDetailsEndpoint').replace(
        queryParameters: {'companyInn': inn.trim()},
      );

      if (kDebugMode) {
        print('Fetching company details for INN: $inn');
        print('Request URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Validate that we have meaningful data
        // If CompanyName and CompanyInn are both null, the company was not found
        if (data['CompanyName'] == null && data['CompanyInn'] == null) {
          throw FakturaCompanyException(
            'COMPANY_NOT_FOUND',
            statusCode: response.statusCode,
          );
        }
        
        return FakturaCompanyDetails.fromJson(data);
      } else if (response.statusCode == 401) {
        throw FakturaCompanyException(
          'AUTH_ERROR',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 404) {
        throw FakturaCompanyException(
          'COMPANY_NOT_FOUND',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 400) {
        throw FakturaCompanyException(
          'INVALID_REQUEST',
          statusCode: response.statusCode,
        );
      } else {
        throw FakturaCompanyException(
          'SERVER_ERROR',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on FakturaCompanyException {
      rethrow;
    } on FakturaAuthException catch (e) {
      throw FakturaCompanyException('AUTH_ERROR', responseBody: e.toString());
    } catch (e) {
      if (kDebugMode) print('Error fetching company details: $e');
      throw FakturaCompanyException('NETWORK_ERROR', responseBody: e.toString());
    }
  }

  /// Validate INN format (9 digits for legal entities, 14 for individuals)
  bool isValidInn(String inn) {
    final trimmed = inn.trim();
    if (trimmed.isEmpty) return false;
    
    // Legal entity: 9 digits, Individual: 14 digits
    final isLegalEntity = RegExp(r'^\d{9}$').hasMatch(trimmed);
    final isIndividual = RegExp(r'^\d{14}$').hasMatch(trimmed);
    
    return isLegalEntity || isIndividual;
  }
}

/// Exception for Faktura company service errors
class FakturaCompanyException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  FakturaCompanyException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => message;
}
