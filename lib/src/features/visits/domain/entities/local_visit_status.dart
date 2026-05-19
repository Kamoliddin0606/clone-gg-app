/// Lifecycle of a visit as tracked in the local `visits_v2` table.
///
/// Distinct from the server-side `VisitStatus` enum because the mobile
/// app needs intermediate states the backend never sees (in-flight session,
/// finished-but-not-yet-synced).
enum LocalVisitStatus {
  /// User has tapped "start visit"; tasks may still be in progress.
  inProgress('in_progress'),

  /// User tapped "finish"; envelope is queued in `outbox` but not yet ACKed.
  finishedLocal('finished_local'),

  /// Server returned 2xx for the finish envelope. Local copy is now read-only
  /// reference data.
  synced('synced'),

  /// User cancelled the visit before tapping finish.
  cancelled('cancelled'),

  /// Server returned a terminal error (400/422). Sits in dead-letter UI until
  /// the user manually discards or retries after fixing the data.
  rejected('rejected');

  const LocalVisitStatus(this.wire);
  final String wire;

  static LocalVisitStatus fromWire(String wire) {
    for (final value in values) {
      if (value.wire == wire) return value;
    }
    throw ArgumentError('Unknown LocalVisitStatus wire value: $wire');
  }
}
