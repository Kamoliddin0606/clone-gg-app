import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_write_repository.dart';

/// Stub adapter that captures every outbound request and returns a
/// canned response queued by the test. Keeps Dio doing real
/// serialisation / interceptor work but never touches the network.
class _StubAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<ResponseBody Function(RequestOptions)> _handlers =
      <ResponseBody Function(RequestOptions)>[];

  void enqueueJson(int status, Map<String, dynamic> body) {
    _handlers.add((_) => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: <String, List<String>>{
            'content-type': <String>['application/json'],
          },
        ));
  }

  void enqueueRawError(int status, Map<String, dynamic> body) =>
      enqueueJson(status, body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_handlers.isEmpty) {
      return ResponseBody.fromString('', 500);
    }
    final handler = _handlers.removeAt(0);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class _MockTokenService extends Mock implements TokenService {
  @override
  Future<String?> ensureValidV2Token({String? login, String? password}) async =>
      'test-token';
}

Future<CustomerWriteRepository> _buildRepo(_StubAdapter adapter) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferencesService.getInstance();
  final dio = Dio()..httpClientAdapter = adapter;
  return CustomerWriteRepository(
    dio: dio,
    tokenService: _MockTokenService(),
    prefs: prefs,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerWriteRepository.create', () {
    test('POSTs the full 22-field SOAP payload + client_uuid + '
        'idempotency_key + bearer + 6-decimal coords', () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      adapter.enqueueJson(201, <String, dynamic>{
        'id': 'cust-1',
        'code': 'C-001',
        'code_1c': '00-001',
        'status': 'active',
        'name': 'Mahalla',
        'inn': '123',
        'phone': '+998901234567',
        'address': 'Toshkent',
        'latitude': '41.311081',
        'longitude': '69.240562',
        'is_active': true,
      });

      final row = await repo.create(
        name: 'Mahalla',
        tradePointType: 'Grocery store',
        contactPersonPhone: '+998901234567',
        address: 'Toshkent',
        latitude: 41.311081,
        longitude: 69.240562,
        codeUser: 'U-AGENT-042',
        codeRegion: 'TASH',
        inn: '123',
      );

      expect(adapter.requests.length, 1);
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, contains('/api/mobile/v2/customers/'));
      expect(req.headers['Authorization'], 'Bearer test-token');
      expect(req.headers['Content-Type'], contains('application/json'));

      final body = req.data as Map<String, dynamic>;
      // Backend-first inversion: mobile no longer sends `code_1c` —
      // backend allocates it after SOAP setClient.
      expect(body.containsKey('code_1c'), isFalse);
      expect(body['name'], 'Mahalla');
      expect(body['inn'], '123');
      expect(body['trade_point_type'], 'Grocery store');
      expect(body['contact_person_phone'], '+998901234567');
      expect(body['address'], 'Toshkent');
      // address_delivery falls back to address when blank.
      expect(body['address_delivery'], 'Toshkent');
      // responsible_person_phone falls back to contact_person_phone.
      expect(body['responsible_person_phone'], '+998901234567');
      expect(body['code_user'], 'U-AGENT-042');
      expect(body['code_region'], 'TASH');
      // Six-decimal string serialisation.
      expect(body['latitude'], '41.311081');
      expect(body['longitude'], '69.240562');
      // UUID v4 shape — 36 chars with dashes.
      expect((body['client_uuid'] as String).length, 36);
      expect((body['idempotency_key'] as String).length, 36);

      // Local catalog now identifies customers by backend `code`.
      expect(row.id, 'C-001');
      expect(row.code, 'C-001');
      expect(row.code1c, '00-001');
      expect(row.name, 'Mahalla');
    });

    test('parses code into TradingPoint.id and falls back through '
        'code_1c → uuid when missing', () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      // `code` missing → fall back to `code_1c`.
      adapter.enqueueJson(201, <String, dynamic>{
        'id': 'uuid-1',
        'code': '',
        'code_1c': '00-FALLBACK',
        'name': 'NoCode',
        'is_active': true,
      });
      final fallback = await repo.create(
        name: 'NoCode',
        tradePointType: 'Grocery store',
        contactPersonPhone: '+998901234567',
        address: 'Toshkent',
        latitude: 41.0,
        longitude: 69.0,
        codeUser: 'U-1',
        codeRegion: 'TASH',
      );
      expect(fallback.id, '00-FALLBACK');
    });

    test('maps onec_business_error 422 to typed exception with '
        'onec_message in details', () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      adapter.enqueueJson(422, <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'onec_business_error',
          'message': '1C rejected the customer.',
          'details': <String, dynamic>{
            'onec_code': '0',
            'onec_message': 'Контрагент с таким ИНН уже существует',
          },
        },
        'request_id': 'r-1',
      });

      Object? caught;
      try {
        await repo.create(
          name: 'X',
          tradePointType: 'Grocery store',
          contactPersonPhone: '+998901234567',
          address: 'Toshkent',
          latitude: 41.0,
          longitude: 69.0,
          codeUser: 'U-1',
          codeRegion: 'TASH',
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<CustomerWriteException>());
      final ex = caught as CustomerWriteException;
      expect(ex.code, 'onec_business_error');
      expect(ex.statusCode, 422);
      expect(ex.details?['onec_message'],
          'Контрагент с таким ИНН уже существует');
    });

    test('maps onec_transport_error 502 to typed exception', () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      adapter.enqueueJson(502, <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'onec_transport_error',
          'message': 'Upstream 1C base returned an error.',
          'details': <String, dynamic>{},
        },
        'request_id': 'r-2',
      });

      Object? caught;
      try {
        await repo.create(
          name: 'X',
          tradePointType: 'Grocery store',
          contactPersonPhone: '+998901234567',
          address: 'Toshkent',
          latitude: 41.0,
          longitude: 69.0,
          codeUser: 'U-1',
          codeRegion: 'TASH',
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<CustomerWriteException>());
      final ex = caught as CustomerWriteException;
      expect(ex.code, 'onec_transport_error');
      expect(ex.statusCode, 502);
    });
  });

  group('CustomerWriteRepository.updateProfile', () {
    test('sends only populated keys via PATCH', () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      adapter.enqueueJson(200, <String, dynamic>{
        'id': 'cust-7',
        'name': 'New Name',
        'inn': '',
        'phone': '',
        'address': '',
        'latitude': '0',
        'longitude': '0',
        'is_active': true,
      });

      await repo.updateProfile(customerId: 'cust-7', name: 'New Name');

      final req = adapter.requests.single;
      expect(req.method, 'PATCH');
      expect(req.path, endsWith('/api/mobile/v2/customers/cust-7/'));
      final body = req.data as Map<String, dynamic>;
      expect(body, <String, dynamic>{'name': 'New Name'});
      // Coordinates intentionally omitted — separate endpoint.
      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('longitude'), isFalse);
    });
  });

  group('CustomerWriteRepository.updateCoordinates', () {
    test('PATCHes the dedicated coordinates endpoint with 6-decimal '
        'strings', () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      adapter.enqueueJson(200, <String, dynamic>{
        'id': 'cust-9',
        'name': '',
        'latitude': '41.311081',
        'longitude': '69.240562',
        'is_active': true,
      });

      await repo.updateCoordinates(
        customerId: 'cust-9',
        latitude: 41.311081234, // extra precision trimmed to 6 decimals
        longitude: 69.2405627,
      );

      final req = adapter.requests.single;
      expect(req.method, 'PATCH');
      expect(req.path,
          endsWith('/api/mobile/v2/customers/cust-9/coordinates/'));
      final body = req.data as Map<String, dynamic>;
      expect(body['latitude'], '41.311081');
      expect(body['longitude'], '69.240563');
    });

    test('maps customer_cross_org_denied 403 to typed exception',
        () async {
      final adapter = _StubAdapter();
      final repo = await _buildRepo(adapter);
      adapter.enqueueJson(403, <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'customer_cross_org_denied',
          'message': 'Customer belongs to another org.',
          'details': null,
        },
      });

      Object? caught;
      try {
        await repo.updateCoordinates(
          customerId: 'cust-9',
          latitude: 41.0,
          longitude: 69.0,
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<CustomerWriteException>());
      expect((caught as CustomerWriteException).code,
          'customer_cross_org_denied');
      expect(caught.statusCode, 403);
    });
  });
}
