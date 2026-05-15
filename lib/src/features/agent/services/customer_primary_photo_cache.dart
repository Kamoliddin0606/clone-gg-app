import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/images/unified_image.dart';
import '../data/repositories/customer_photo_repository.dart';

/// In-memory de-duped cache of "primary photo per customer" lookups.
///
/// Rendered grids/lists can mount many [CustomerPrimaryThumbnail]
/// widgets at once (50–100 tiles is normal). Without coordination
/// each tile would fire its own `GET /api/mobile/v2/customers/{id}/photos/`
/// during `initState`. The repository's ETag short-circuits the body,
/// but the round-trip still costs latency. This singleton:
///
///   1. Caches the resolved primary so subsequent mounts hit the map
///      synchronously.
///   2. De-dupes concurrent `getPrimary` calls for the same customer
///      via the `_inflight` futures map.
///   3. Surfaces an [invalidate] hook for mutation flows (called from
///      [CustomerPhotoChangeNotifier] subscribers) so the next
///      `getPrimary` re-fetches.
///
/// `null` in `_byCustomerId` means *"loaded, no photos for this
/// customer"* — distinct from "not yet loaded" (key absent). This
/// distinction is what lets the thumbnail widget skip the loading
/// shimmer on a known-empty customer.
class CustomerPrimaryPhotoCache extends ChangeNotifier {
  final CustomerPhotoRepository _repo;

  final Map<String, UnifiedImage?> _byCustomerId = {};
  final Map<String, Future<UnifiedImage?>> _inflight = {};

  CustomerPrimaryPhotoCache({required CustomerPhotoRepository repo})
      : _repo = repo;

  /// Synchronous peek. Returns `null` if the customer has no primary
  /// photo OR if the customer hasn't been loaded yet — use
  /// [hasResolved] to distinguish the two when needed.
  UnifiedImage? peek(String customerId) => _byCustomerId[customerId];

  /// True when [getPrimary] has resolved for this customer at least
  /// once (regardless of whether photos exist).
  bool hasResolved(String customerId) =>
      _byCustomerId.containsKey(customerId);

  Future<UnifiedImage?> getPrimary(String customerId) {
    if (_byCustomerId.containsKey(customerId)) {
      return Future<UnifiedImage?>.value(_byCustomerId[customerId]);
    }
    return _inflight.putIfAbsent(customerId, () async {
      try {
        final list = await _repo.list(
          customerId,
          ordering: '-is_primary,order',
        );
        final UnifiedImage? primary = list.isEmpty
            ? null
            : list.firstWhere(
                (p) => p.isPrimary,
                orElse: () => list.first,
              );
        _byCustomerId[customerId] = primary;
        notifyListeners();
        return primary;
      } catch (_) {
        // Don't poison the cache on transient failures — let the next
        // call retry. We still notify so any SHIMMER state can flip
        // to errorBuilder via the subscriber's setState.
        notifyListeners();
        rethrow;
      } finally {
        _inflight.remove(customerId);
      }
    });
  }

  /// Drop the cached entry for [customerId]. The next [getPrimary]
  /// will re-fetch from the repository (which itself respects ETag).
  void invalidate(String customerId) {
    final removed = _byCustomerId.remove(customerId) != null;
    if (removed) notifyListeners();
  }

  /// Test/debug helper — clears every customer.
  @visibleForTesting
  void clear() {
    if (_byCustomerId.isEmpty) return;
    _byCustomerId.clear();
    notifyListeners();
  }
}
