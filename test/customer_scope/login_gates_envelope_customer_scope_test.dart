import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

/// Unit tests for the `customer_scope` + `primary_project_id` fields
/// added to [LoginGatesEnvelope]. Covers the rollout contract from
/// `mobile-customer-scope.md`:
///
///   * Old responses (no `customer_scope` key) default to
///     [CustomerScope.organization] and `customerScopeProvided=false`.
///   * `"project"` switches scope and exposes `primaryProjectId`.
///   * `toJson` round-trips both fields only when explicitly provided.
void main() {
  group('LoginGatesEnvelope customer_scope', () {
    Map<String, dynamic> baseJson({
      Map<String, dynamic>? gatesExtras,
    }) =>
        <String, dynamic>{
          'access': 'access-token',
          'refresh': 'refresh-token',
          'gates': <String, dynamic>{
            'user_active_end': null,
            'license_valid_to': '2030-01-01T00:00:00Z',
            'organization_id': 'org-uuid',
            'server_time': '2026-05-14T10:00:00Z',
            'bypass': false,
            ...?gatesExtras,
          },
        };

    test('defaults to organization scope when field absent', () {
      final envelope = LoginGatesEnvelope.fromJson(baseJson());

      expect(envelope.customerScope, CustomerScope.organization);
      expect(envelope.customerScopeProvided, isFalse);
      expect(envelope.primaryProjectId, isNull);
    });

    test('parses customer_scope=project + primary_project_id', () {
      final json = baseJson(gatesExtras: <String, dynamic>{
        'customer_scope': 'project',
        'primary_project_id': '11111111-2222-3333-4444-555555555555',
      });

      final envelope = LoginGatesEnvelope.fromJson(json);

      expect(envelope.customerScope, CustomerScope.project);
      expect(envelope.customerScopeProvided, isTrue);
      expect(
        envelope.primaryProjectId,
        '11111111-2222-3333-4444-555555555555',
      );
    });

    test('parses customer_scope=organization explicitly', () {
      final json = baseJson(gatesExtras: <String, dynamic>{
        'customer_scope': 'organization',
        'primary_project_id': null,
      });

      final envelope = LoginGatesEnvelope.fromJson(json);

      expect(envelope.customerScope, CustomerScope.organization);
      expect(envelope.customerScopeProvided, isTrue);
      expect(envelope.primaryProjectId, isNull);
    });

    test('unknown customer_scope falls back to organization', () {
      final json = baseJson(gatesExtras: <String, dynamic>{
        'customer_scope': 'galaxy',
      });

      final envelope = LoginGatesEnvelope.fromJson(json);

      // Defensive parse: unknown values must NOT crash the login flow.
      expect(envelope.customerScope, CustomerScope.organization);
    });

    test('empty string primary_project_id is treated as null', () {
      final json = baseJson(gatesExtras: <String, dynamic>{
        'customer_scope': 'project',
        'primary_project_id': '',
      });

      final envelope = LoginGatesEnvelope.fromJson(json);

      expect(envelope.customerScope, CustomerScope.project);
      expect(envelope.primaryProjectId, isNull);
    });

    test('toJson omits customer_scope keys when not provided', () {
      final envelope = LoginGatesEnvelope(
        accessToken: 'a',
        refreshToken: 'r',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: 'org',
        serverTime: _epoch,
        bypass: false,
      );

      final json = envelope.toJson();
      final gates = json['gates'] as Map<String, dynamic>;

      expect(gates.containsKey('customer_scope'), isFalse);
      expect(gates.containsKey('primary_project_id'), isFalse);
    });

    test('toJson serialises customer_scope=project + id when provided',
        () {
      final envelope = LoginGatesEnvelope(
        accessToken: 'a',
        refreshToken: 'r',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: 'org',
        serverTime: _epoch,
        bypass: false,
        customerScope: CustomerScope.project,
        primaryProjectId: 'pid-1',
        customerScopeProvided: true,
      );

      final gates = envelope.toJson()['gates'] as Map<String, dynamic>;

      expect(gates['customer_scope'], 'project');
      expect(gates['primary_project_id'], 'pid-1');
    });

    test('encode + tryDecode round-trip preserves new fields', () {
      final original = LoginGatesEnvelope(
        accessToken: 'a',
        refreshToken: 'r',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: 'org',
        serverTime: _epoch,
        bypass: false,
        customerScope: CustomerScope.project,
        primaryProjectId: 'pid-roundtrip',
        customerScopeProvided: true,
      );

      final restored = LoginGatesEnvelope.tryDecode(original.encode());

      expect(restored, isNotNull);
      expect(restored!.customerScope, CustomerScope.project);
      expect(restored.primaryProjectId, 'pid-roundtrip');
      expect(restored.customerScopeProvided, isTrue);
    });

    test('copyWith preserves untouched customer_scope fields', () {
      final original = LoginGatesEnvelope(
        accessToken: 'a',
        refreshToken: 'r',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: 'org',
        serverTime: _epoch,
        bypass: false,
        customerScope: CustomerScope.project,
        primaryProjectId: 'pid',
        customerScopeProvided: true,
      );

      final copy = original.copyWith(accessToken: 'new-token');

      expect(copy.accessToken, 'new-token');
      expect(copy.customerScope, CustomerScope.project);
      expect(copy.primaryProjectId, 'pid');
      expect(copy.customerScopeProvided, isTrue);
    });
  });
}

final DateTime _epoch = DateTime.utc(2026, 5, 14, 10);
