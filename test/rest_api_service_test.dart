import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';

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

    group('getClientImages', () {
      test('returns list of client images on successful API call', () async {
        // Arrange
        final mockResponse = Response(
          data: [
            {
              "id": 116,
              "client": 31866,
              "image": "http://example.com/original.jpg",
              "category": "",
              "note": "",
              "image_url": "http://example.com/original.jpg",
              "image_sm_url": "http://example.com/sm.jpg",
              "image_md_url": "http://example.com/md.jpg",
              "image_lg_url": "http://example.com/lg.jpg",
              "image_thumbnail_url": "http://example.com/thumb.jpg",
              "image_dimensions": {"width": 720, "height": 1280},
              "is_main": false,
              "status": null,
              "source": null,
              "created_at": "2025-12-17T13:55:24.203699+05:00"
            }
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/v1/client-image',
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await restApiService.getClientImages(
          authToken: authToken,
        );

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result[0]['id'], 116);
        expect(result[0]['client'], 31866);
        expect(result[0]['image_thumbnail_url'], 'http://example.com/thumb.jpg');

        verify(mockDio.get(
          '$hardcodedUrl/api/v1/client-image',
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).called(1);
      });

      test('returns empty list when API returns empty array', () async {
        // Arrange
        final mockResponse = Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/v1/client-image',
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await restApiService.getClientImages(
          authToken: authToken,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('throws exception on API error', () async {
        // Arrange
        when(mockDio.get(
          '$hardcodedUrl/api/v1/client-image',
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
          ),
          type: DioExceptionType.badResponse,
        ));

        // Act & Assert
        expect(
          () => restApiService.getClientImages(
            authToken: authToken,
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('handles network timeout', () async {
        // Arrange
        when(mockDio.get(
          '$hardcodedUrl/api/v1/client-image',
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => restApiService.getClientImages(
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
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
        );

        when(mockDio.get(
          '$hardcodedUrl/api/v1/client-image',
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
          '$hardcodedUrl/api/v1/client-image',
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$hardcodedUrl/api/v1/client-image'),
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