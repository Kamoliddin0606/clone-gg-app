import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Test smart fallback mechanism with 15 second timeout
/// Tests: gemini-2.0-flash-exp, gemini-exp-1206, gemini-1.5-flash-002
void main() {
  const String apiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
  
  // Fallback chain: v2.0+ first, then v1.5 and below
  const models = [
    'gemini-2.0-flash-exp',           // v2.0: Primary
    'gemini-exp-1206',                // v2.0: Experimental
    'gemini-1.5-flash-latest',        // v1.5: Stable
    'gemini-1.5-flash-002',           // v1.5: Specific release
    'gemini-1.5-pro-latest',          // v1.5: Most capable
  ];

  group('Gemini Smart Fallback Test (15s timeout)', () {
    test('Test fallback mechanism with 15s timeout per model', () async {
      final testImage = _createTestImage();
      
      print('\n=== SMART FALLBACK TEST (15s timeout) ===\n');
      
      final errors = <String>[];
      bool foundWorkingModel = false;
      
      for (int i = 0; i < models.length; i++) {
        final model = models[i];
        print('[${i + 1}/${models.length}] Testing: $model');
        print('─' * 50);
        
        try {
          final startTime = DateTime.now();
          
          final result = await _testModelWithTimeout(
            model: model,
            apiKey: apiKey,
            imageBytes: testImage,
            timeout: const Duration(seconds: 15),
          );
          
          final duration = DateTime.now().difference(startTime);
          
          print('✅ SUCCESS in ${duration.inMilliseconds}ms');
          print('   Model: $model');
          print('   This model will be used!\n');
          foundWorkingModel = true;
          break;
        } catch (e) {
          final errorMsg = '$model: $e';
          errors.add(errorMsg);
          print('❌ FAILED: $e');
          
          if (i < models.length - 1) {
            print('   Falling back to next model...\n');
          } else {
            print('   No more models to try.\n');
          }
        }
      }
      
      if (foundWorkingModel) {
        print('✅ Fallback mechanism works correctly!');
      } else {
        print('❌ All models failed:');
        for (final error in errors) {
          print('   - $error');
        }
      }
      
      print('\n=== TEST COMPLETED ===\n');
      
      expect(foundWorkingModel, isTrue, reason: 'At least one model should work');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

/// Test model with timeout
Future<Map<String, dynamic>> _testModelWithTimeout({
  required String model,
  required String apiKey,
  required Uint8List imageBytes,
  required Duration timeout,
}) async {
  const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final url = Uri.parse('$baseUrl/models/$model:generateContent?key=$apiKey');
  
  final base64Image = base64Encode(imageBytes);
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': 'Extract organization name from this document. Return JSON.'},
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
      'maxOutputTokens': 512,
    },
  };
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(requestBody),
  ).timeout(timeout);
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    return {
      'status': 'OK',
      'statusCode': 200,
      'model': model,
    };
  } else {
    throw Exception('HTTP ${response.statusCode}');
  }
}

/// Create minimal test image
Uint8List _createTestImage() {
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
    0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59,
    0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
    0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);
}
