import '../../../../../l10n/app_localizations.dart';
import '../../data/repositories/customer_write_repository.dart';

/// Translates a save-location failure into a user-facing message
/// localised for the three supported app locales.
///
/// Special-cased codes (must match the V2 backend's error envelope):
/// - `permission_denied` — user holds the codename in their JWT but
///   the backend's object-level RBAC still rejected the request. Most
///   common cause: the user is not assigned as staff for THIS
///   customer (codename gates the action class; staff assignment
///   gates the per-customer scope). Shown as a clear instruction to
///   contact the supervisor.
/// - `customer_cross_org_denied` — customer belongs to a different
///   organization than the JWT carries; rare in practice but the
///   runbook reserves a distinct code for it.
/// - `customer_not_found` / `not_found` — stale local catalog or
///   customer deleted server-side.
/// - `invalid_coordinates` — lat/lng out of range (we validate
///   client-side but keep the message for safety).
/// - `network_error` — Dio threw before reaching the server.
///
/// Anything else falls back to a generic "Could not save: {detail}".
String coordinatesSaveErrorText(AppLocalizations l10n, Object error) {
  if (error is CustomerWriteException) {
    switch (error.code) {
      case 'permission_denied':
        return l10n.coordinatesSave_err_permission_perCustomer;
      case 'customer_cross_org_denied':
        return l10n.coordinatesSave_err_crossOrg;
      case 'customer_not_found':
      case 'not_found':
        return l10n.coordinatesSave_err_notFound;
      case 'invalid_coordinates':
        return l10n.coordinatesSave_err_invalidCoords;
      case 'network_error':
        return l10n.coordinatesSave_err_network;
      case 'server_error':
        return l10n.coordinatesSave_err_serverError;
      default:
        return l10n.coordinatesSave_err_generic(error.message);
    }
  }
  return l10n.coordinatesSave_err_generic(error.toString());
}
