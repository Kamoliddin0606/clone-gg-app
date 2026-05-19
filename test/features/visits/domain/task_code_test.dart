import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/task_code.dart';

void main() {
  group('TaskCode', () {
    test('round-trips known wire codes', () {
      for (final code in TaskCode.values) {
        final round = TaskCode.fromCode(code.code);
        expect(round, code, reason: 'fromCode(${code.code}) should round-trip');
      }
    });

    test('returns null for unknown wire codes', () {
      expect(TaskCode.fromCode('NOT_A_REAL_TASK'), isNull);
      expect(TaskCode.fromCode(''), isNull);
    });
  });
}
