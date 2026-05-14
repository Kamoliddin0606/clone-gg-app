import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/customer_scope_error_handler.dart';

/// Unit tests for [CustomerScopeErrorHandler.handles] — the inexpensive
/// pure-function gate that lets every error site decide whether to
/// delegate to the centralised mapper or fall back to its existing
/// error UI. The async `handle()` is intentionally not covered here
/// because it depends on a live BuildContext + Navigator; it's
/// exercised manually as part of the smoke test plan.
void main() {
  group('CustomerScopeErrorHandler.handles', () {
    test('returns true for every code from the rollout matrix', () {
      const codes = <String>[
        'customer_project_required',
        'customer_project_not_allowed',
        'customer_code_duplicate_in_org',
        'customer_code_duplicate_in_project',
        'customer_cross_project_denied',
      ];
      for (final code in codes) {
        expect(
          CustomerScopeErrorHandler.handles(code),
          isTrue,
          reason: 'expected $code to be routed through the handler',
        );
      }
    });

    test('returns false for unrelated backend codes', () {
      const unrelated = <String>[
        '',
        'permission_denied',
        'customer_not_found',
        'onec_business_error',
        'onec_transport_error',
        'network_error',
        'server_error',
        'http_404',
        'authentication_failed',
      ];
      for (final code in unrelated) {
        expect(
          CustomerScopeErrorHandler.handles(code),
          isFalse,
          reason: 'expected $code to fall through to legacy UI',
        );
      }
    });

    test('is case-sensitive — preserves backend envelope contract', () {
      expect(
        CustomerScopeErrorHandler.handles('CUSTOMER_PROJECT_REQUIRED'),
        isFalse,
      );
      expect(
        CustomerScopeErrorHandler.handles('Customer_Project_Required'),
        isFalse,
      );
    });
  });
}
