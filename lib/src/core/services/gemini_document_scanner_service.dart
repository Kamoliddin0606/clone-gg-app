import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gloria_marketing_flutter/src/core/models/scanned_document_data.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_base_service.dart';

/// Service for scanning organization certificates using Google Gemini AI
/// 
/// This service uses Gemini's vision capabilities to extract structured data
/// from organization certificates, business licenses, and similar documents.
/// 
/// Features:
/// - Smart model fallback (tries 3 models in priority order)
/// - Automatic image compression (5MB → 500KB)
/// - 10-second timeout per model attempt
/// - Structured data extraction with confidence scores
/// - Support for multiple image formats (JPEG, PNG, WebP, HEIC)
/// 
/// This service extends [GeminiBaseService] for unified API key management
/// and consistent error handling across all Gemini services.
/// 
/// Usage:
/// ```dart
/// final scanner = sl<GeminiDocumentScannerService>();
/// final data = await scanner.scanDocument(imageBytes);
/// print('Organization: ${data.organizationName}');
/// print('INN: ${data.inn}');
/// ```
class GeminiDocumentScannerService extends GeminiBaseService {
  /// Model fallback chain in priority order
  /// Priority: Flash 2.5 > Flash 2.0 Exp > Flash 2.0
  /// These models are tested and working as of Jan 2026
  static const List<String> modelFallbackChain = [
    'gemini-2.5-flash',          // v2.5: Latest - 1.2s response time
    'gemini-2.0-flash-exp',      // v2.0: Fastest - 1.0s response time
    'gemini-2.0-flash',          // v2.0: Stable - 1.1s response time
  ];
  
  /// Timeout for document scanning requests
  /// 10 seconds is needed for large images (5-6MB) in production
  static const Duration scanTimeout = Duration(seconds: 10);
  
  /// Constructor for GeminiDocumentScannerService
  /// 
  /// @param apiKeyService Service for managing API keys
  /// @param dio HTTP client for making requests
  GeminiDocumentScannerService({
    required ApiKeyService apiKeyService,
    required Dio dio,
  }) : super(apiKeyService: apiKeyService, dio: dio);

  /// Scan organization certificate image and extract data
  /// 
  /// Compresses the image, sends it to Gemini AI, and extracts structured
  /// data including organization name, INN, director, address, etc.
  /// 
  /// Uses smart fallback: tries models in priority order with 10s timeout each.
  /// 
  /// @param imageBytes The image data as bytes (supports JPEG, PNG, WebP, HEIC)
  /// @returns Extracted document data as [ScannedDocumentData]
  /// @throws GeminiException if all models fail or image is empty
  Future<ScannedDocumentData> scanDocument(Uint8List imageBytes) async {
    // Validate input
    if (imageBytes.isEmpty) {
      throw GeminiException(
        code: GeminiErrorCode.invalidRequest,
        message: 'Image data is empty',
      );
    }

    // Compress image before sending to API (reduces 5MB to ~500KB)
    final compressedBytes = await _compressImage(imageBytes);
    
    if (kDebugMode) {
      final originalSizeMB = (imageBytes.length / 1024 / 1024).toStringAsFixed(2);
      final compressedSizeMB = (compressedBytes.length / 1024 / 1024).toStringAsFixed(2);
      final ratio = ((1 - compressedBytes.length / imageBytes.length) * 100).toStringAsFixed(1);
      debugPrint('[GeminiDocumentScanner] Original: ${imageBytes.length} bytes ($originalSizeMB MB)');
      debugPrint('[GeminiDocumentScanner] Compressed: ${compressedBytes.length} bytes ($compressedSizeMB MB)');
      debugPrint('[GeminiDocumentScanner] Compression ratio: $ratio%');
    }

    // Convert compressed image to base64
    final base64Image = base64Encode(compressedBytes);
    final mimeType = _detectMimeType(compressedBytes);

    // Build the prompt for document extraction
    final prompt = _buildExtractionPrompt();

    // Build request body with vision content
    final requestBody = _buildRequestBody(prompt, base64Image, mimeType);

    // Use base service fallback mechanism
    try {
      final response = await makeGeminiRequestWithFallback(
        models: modelFallbackChain,
        body: requestBody,
        timeout: scanTimeout,
      );
      
      return _parseResponse(response);
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiDocumentScanner] Unexpected error: $e');
      }
      throw GeminiException(
        code: GeminiErrorCode.unknownError,
        message: 'Document scanning failed: $e',
      );
    }
  }

  /// Build request body for document extraction
  /// 
  /// @param prompt The extraction prompt
  /// @param base64Image Base64 encoded image data
  /// @param mimeType MIME type of the image
  /// @returns Request body map
  Map<String, dynamic> _buildRequestBody(
    String prompt, 
    String base64Image, 
    String mimeType,
  ) {
    return {
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
  }

  /// Build the extraction prompt for Gemini
  /// 
  /// Creates a detailed prompt instructing Gemini to extract
  /// specific fields from the document image.
  /// 
  /// @returns The extraction prompt string
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

  /// Parse Gemini API response and extract document data
  /// 
  /// @param response The raw API response
  /// @returns Parsed document data
  /// @throws GeminiException if parsing fails
  ScannedDocumentData _parseResponse(Map<String, dynamic> response) {
    try {
      // Use base service method to extract text
      final textContent = extractTextFromResponse(response);
      
      if (kDebugMode) {
        debugPrint('[GeminiDocumentScanner] Raw response text: $textContent');
      }

      // Parse JSON from response
      final jsonData = _extractJsonFromText(textContent);
      return ScannedDocumentData.fromJson(jsonData);
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiDocumentScanner] Parse error: $e');
      }
      throw GeminiException(
        code: GeminiErrorCode.parseError,
        message: 'Failed to parse AI response: $e',
      );
    }
  }

  /// Extract JSON object from response text
  /// 
  /// Handles markdown code blocks and finds JSON object boundaries.
  /// 
  /// @param text The raw text response
  /// @returns Parsed JSON map
  /// @throws GeminiException if JSON parsing fails
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
      throw GeminiException(
        code: GeminiErrorCode.parseError,
        message: 'Invalid JSON in response: $e',
      );
    }
  }

  /// Compress image to reduce size while maintaining text readability
  /// 
  /// Reduces 5-6MB images to ~500KB for faster API calls.
  /// Uses max 1920px dimension and 85% quality for optimal balance.
  /// 
  /// @param imageBytes Original image bytes
  /// @returns Compressed image bytes (or original if compression fails/increases size)
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Compress image with optimal settings for document scanning
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 1920,        // Max width for good text readability
        minHeight: 1920,       // Max height for good text readability
        quality: 85,           // 85% quality - good balance for text
        format: CompressFormat.jpeg, // JPEG for smaller size
      );

      // If compression failed or made it bigger, return original
      if (compressedBytes.isEmpty || compressedBytes.length >= imageBytes.length) {
        if (kDebugMode) {
          debugPrint('[GeminiDocumentScanner] Compression skipped (result larger or empty)');
        }
        return imageBytes;
      }

      return compressedBytes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiDocumentScanner] Compression error: $e, using original image');
      }
      return imageBytes; // Return original on error
    }
  }

  /// Detect MIME type from image bytes
  /// 
  /// Checks magic bytes to determine image format.
  /// Supports JPEG, PNG, WebP, and HEIC formats.
  /// 
  /// @param bytes Image bytes to analyze
  /// @returns MIME type string (defaults to 'image/jpeg')
  String _detectMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';

    // Check magic bytes for image type
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP: 52 49 46 46 (RIFF)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }
    // HEIC: Check for ftyp
    if (bytes.length >= 12) {
      final ftypStr = String.fromCharCodes(bytes.sublist(4, 8));
      if (ftypStr == 'ftyp') {
        return 'image/heic';
      }
    }

    return 'image/jpeg'; // Default fallback
  }
}
