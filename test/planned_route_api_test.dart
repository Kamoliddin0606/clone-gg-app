import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';

// Generate mocks
@GenerateMocks([Dio, ServerService])
import 'planned_route_api_test.mocks.dart';

void main() {
  late SoapApiService soapApiService;
  late MockDio mockDio;
  late MockServerService mockServerService;

  setUp(() {
    mockDio = MockDio();
    mockServerService = MockServerService();
    soapApiService = SoapApiService(mockDio, mockServerService);

    // Mock the baseUrl getter
    when(mockServerService.baseUrl).thenReturn('http://test.com/soap');
  });

  group('SoapApiService.getPlannedRouteList Tests', () {
    test('should return empty list when response has no return element', () async {
      // Arrange
      const userCode = '000000109';
      final soapResponse = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:getPlannedRouteListResponse xmlns:m="http://www.sample-package.org">
      </m:getPlannedRouteListResponse>
   </soap:Body>
</soap:Envelope>''';

      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Act
      final result = await soapApiService.getPlannedRouteList(userCode: userCode);

      // Assert
      expect(result, isEmpty);
      verify(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options'))).called(1);
    });

    test('should parse single route correctly', () async {
      // Arrange
      const userCode = '000000109';
      final soapResponse = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:getPlannedRouteListResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <m:row>
               <m:codeWeekday>1</m:codeWeekday>
               <m:WeekDay>Понедельник</m:WeekDay>
               <m:CodeClient>00-00024433</m:CodeClient>
               <m:ClientName>NOMOZOVA GULSHOD TOSHPULATOVNA YaTT</m:ClientName>
            </m:row>
         </m:return>
      </m:getPlannedRouteListResponse>
   </soap:Body>
</soap:Envelope>''';

      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Act
      final result = await soapApiService.getPlannedRouteList(userCode: userCode);

      // Assert
      expect(result, hasLength(1));
      expect(result[0]['codeWeekday'], 1);
      expect(result[0]['weekDay'], 'Понедельник');
      expect(result[0]['codeClient'], '00-00024433');
      expect(result[0]['clientName'], 'NOMOZOVA GULSHOD TOSHPULATOVNA YaTT');
    });

    test('should parse multiple routes correctly', () async {
      // Arrange
      const userCode = '000000109';
      final soapResponse = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:getPlannedRouteListResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <m:row>
               <m:codeWeekday>1</m:codeWeekday>
               <m:WeekDay>Понедельник</m:WeekDay>
               <m:CodeClient>00-00024433</m:CodeClient>
               <m:ClientName>NOMOZOVA GULSHOD TOSHPULATOVNA YaTT</m:ClientName>
            </m:row>
            <m:row>
               <m:codeWeekday>2</m:codeWeekday>
               <m:WeekDay>Вторник</m:WeekDay>
               <m:CodeClient>00-00032102</m:CodeClient>
               <m:ClientName>SOBIRJONOV ZIKRILLA TOHIRJON</m:ClientName>
            </m:row>
         </m:return>
      </m:getPlannedRouteListResponse>
   </soap:Body>
</soap:Envelope>''';

      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Act
      final result = await soapApiService.getPlannedRouteList(userCode: userCode);

      // Assert
      expect(result, hasLength(2));
      expect(result[0]['codeWeekday'], 1);
      expect(result[0]['weekDay'], 'Понедельник');
      expect(result[1]['codeWeekday'], 2);
      expect(result[1]['weekDay'], 'Вторник');
    });

    test('should handle SOAP fault response', () async {
      // Arrange
      const userCode = '000000109';

      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          data: 'SOAP Fault',
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act & Assert
      expect(
        () => soapApiService.getPlannedRouteList(userCode: userCode),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle network timeout', () async {
      // Arrange
      const userCode = '000000109';

      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act & Assert
      expect(
        () => soapApiService.getPlannedRouteList(userCode: userCode),
        throwsA(isA<Exception>()),
      );
    });

    test('should send correct SOAP request format', () async {
      // Arrange
      const userCode = '000000109';
      final soapResponse = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:getPlannedRouteListResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
      </m:getPlannedRouteListResponse>
   </soap:Body>
</soap:Envelope>''';

      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: soapResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Act
      await soapApiService.getPlannedRouteList(userCode: userCode);

      // Assert
      final captured = verify(mockDio.post(
        captureAny,
        data: captureAnyNamed('data'),
        options: anyNamed('options'),
      )).captured;

      final requestData = captured[1] as String;
      expect(requestData, contains('<sam:getPlannedRouteList>'));
      expect(requestData, contains('<sam:CodeUser>$userCode</sam:CodeUser>'));
      expect(requestData, contains('</sam:getPlannedRouteList>'));
    });
  });
}