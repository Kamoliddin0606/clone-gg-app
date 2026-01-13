import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gloria_marketing_flutter/src/core/models/scanned_document_data.dart';

/// Service for scanning organization certificates using Google Gemini AI
/// Uses Gemini 2.0 Flash model for fast and efficient document processing
class GeminiDocumentScannerService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  // Using Gemini 2.0 Flash - stable model with best price-performance for image analysis
  static const String _model = 'gemini-2.0-flash';
  static const int _maxRetries = 2;
  static const Duration _timeout = Duration(seconds: 30);

  final String _apiKey;

  GeminiDocumentScannerService({required String apiKey}) : _apiKey = apiKey;

  /// Scan organization certificate image and extract data
  /// Returns ScannedDocumentData with extracted fields
  /// Throws GeminiScanException on errors
  Future<ScannedDocumentData> scanDocument(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw GeminiScanException('IMAGE_EMPTY', message: 'Image data is empty');
    }

    // Convert image to base64
    final base64Image = base64Encode(imageBytes);
    final mimeType = _detectMimeType(imageBytes);

    // Build the prompt for document extraction
    final prompt = _buildExtractionPrompt();

    // Build request body
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1, // Low temperature for accurate extraction
        'topK': 32,
        'topP': 0.95,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    };

    // Make API request with retry logic
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _makeRequest(requestBody);
        return _parseResponse(response);
      } on GeminiScanException {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw GeminiScanException('MAX_RETRIES', message: 'Maximum retries exceeded');
  }

  /// Build the extraction prompt for Gemini
  String _buildExtractionPrompt() {
    return '''Analyze this organization certificate/business document image and extract the following information in JSON format.

Extract these fields (use null if not found):
- organizationName: Full official name of the organization/company
- inn: Tax Identification Number (STIR/INN/TIN) - 9 or 14 digits
- directorName: Name of the director/CEO/manager
- address: Legal/registration address
- phoneNumber: Contact phone number
- bankAccount: Bank account number (20 digits)
- mfo: Bank MFO code (5 digits)
- oked: Economic activity code (OKED)
- registrationNumber: Registration certificate number
- registrationDate: Registration date (format: YYYY-MM-DD if possible)
- confidence: Your confidence in extraction accuracy (0.0 to 1.0)

Important rules:
1. Extract ONLY visible text from the document
2. Do NOT guess or make up any values
3. For INN/STIR: Extract only numeric digits (9 or 14 characters)
4. For phone: Include country code if visible
5. Return valid JSON only, no markdown or extra text

Return JSON object with extracted fields:''';
  }

  /// Make HTTP request to Gemini API
  Future<Map<String, dynamic>> _makeRequest(Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey');

    if (kDebugMode) {
      print('GeminiScanner: Making request to Gemini API');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(_timeout);

      if (kDebugMode) {
        print('GeminiScanner: Response status: ${response.statusCode}');
        if (response.statusCode != 200) {
          print('GeminiScanner: Error response: ${response.body}');
        }
      }

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        throw GeminiScanException('BAD_REQUEST', 
            statusCode: 400, 
            message: 'Invalid request format');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw GeminiScanException('AUTH_ERROR', 
            statusCode: response.statusCode, 
            message: 'API key is invalid or expired');
      } else if (response.statusCode == 404) {
        throw GeminiScanException('NOT_FOUND', 
            statusCode: 404, 
            message: 'API endpoint not found. Check model name');
      } else if (response.statusCode == 429) {
        throw GeminiScanException('RATE_LIMIT', 
            statusCode: 429, 
            message: 'API rate limit exceeded');
      } else if (response.statusCode >= 500) {
        throw GeminiScanException('SERVER_ERROR', 
            statusCode: response.statusCode, 
            message: 'Gemini server error');
      } else {
        throw GeminiScanException('UNKNOWN_ERROR', 
            statusCode: response.statusCode, 
            message: response.body);
      }
    } on GeminiScanException {
      rethrow;
    } catch (e) {
      if (kDebugMode) print('GeminiScanner: Network error: $e');
      throw GeminiScanException('NETWORK_ERROR', message: e.toString());
    }
  }

  /// Parse Gemini API response and extract document data
  ScannedDocumentData _parseResponse(Map<String, dynamic> response) {
    try {
      // Navigate to the text content
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiScanException('NO_CONTENT', message: 'No response from AI');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw GeminiScanException('NO_CONTENT', message: 'Empty response parts');
      }

      final textContent = parts[0]['text'] as String?;
      if (textContent == null || textContent.isEmpty) {
        throw GeminiScanException('NO_CONTENT', message: 'Empty text response');
      }

      if (kDebugMode) {
        print('GeminiScanner: Raw response text: $textContent');
      }

      // Parse JSON from response
      final jsonData = _extractJsonFromText(textContent);
      return ScannedDocumentData.fromJson(jsonData);
    } catch (e) {
      if (e is GeminiScanException) rethrow;
      if (kDebugMode) print('GeminiScanner: Parse error: $e');
      throw GeminiScanException('PARSE_ERROR', message: 'Failed to parse AI response: $e');
    }
  }

  /// Extract JSON object from response text (handles markdown code blocks)
  Map<String, dynamic> _extractJsonFromText(String text) {
    String jsonStr = text.trim();

    // Remove markdown code blocks if present
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    } else if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    jsonStr = jsonStr.trim();

    // Find JSON object boundaries
    final startIndex = jsonStr.indexOf('{');
    final endIndex = jsonStr.lastIndexOf('}');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      jsonStr = jsonStr.substring(startIndex, endIndex + 1);
    }

    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw GeminiScanException('JSON_PARSE_ERROR', message: 'Invalid JSON in response');
    }
  }

  /// Detect MIME type from image bytes (JPEG, PNG, WebP, HEIC)
  String _detectMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';

    // Check magic bytes for image type
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }
    if (bytes.length >= 12) {
      // HEIC check
      final ftypStr = String.fromCharCodes(bytes.sublist(4, 8));
      if (ftypStr == 'ftyp') {
        return 'image/heic';
      }
    }

    return 'image/jpeg'; // Default fallback
  }
}

/// Exception for Gemini document scanner errors
class GeminiScanException implements Exception {
  final String code;
  final String? message;
  final int? statusCode;

  GeminiScanException(this.code, {this.message, this.statusCode});

  @override
  String toString() => 'GeminiScanException: $code${message != null ? ' - $message' : ''}';
}
