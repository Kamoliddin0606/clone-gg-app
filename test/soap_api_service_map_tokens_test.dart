import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';

// Mock classes
class MockDio extends Mock implements Dio {}
class MockServerService extends Mock implements ServerService {}

void main() {
  late SoapApiService soapApiService;
  late MockDio mockDio;
  late MockServerService mockServerService;

  setUp(() {
    mockDio = MockDio();
    mockServerService = MockServerService();

    // Mock the Dio options to avoid null issues
    when(mockDio.options).thenReturn(BaseOptions());

    soapApiService = SoapApiService(mockDio, mockServerService);
  });

  group('getMapTokens', () {
    const userCode = '000000109';
    const baseUrl = 'http://test.server.com/api';

    setUp(() {
      when(mockServerService.baseUrl).thenReturn(baseUrl);
    });

    test('should return map tokens when server returns valid response', () async {
      // Arrange
      const soapResponse = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <m:getMapTokensResponse xmlns:m="http://www.sample-package.org">
      <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <m:yandexToken>6381d1cf-a0d8-4b88-8c8f-60951f817884</m:yandexToken>
        <m:googleToken>AIzaSyDummyGoogleToken123456789</m:googleToken>
      </m:return>
    </m:getMapTokensResponse>
  </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: baseUrl),
      ));

      // Act
      final result = await soapApiService.getMapTokens(userCode: userCode);

      // Assert
      expect(result, isA<Map<String, String>>());
      expect(result['yandexToken'], '6381d1cf-a0d8-4b88-8c8f-60951f817884');
      expect(result['googleToken'], 'AIzaSyDummyGoogleToken123456789');

      verify(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should return empty strings when tokens are not set on server', () async {
      // Arrange
      const soapResponse = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <m:getMapTokensResponse xmlns:m="http://www.sample-package.org">
      <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <m:yandexToken/>
        <m:googleToken/>
      </m:return>
    </m:getMapTokensResponse>
  </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: baseUrl),
      ));

      // Act
      final result = await soapApiService.getMapTokens(userCode: userCode);

      // Assert
      expect(result, isA<Map<String, String>>());
      expect(result['yandexToken'], '');
      expect(result['googleToken'], '');
    });

    test('should return only yandex token when google token is empty', () async {
      // Arrange
      const soapResponse = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <m:getMapTokensResponse xmlns:m="http://www.sample-package.org">
      <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <m:yandexToken>6381d1cf-a0d8-4b88-8c8f-60951f817884</m:yandexToken>
        <m:googleToken/>
      </m:return>
    </m:getMapTokensResponse>
  </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: baseUrl),
      ));

      // Act
      final result = await soapApiService.getMapTokens(userCode: userCode);

      // Assert
      expect(result['yandexToken'], '6381d1cf-a0d8-4b88-8c8f-60951f817884');
      expect(result['googleToken'], '');
    });

    test('should throw exception when network request fails', () async {
      // Arrange
      when(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: baseUrl),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act & Assert
      expect(
        () => soapApiService.getMapTokens(userCode: userCode),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when XML parsing fails', () async {
      // Arrange
      const invalidXmlResponse = 'Invalid XML Response';

      when(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: invalidXmlResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: baseUrl),
      ));

      // Act & Assert
      expect(
        () => soapApiService.getMapTokens(userCode: userCode),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle server error responses gracefully', () async {
      // Arrange
      when(mockDio.post(
        baseUrl,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: baseUrl),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: baseUrl),
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act & Assert
      expect(
        () => soapApiService.getMapTokens(userCode: userCode),
        throwsA(isA<Exception>()),
      );
    });
  });
}