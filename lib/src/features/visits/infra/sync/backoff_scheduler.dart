import 'dart:math';

/// Exponential backoff with ±10% jitter, capped at 300s.
///
/// Sequence (no jitter): 2s, 4s, 8s, 16s, 32s, 64s, 128s, 300s, 300s, 300s.
/// Index is `attempts - 1` (the very first retry uses index 0). Beyond the
/// table we keep the 300s cap forever — the dispatcher itself stops trying
/// after `maxAttempts`, so this just guards against off-by-one bugs.
class BackoffScheduler {
  BackoffScheduler({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _table = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 32),
    Duration(seconds: 64),
    Duration(seconds: 128),
    Duration(seconds: 300),
    Duration(seconds: 300),
    Duration(seconds: 300),
  ];

  Duration compute(int attempts) {
    final idx = (attempts - 1).clamp(0, _table.length - 1);
    final base = _table[idx];
    final jitter = (_random.nextDouble() * 0.2) - 0.1; // ±10%
    final ms = (base.inMilliseconds * (1 + jitter)).round();
    return Duration(milliseconds: ms);
  }
}
