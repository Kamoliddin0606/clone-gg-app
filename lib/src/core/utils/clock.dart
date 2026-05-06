/// Thin abstraction over [DateTime.now] so business-logic classes can
/// receive an injectable clock and tests can advance time deterministically.
///
/// Always returns UTC to avoid local-zone surprises when comparing against
/// server timestamps (`gates.server_time`, `license_valid_to`, etc.).
abstract class Clock {
  const Clock();

  /// Current UTC time. Replaces direct calls to `DateTime.now().toUtc()`
  /// in business code.
  DateTime nowUtc();
}

/// Default production clock — delegates to the system clock.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
