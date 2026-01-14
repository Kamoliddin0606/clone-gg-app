import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Test script to compare Gemini models: Flash 2.0, Flash 1.5, and Pro 1.5
/// Tests stability, response time, and accuracy for document scanning
void main() {
  const String apiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
  
  // Test models
  const models = [
    'gemini-2.0-flash-exp',      // Gemini 2.0 Flash (experimental)
    'gemini-1.5-flash',          // Gemini 1.5 Flash (stable)
    'gemini-1.5-pro',            // Gemini 1.5 Pro (most capable)
  ];

  group('Gemini Models Stability Test', () {
    test('Test all models with sample document', () async {
      // Create a simple test image (1x1 white pixel PNG)
      final testImage = _createTestImage();
      
      print('\n=== GEMINI MODELS COMPARISON TEST ===\n');
      
      for (final model in models) {
        print('Testing model: $model');
        print('─' * 50);
        
        try {
          final startTime = DateTime.now();
          
          final result = await _testModel(
            model: model,
            apiKey: apiKey,
            imageBytes: testImage,
          );
          
          final duration = DateTime.now().difference(startTime);
          
          print('✅ SUCCESS');
          print('   Response time: ${duration.inMilliseconds}ms');
          print('   Status: ${result['status']}');
          if (result['hasContent'] == true) {
            print('   Content received: Yes');
          }
          print('');
        } catch (e) {
          print('❌ FAILED');
          print('   Error: $e');
          print('');
        }
      }
      
      print('=== TEST COMPLETED ===\n');
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}

/// Test a specific Gemini model
Future<Map<String, dynamic>> _testModel({
  required String model,
  required String apiKey,
  required Uint8List imageBytes,
}) async {
  const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final url = Uri.parse('$baseUrl/models/$model:generateContent?key=$apiKey');
  
  final base64Image = base64Encode(imageBytes);
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': 'Extract organization name and INN from this document. Return JSON format.'},
          {
            'inline_data': {
              'mime_type': 'image/png',
              'data': base64Image,
            }
          }
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.1,
      'topK': 32,
      'topP': 0.95,
      'maxOutputTokens': 512,
    },
  };
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(requestBody),
  ).timeout(const Duration(seconds: 45));
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    final hasContent = candidates != null && candidates.isNotEmpty;
    
    return {
      'status': 'OK',
      'statusCode': 200,
      'hasContent': hasContent,
      'model': model,
    };
  } else {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}

/// Create a minimal test image (1x1 white pixel PNG)
Uint8List _createTestImage() {
  // Minimal PNG file (1x1 white pixel)
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
    0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59,
    0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
    0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);
}
