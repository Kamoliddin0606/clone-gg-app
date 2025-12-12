import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

void main() {
  late RestApiService restApiService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    // Mock the options property to avoid null errors
    when(mockDio.options).thenReturn(BaseOptions());
    restApiService = RestApiService(mockDio);
  });

  group('RestApiService Tests', () {
    const authToken = 'test_token';
    const hardcodedUrl = 'http://178.218.200.120:1596';

    group('getThumbnails', () {
      test('returns list of thumbnails on successful API call', () async {
        // Arrange
        final mockResponse = Response(
          data: [
            {
              "entity_type": "nomenklatura",
              "entity_id": 843,
              "code_1c": "00-00001559",
              "entity_name": "Test Product",
              "image_id": 35,
              "thumbnail_url": "http://example.com/image.jpg",
              "thumbnail_dimensions": {"width": 150, "height": 150},
              "original_dimensions": {"width": 432, "height": 376},
              "is_main": true,
              "category": null,
              "note": null,
              "status_code": "product_main",
              "status_name": "Main Product Image",
              "source_name": "Admin",
              "source_type": "admin",
              "created_at": "2025-12-05T11:09:29.544560+05:00"
            }
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await restApiService.getThumbnails(
          authToken: authToken,
        );

        // Assert
        expect(result, isA<List<Thumbnail>>());
        expect(result.length, 1);
        expect(result[0].entityType, 'nomenklatura');
        expect(result[0].code1c, '00-00001559');
        expect(result[0].entityName, 'Test Product');

        verify(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).called(1);
      });

      test('returns empty list when API returns empty array', () async {
        // Arrange
        final mockResponse = Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await restApiService.getThumbnails(
          authToken: authToken,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('throws exception on API error', () async {
        // Arrange
        when(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
          ),
          type: DioExceptionType.badResponse,
        ));

        // Act & Assert
        expect(
          () => restApiService.getThumbnails(
            authToken: authToken,
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('handles network timeout', () async {
        // Arrange
        when(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => restApiService.getThumbnails(
            authToken: authToken,
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('testApiConnectivity', () {
      test('returns true when API is accessible', () async {
        // Arrange
        final mockResponse = Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await restApiService.testApiConnectivity(
          authToken: authToken,
        );

        // Assert
        expect(result, isTrue);
      });

      test('returns false when API is not accessible', () async {
        // Arrange
        when(mockDio.get(
          '$hardcodedUrl/api/v1/thumbnails',
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/thumbnails'),
          type: DioExceptionType.connectionError,
        ));

        // Act
        final result = await restApiService.testApiConnectivity(
          authToken: authToken,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('getApiHealth', () {
      test('returns healthy status on successful response', () async {
        // Arrange
        final mockResponse = Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/health'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/health',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await restApiService.getApiHealth(
          baseUrl: hardcodedUrl,
        );

        // Assert
        expect(result['status'], 'healthy');
        expect(result['statusCode'], 200);
        expect(result.containsKey('responseTime'), isTrue);
      });

      test('returns unhealthy status on error', () async {
        // Arrange
        when(mockDio.get(
          '$hardcodedUrl/api/health',
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/health'),
          type: DioExceptionType.connectionError,
        ));

        // Act
        final result = await restApiService.getApiHealth(
          baseUrl: hardcodedUrl,
        );

        // Assert
        expect(result['status'], 'unhealthy');
        expect(result.containsKey('error'), isTrue);
        expect(result.containsKey('timestamp'), isTrue);
      });
    });
  });
}