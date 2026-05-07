import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/health_check_service.dart';

void main() {
  group('HealthCheckResult', () {
    test('toString reports ok and latency on success', () {
      const ok = HealthCheckResult(
        ok: true,
        statusCode: 200,
        latency: Duration(milliseconds: 12),
      );
      expect(ok.toString(), contains('ok=true'));
      expect(ok.toString(), contains('status=200'));
      expect(ok.toString(), contains('12ms'));
    });

    test('toString includes the error on failure', () {
      const failed = HealthCheckResult(
        ok: false,
        statusCode: 503,
        errorMessage: 'service unavailable',
      );
      expect(failed.toString(), contains('ok=false'));
      expect(failed.toString(), contains('service unavailable'));
    });

    test('latency is populated even on failure (so dashboards can graph it)',
        () {
      const failed = HealthCheckResult(
        ok: false,
        latency: Duration(milliseconds: 4500),
        errorMessage: 'timeout',
      );
      expect(failed.latency, const Duration(milliseconds: 4500));
    });
  });
}
