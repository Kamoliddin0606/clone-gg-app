import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/shared_preferences_service.dart';
import '../services/service_locator.dart';
import '../services/token_service.dart';
import 'models/api_organization.dart';

/// Fetches the public list of organizations and their active projects
/// from the V2 backend. Used on the login page before the user is
/// authenticated, so it carries no auth headers.
///
/// Follows the same self-contained [Dio] pattern as [HealthCheckService].
class OrganizationApiService {
  static const String _tag = 'ORG-API';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches organizations with nested projects from the public endpoint.
  ///
  /// On success the response is also cached in [SharedPreferencesService]
  /// so the login page can render a list even when the backend is
  /// unreachable on subsequent launches.
  Future<List<ApiOrganization>> fetchOrganizations() async {
    final baseUrl = TokenService.v2BaseUrl;
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Accept': 'application/json',
      },
    ));

    try {
      final response = await dio.get('/api/public/v1/organizations/');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results =
            data is Map<String, dynamic> ? (data['results'] as List<dynamic>) : (data as List<dynamic>);

        final organizations =
            results.map((e) => ApiOrganization.fromJson(e as Map<String, dynamic>)).toList();

        // Cache the raw JSON for offline fallback
        try {
          final prefs = sl<SharedPreferencesService>();
          await prefs.setCachedOrganizationsJson(jsonEncode(response.data));
        } catch (_) {}

        if (kDebugMode) {
          print('[$_tag] Fetched ${organizations.length} organizations');
        }
        return organizations;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected status ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[$_tag] Fetch failed: ${e.message}');
      }
      rethrow;
    }
  }

  /// Attempts to load organizations from the [SharedPreferencesService]
  /// cache. Returns an empty list when the cache is missing or corrupt.
  List<ApiOrganization> loadCachedOrganizations() {
    try {
      final prefs = sl<SharedPreferencesService>();
      final raw = prefs.getCachedOrganizationsJson();
      if (raw == null || raw.isEmpty) return [];

      final data = jsonDecode(raw);
      final List<dynamic> results =
          data is Map<String, dynamic> ? (data['results'] as List<dynamic>) : (data as List<dynamic>);

      return results
          .map((e) => ApiOrganization.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Cache load failed: $e');
      }
      return [];
    }
  }
}
