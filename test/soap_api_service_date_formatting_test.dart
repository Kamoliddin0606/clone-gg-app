import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';

// Mock classes for testing
class MockServerService {
  String get baseUrl => 'http://test.com/soap';
}

class MockDio {
  // Mock implementation for testing
}

void main() {
  late SoapApiService soapApiService;

  setUp(() {
    // Create a minimal SoapApiService instance for testing
    // We'll use a simplified approach since the method is private
    final mockDio = MockDio();
    final mockServerService = MockServerService();
    soapApiService = SoapApiService(mockDio as dynamic, mockServerService as dynamic);
  });

  group('Date Formatting Tests', () {
    test('generateSetOrderSoapRequest should format dates as YYYYMMDD', () {
      // Test with specific date: December 3, 2025
      final shippingDate = DateTime(2025, 12, 3, 19, 11, 10, 360, 367);
      final createDate = DateTime(2025, 12, 3, 10, 30, 0);

      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: shippingDate,
        commentSupervisor: 'Test comment',
        commentForwarder: 'Forwarder comment',
        comment: 'Order comment',
        createDate: createDate,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 100.0,
        capacity: 50.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: 'CONTRACT001',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      final soapRequest = soapApiService.generateSetOrderSoapRequest(order);

      // Verify that dates are formatted as YYYYMMDD
      expect(soapRequest.contains('<sam:ShippingDate>20251203</sam:ShippingDate>'), isTrue);
      expect(soapRequest.contains('<sam:CreateDate>20251203</sam:CreateDate>'), isTrue);

      // Verify that old format is not present
      expect(soapRequest.contains('2025-12-03'), isFalse);
    });

    test('generateSetOrderSoapRequest should handle single digit months and days with padding', () {
      // Test with January 5, 2023
      final shippingDate = DateTime(2023, 1, 5);
      final createDate = DateTime(2023, 1, 5);

      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: shippingDate,
        commentSupervisor: '',
        commentForwarder: '',
        comment: '',
        createDate: createDate,
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: '',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      final soapRequest = soapApiService.generateSetOrderSoapRequest(order);

      expect(soapRequest.contains('<sam:ShippingDate>20230105</sam:ShippingDate>'), isTrue);
      expect(soapRequest.contains('<sam:CreateDate>20230105</sam:CreateDate>'), isTrue);
    });

    test('generateSetOrderSoapRequest should handle different years correctly', () {
      // Test with year 1999
      final shippingDate = DateTime(1999, 12, 31);
      final createDate = DateTime(1999, 12, 31);

      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: shippingDate,
        commentSupervisor: '',
        commentForwarder: '',
        comment: '',
        createDate: createDate,
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: '',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      final soapRequest = soapApiService.generateSetOrderSoapRequest(order);

      expect(soapRequest.contains('<sam:ShippingDate>19991231</sam:ShippingDate>'), isTrue);
      expect(soapRequest.contains('<sam:CreateDate>19991231</sam:CreateDate>'), isTrue);
    });

    test('generateSetOrderSoapRequest should handle leap year dates', () {
      // Test with February 29, 2024 (leap year)
      final shippingDate = DateTime(2024, 2, 29);
      final createDate = DateTime(2024, 2, 29);

      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: shippingDate,
        commentSupervisor: '',
        commentForwarder: '',
        comment: '',
        createDate: createDate,
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: '',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      final soapRequest = soapApiService.generateSetOrderSoapRequest(order);

      expect(soapRequest.contains('<sam:ShippingDate>20240229</sam:ShippingDate>'), isTrue);
      expect(soapRequest.contains('<sam:CreateDate>20240229</sam:CreateDate>'), isTrue);
    });

    test('generateSetOrderSoapRequest should ignore time component', () {
      // Test that time component is ignored
      final shippingDate1 = DateTime(2025, 12, 3, 0, 0, 0);
      final createDate1 = DateTime(2025, 12, 3, 0, 0, 0);
      final shippingDate2 = DateTime(2025, 12, 3, 23, 59, 59);
      final createDate2 = DateTime(2025, 12, 3, 23, 59, 59);

      final order1 = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: shippingDate1,
        commentSupervisor: '',
        commentForwarder: '',
        comment: '',
        createDate: createDate1,
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: '',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      final order2 = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: shippingDate2,
        commentSupervisor: '',
        commentForwarder: '',
        comment: '',
        createDate: createDate2,
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: '',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      final soapRequest1 = soapApiService.generateSetOrderSoapRequest(order1);
      final soapRequest2 = soapApiService.generateSetOrderSoapRequest(order2);

      // Both should produce the same date strings
      expect(soapRequest1.contains('<sam:ShippingDate>20251203</sam:ShippingDate>'), isTrue);
      expect(soapRequest1.contains('<sam:CreateDate>20251203</sam:CreateDate>'), isTrue);
      expect(soapRequest2.contains('<sam:ShippingDate>20251203</sam:ShippingDate>'), isTrue);
      expect(soapRequest2.contains('<sam:CreateDate>20251203</sam:CreateDate>'), isTrue);
    });

    test('generateSetOrderSoapRequest should format credit details dates correctly', () {
      // Test credit details date formatting
      final creditDetails = [
        CreditDetail(
          dateOfPayment: DateTime(2025, 12, 15),
          total: 1000.0,
        ),
        CreditDetail(
          dateOfPayment: DateTime(2025, 12, 30),
          total: 2000.0,
        ),
      ];

      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'CASH',
        shippingDate: DateTime(2025, 12, 3),
        commentSupervisor: '',
        commentForwarder: '',
        comment: '',
        createDate: DateTime(2025, 12, 3),
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: true,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        codeContract: '',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: creditDetails,
      );

      final soapRequest = soapApiService.generateSetOrderSoapRequest(order);

      // Verify credit details dates are formatted correctly
      expect(soapRequest.contains('<sam:DateOfPayment>20251215</sam:DateOfPayment>'), isTrue);
      expect(soapRequest.contains('<sam:DateOfPayment>20251230</sam:DateOfPayment>'), isTrue);

      // Verify old format is not present
      expect(soapRequest.contains('2025-12-15'), isFalse);
      expect(soapRequest.contains('2025-12-30'), isFalse);
    });
  });
}