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
    soapApiService = SoapApiService(mockDio, mockServerService);

    when(mockServerService.baseUrl).thenReturn('http://test.com/soap');
  });

  group('GetReportByPeriod Tests', () {
    test('Successfully parses report data from XML response', () async {
      const mockXmlResponse = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:GetReportByPeriodResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <BusinessRegionReportRow xmlns="http://www.agents-report.org">
               <Code>00000000713</Code>
               <Name>Мирзо-Улугбекский район-1</Name>
               <AKB>44</AKB>
            </BusinessRegionReportRow>
            <BusinessRegionReportRow xmlns="http://www.agents-report.org">
               <Code>00000000714</Code>
               <Name>Мирзо-Улугбекский район-2</Name>
               <AKB>30</AKB>
            </BusinessRegionReportRow>
            <CountAKB xmlns="http://www.agents-report.org">79</CountAKB>
            <CountOKB xmlns="http://www.agents-report.org">402</CountOKB>
            <Cash xmlns="http://www.agents-report.org">29050010</Cash>
            <Transfer xmlns="http://www.agents-report.org">27082530</Transfer>
            <Sum xmlns="http://www.agents-report.org">56132540</Sum>
            <AKBByCotegoriesRow xmlns="http://www.agents-report.org">
               <Code>00-00000003</Code>
               <Name>DURU SOAP</Name>
               <AKB>56</AKB>
            </AKBByCotegoriesRow>
            <AKBByCotegoriesRow xmlns="http://www.agents-report.org">
               <Code>00-00000033</Code>
               <Name>FAX SOAP</Name>
               <AKB>12</AKB>
            </AKBByCotegoriesRow>
            <CountVisited xmlns="http://www.agents-report.org">93</CountVisited>
            <DateStart xmlns="http://www.agents-report.org">2025-10-01</DateStart>
            <DateEnd xmlns="http://www.agents-report.org">2025-10-09</DateEnd>
         </m:return>
      </m:GetReportByPeriodResponse>
   </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: mockXmlResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
      ));

      final result = await soapApiService.getReportByPeriod(
        userCode: '000000329',
        dateStart: '2025-10-01',
        dateEnd: '2025-10-09',
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('mainReport'), true);
      expect(result.containsKey('businessRegionReports'), true);
      expect(result.containsKey('akbByCategories'), true);

      final mainReport = result['mainReport'];
      expect(mainReport.userCode, '000000329');
      expect(mainReport.dateStart, DateTime(2025, 10, 1));
      expect(mainReport.dateEnd, DateTime(2025, 10, 9));
      expect(mainReport.countAKB, 79);
      expect(mainReport.countOKB, 402);
      expect(mainReport.cash, 29050010.0);
      expect(mainReport.transfer, 27082530.0);
      expect(mainReport.sum, 56132540.0);
      expect(mainReport.countVisited, 93);

      final businessRegionReports = result['businessRegionReports'];
      expect(businessRegionReports.length, 2);
      expect(businessRegionReports[0].code, '00000000713');
      expect(businessRegionReports[0].name, 'Мирзо-Улугбекский район-1');
      expect(businessRegionReports[0].akb, 44);

      final akbByCategories = result['akbByCategories'];
      expect(akbByCategories.length, 2);
      expect(akbByCategories[0].code, '00-00000003');
      expect(akbByCategories[0].name, 'DURU SOAP');
      expect(akbByCategories[0].akb, 56);
    });

    test('Handles empty business region reports', () async {
      const mockXmlResponse = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:GetReportByPeriodResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <CountAKB xmlns="http://www.agents-report.org">0</CountAKB>
            <CountOKB xmlns="http://www.agents-report.org">0</CountOKB>
            <Cash xmlns="http://www.agents-report.org">0</Cash>
            <Transfer xmlns="http://www.agents-report.org">0</Transfer>
            <Sum xmlns="http://www.agents-report.org">0</Sum>
            <CountVisited xmlns="http://www.agents-report.org">0</CountVisited>
            <DateStart xmlns="http://www.agents-report.org">2025-10-01</DateStart>
            <DateEnd xmlns="http://www.agents-report.org">2025-10-09</DateEnd>
         </m:return>
      </m:GetReportByPeriodResponse>
   </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: mockXmlResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
      ));

      final result = await soapApiService.getReportByPeriod(
        userCode: '000000329',
        dateStart: '2025-10-01',
        dateEnd: '2025-10-09',
      );

      expect(result['mainReport'].countAKB, 0);
      expect(result['businessRegionReports'], isEmpty);
      expect(result['akbByCategories'], isEmpty);
    });

    test('Handles network timeout', () async {
      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
        type: DioExceptionType.receiveTimeout,
      ));

      expect(
        () => soapApiService.getReportByPeriod(
          userCode: '000000329',
          dateStart: '2025-10-01',
          dateEnd: '2025-10-09',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Handles invalid XML response', () async {
      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: 'Invalid XML',
        statusCode: 200,
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
      ));

      expect(
        () => soapApiService.getReportByPeriod(
          userCode: '000000329',
          dateStart: '2025-10-01',
          dateEnd: '2025-10-09',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Handles server error response', () async {
      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: '<error>Server Error</error>',
        statusCode: 500,
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
      ));

      expect(
        () => soapApiService.getReportByPeriod(
          userCode: '000000329',
          dateStart: '2025-10-01',
          dateEnd: '2025-10-09',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Handles missing required fields in XML', () async {
      const mockXmlResponse = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:GetReportByPeriodResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <BusinessRegionReportRow xmlns="http://www.agents-report.org">
               <Name>Test Region</Name>
            </BusinessRegionReportRow>
         </m:return>
      </m:GetReportByPeriodResponse>
   </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: mockXmlResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
      ));

      final result = await soapApiService.getReportByPeriod(
        userCode: '000000329',
        dateStart: '2025-10-01',
        dateEnd: '2025-10-09',
      );

      // Should handle missing fields gracefully
      final businessRegionReports = result['businessRegionReports'];
      expect(businessRegionReports[0].code, ''); // Empty string for missing code
      expect(businessRegionReports[0].name, 'Test Region');
      expect(businessRegionReports[0].akb, 0); // Default value for missing AKB
    });

    test('Validates SOAP request format', () async {
      const expectedSoapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
  <soap:Header/>
  <soap:Body>
    <sam:GetReportByPeriod>
      <sam:UserCode>000000329</sam:UserCode>
      <sam:DateStart>2025-10-01</sam:DateStart>
      <sam:DateEnd>2025-10-09</sam:DateEnd>
    </sam:GetReportByPeriod>
  </soap:Body>
</soap:Envelope>
''';

      when(mockDio.post(
        'http://test.com/soap',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: '<valid>response</valid>',
        statusCode: 200,
        requestOptions: RequestOptions(path: 'http://test.com/soap'),
      ));

      await soapApiService.getReportByPeriod(
        userCode: '000000329',
        dateStart: '2025-10-01',
        dateEnd: '2025-10-09',
      );

      verify(mockDio.post(
        'http://test.com/soap',
        data: expectedSoapEnvelope.trim(),
        options: anyNamed('options'),
      )).called(1);
    });
  });
}