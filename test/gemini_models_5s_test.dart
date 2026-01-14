import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Test all Gemini models with 5 second timeout
/// Tests Flash 3.0, 2.5, 2.0, and 1.5 models
void main() {
  const String apiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
  
  // Complete fallback chain with all v2+ models
  const models = [
    'gemini-flash-3.0',          // v3.0: Latest
    'gemini-2.5-flash',          // v2.5: Flash
    'gemini-2.5-flash-exp',      // v2.5: Experimental
    'gemini-2.0-flash-exp',      // v2.0: Experimental
    'gemini-2.0-flash',          // v2.0: Stable
    'gemini-exp-1206',           // v2.0: Variant
    'gemini-1.5-flash-latest',   // v1.5: Latest
    'gemini-1.5-flash-002',      // v1.5: Specific
    'gemini-1.5-pro-latest',     // v1.5: Pro
  ];

  group('Gemini Models Test (5s timeout)', () {
    test('Test all models with 5s timeout', () async {
      final testImage = _createTestImage();
      
      print('\n=== GEMINI MODELS TEST (5s timeout) ===');
      print('Testing ${models.length} models\n');
      
      final results = <String, String>{};
      
      for (int i = 0; i < models.length; i++) {
        final model = models[i];
        print('[${i + 1}/${models.length}] $model');
        
        try {
          final startTime = DateTime.now();
          
          await _testModel(
            model: model,
            apiKey: apiKey,
            imageBytes: testImage,
            timeout: const Duration(seconds: 5),
          );
          
          final duration = DateTime.now().difference(startTime);
          final time = '${duration.inMilliseconds}ms';
          results[model] = '✅ $time';
          print('   ✅ SUCCESS in $time\n');
        } catch (e) {
          final error = e.toString().contains('404') ? '404 Not Found' 
                      : e.toString().contains('TimeoutException') ? 'Timeout (>5s)'
                      : 'Error';
          results[model] = '❌ $error';
          print('   ❌ $error\n');
        }
      }
      
      print('=' * 60);
      print('SUMMARY:');
      print('=' * 60);
      
      int successCount = 0;
      for (final entry in results.entries) {
        print('${entry.key.padRight(30)} ${entry.value}');
        if (entry.value.startsWith('✅')) successCount++;
      }
      
      print('\nWorking models: $successCount/${models.length}');
      print('=' * 60);
      
      expect(successCount, greaterThan(0), reason: 'At least one model should work');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

/// Test a specific model
Future<void> _testModel({
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
          {'text': 'Extract organization name. Return JSON.'},
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
      'maxOutputTokens': 256,
    },
  };
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(requestBody),
  ).timeout(timeout);
  
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }
}

/// Create minimal test image (1x1 white pixel PNG)
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
