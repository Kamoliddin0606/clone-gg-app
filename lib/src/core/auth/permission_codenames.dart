/// Dotted Django-style permission codenames the backend ships in
/// `gates.permissions`. The mobile app uses them to gate UI actions
/// (FAB, action sheet items, etc.) so the user never sees a button
/// they cannot use; backend's 403 stays the source of truth.
///
/// IMPORTANT: keep these strings in lock-step with the backend's
/// `customers.add_customer_photo` etc. — the same literals appear in
/// `gates.permissions` and any change must land in both repos.
class PermissionCodenames {
  PermissionCodenames._();

  // --- Customer profile / coordinates (staff-permissions runbook) -----------

  static const String customerAdd = 'customers.add_customer';
  static const String customerChange = 'customers.change_customer';
  static const String customerChangeCoordinates =
      'customers.change_customer_coordinates';

  // --- Customer photos (customer-photos runbook) ----------------------------

  static const String customerChangePhoto = 'customers.change_customer_photo';
  static const String customerAddPhoto = 'customers.add_customer_photo';
  static const String customerDeletePhoto = 'customers.delete_customer_photo';
  static const String customerReplacePhoto =
      'customers.replace_customer_photo';

  /// All four customer-photo codenames — used to decide whether to
  /// show any photo-related affordance at all (any-of-four gate).
  static const List<String> customerPhotoAny = <String>[
    customerAddPhoto,
    customerChangePhoto,
    customerDeletePhoto,
    customerReplacePhoto,
  ];

  /// Backend gate for **reading** a customer's photos — the
  /// `GET …/photos/` (list) and `GET …/photos/{id}/` (retrieve)
  /// endpoints. The V2 photo viewset binds reads to
  /// `HasRolePermission('customers.change_customer_photo')`; there is
  /// **no** separate `view_customer_photo` codename (the backend's
  /// Customer model Meta only defines add / change / delete / replace).
  ///
  /// The gallery page and the inline carousel both `list()` the moment
  /// they open, so their entry-points must gate on THIS — not on
  /// "any of the four". Gating on any-of-four lets a user who holds
  /// only add / delete / replace open a gallery that 403s the instant
  /// it loads (and whose post-mutation reload would 403 too).
  static const String customerViewPhotoGate = customerChangePhoto;

  /// Codenames owned by [BackendPermissionStore]. The SOAP settings
  /// pipeline must never write any of these strings into its local
  /// store — that is the entire point of the carve-out. Kept here as
  /// the single source of truth so the SOAP filter and the store are
  /// guaranteed to agree.
  static const Set<String> owned = <String>{
    customerAdd,
    customerChange,
    customerChangeCoordinates,
    customerChangePhoto,
    customerAddPhoto,
    customerDeletePhoto,
    customerReplacePhoto,
  };
}

/// Defensive default while backend exposure is rolling out: when the
/// `permissions` list is empty (i.e. backend has not shipped the
/// codename block yet) we treat the user as having every codename so
/// existing roles do not lose access. Backend's 403 still gates the
/// actual mutation. Once staging confirms the list is populated for
/// every login, flip [_optimistic] to `false` to switch to a
/// pessimistic gate (hide unless explicitly granted).
extension PermissionCheck on List<String> {
  /// Flip to `false` after staging confirms backend exposure is live.
  /// The PR that flips this should call out the change in its
  /// description so reviewers know the gate semantics changed.
  static const bool _optimistic = true;

  /// True when [codename] is granted to this user.
  ///
  /// Returns `true` for an empty list while [_optimistic] is on so the
  /// roll-out window does not regress existing users; once flipped to
  /// `false`, an empty list means "no access".
  bool has(String codename) {
    if (isEmpty && _optimistic) return true;
    return contains(codename);
  }

  /// True when at least one of [codenames] is granted.
  bool hasAny(Iterable<String> codenames) {
    if (isEmpty && _optimistic) return true;
    for (final c in codenames) {
      if (contains(c)) return true;
    }
    return false;
  }
}
