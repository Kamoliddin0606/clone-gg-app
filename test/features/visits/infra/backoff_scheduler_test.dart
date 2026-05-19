import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/backoff_scheduler.dart';

void main() {
  group('BackoffScheduler', () {
    test('honors the documented base sequence at attempts 1..7', () {
      // Deterministic random => nextDouble returns 0.0 => jitter = -10%
      // (the formula multiplies the base by `1 + (nextDouble * 0.2 - 0.1)`).
      // We assert the lower-bound (90% of the base) — the upper bound test
      // below covers the jitter spread.
      final scheduler = BackoffScheduler(random: _ZeroRandom());
      final baseSeconds = [2, 4, 8, 16, 32, 64, 128];
      for (var i = 0; i < baseSeconds.length; i++) {
        final attempts = i + 1;
        final delay = scheduler.compute(attempts);
        final expectedMs = (baseSeconds[i] * 1000 * 0.9).round();
        expect(delay.inMilliseconds, expectedMs,
            reason: 'attempt $attempts should equal base × 0.9');
      }
    });

    test('caps at 300s past the table', () {
      final scheduler = BackoffScheduler(random: _ZeroRandom());
      final delay = scheduler.compute(20);
      // 300s ± 10%
      expect(delay.inSeconds, inInclusiveRange(270, 330));
    });

    test('jitter stays within ±10% of the base', () {
      final scheduler = BackoffScheduler(random: Random(42));
      for (var i = 0; i < 50; i++) {
        final delay = scheduler.compute(3); // base = 8s
        expect(delay.inMilliseconds,
            inInclusiveRange((8000 * 0.9).round(), (8000 * 1.1).round()));
      }
    });
  });
}

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;
}
