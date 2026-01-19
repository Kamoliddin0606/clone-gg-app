import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'rest_api_service_client_images_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late RestApiService restApiService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    restApiService = RestApiService(mockDio);
  });

  group('RestApiService Client Images Tests', () {
    test('getClientImages calls correct endpoint with correct parameters', () async {
      // Arrange
      const authToken = 'test_token';
      const clientCode = 'C123';
      final responseData = [
        {
          'id': 1,
          'client_code': clientCode,
          'image_url': 'http://example.com/image.jpg'
        }
      ];

      when(mockDio.options).thenReturn(BaseOptions());
      
      when(mockDio.get(
        any,
        options: anyNamed('options'),
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: responseData,
      ));

      // Act
      final result = await restApiService.getClientImages(
        authToken: authToken,
        clientCode: clientCode,
      );

      // Assert
      expect(result, isNotEmpty);
      expect(result.first['client_code'], clientCode);
      
      verify(mockDio.get(
        'http://178.218.200.120:1596/api/v1/client-image/',
        options: anyNamed('options'), // We can't easily verify headers contents with simple verifying, but endpoint is key
        queryParameters: {'client_code_1c': clientCode},
      )).called(1);
    });
  });
}
