import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Service for managing Faktura.uz authentication
/// Handles token acquisition, refresh, and storage
class FakturaAuthService {
  static const String _tokenEndpoint = 'https://account.faktura.uz/token';
  static const String _accessTokenKey = 'faktura_access_token';
  static const String _refreshTokenKey = 'faktura_refresh_token';
  static const String _tokenExpiryKey = 'faktura_token_expiry';

  final SharedPreferencesService _prefs;
  final String _username;
  final String _password;
  final String _clientId;
  final String _clientSecret;

  FakturaAuthService({
    required SharedPreferencesService prefs,
    required String username,
    required String password,
    required String clientId,
    required String clientSecret,
  })  : _prefs = prefs,
        _username = username,
        _password = password,
        _clientId = clientId,
        _clientSecret = clientSecret;

  /// Get valid access token, refreshing if necessary
  Future<String> getAccessToken() async {
    try {
      // Check if we have a valid token
      final accessToken = _prefs.preferences.getString(_accessTokenKey);
      final expiryStr = _prefs.preferences.getString(_tokenExpiryKey);

      if (accessToken != null && expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        // If token expires in more than 5 minutes, use it
        if (expiry.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
          return accessToken;
        }
      }

      // Try to refresh token
      final refreshToken = _prefs.preferences.getString(_refreshTokenKey);
      if (refreshToken != null) {
        try {
          return await _refreshAccessToken(refreshToken);
        } catch (e) {
          if (kDebugMode) print('Token refresh failed: $e');
          // Fall through to re-authenticate
        }
      }

      // Authenticate from scratch
      return await _authenticate();
    } catch (e) {
      if (kDebugMode) print('Error getting access token: $e');
      rethrow;
    }
  }

  /// Authenticate and get new tokens
  Future<String> _authenticate() async {
    try {
      if (kDebugMode) {
        print('=== FAKTURA AUTH REQUEST ===');
        print('Endpoint: $_tokenEndpoint');
        print('Headers: Content-Type: application/x-www-form-urlencoded');
        print('Body parameters:');
        print('  grant_type: password');
        print('  username: $_username');
        print('  password: $_password');
        print('  client_id: $_clientId');
        print('  client_secret: $_clientSecret');
        print('===========================');
      }
      
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'password',
          'username': _username,
          'password': _password,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('=== FAKTURA AUTH RESPONSE ===');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('============================');
      }
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return await _saveTokens(data);
      } else {
        if (kDebugMode) {
          print('❌ Authentication failed!');
          print('Status: ${response.statusCode}');
          print('Body: ${response.body}');
        }
        final errorBody = response.body;
        throw FakturaAuthException(
          'AUTH_ERROR',
          statusCode: response.statusCode,
          responseBody: errorBody,
        );
      }
    } catch (e) {
      if (e is FakturaAuthException) rethrow;
      throw FakturaAuthException('NETWORK_ERROR', responseBody: e.toString());
    }
  }

  /// Refresh access token using refresh token
  Future<String> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return await _saveTokens(data);
      } else {
        throw FakturaAuthException(
          'TOKEN_REFRESH_ERROR',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FakturaAuthException) rethrow;
      throw FakturaAuthException('TOKEN_REFRESH_ERROR', responseBody: e.toString());
    }
  }

  /// Save tokens to shared preferences
  Future<String> _saveTokens(Map<String, dynamic> data) async {
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = data['expires_in'] as int? ?? 3600;

    final expiry = DateTime.now().add(Duration(seconds: expiresIn));

    await _prefs.preferences.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _prefs.preferences.setString(_refreshTokenKey, refreshToken);
    }
    await _prefs.preferences.setString(_tokenExpiryKey, expiry.toIso8601String());

    if (kDebugMode) {
      print('Faktura tokens saved. Expires at: $expiry');
    }

    return accessToken;
  }

  /// Clear stored tokens
  Future<void> clearTokens() async {
    await _prefs.preferences.remove(_accessTokenKey);
    await _prefs.preferences.remove(_refreshTokenKey);
    await _prefs.preferences.remove(_tokenExpiryKey);
  }

  /// Check if tokens are stored
  bool hasStoredTokens() {
    return _prefs.preferences.containsKey(_accessTokenKey);
  }
}

/// Exception for Faktura authentication errors
class FakturaAuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  FakturaAuthException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => message;
}
