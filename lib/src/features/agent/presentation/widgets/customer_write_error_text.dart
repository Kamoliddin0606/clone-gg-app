import '../../../../../l10n/app_localizations.dart';

/// Map the backend error envelope's `code` field to a localised string
/// for the customer create / edit / coordinates flows. Keep in lock-
/// step with the runbook's error table; unknown codes fall back to a
/// generic "Something went wrong".
String customerWriteErrorText(AppLocalizations l10n, String code) {
  switch (code) {
    case 'invalid_coordinates':
      return l10n.customer_err_invalidCoordinates;
    case 'customer_cross_org_denied':
      return l10n.customer_err_crossOrg;
    case 'customer_idempotency_conflict':
      return l10n.customer_err_idempotencyConflict;
    case 'permission_denied':
      return l10n.customer_err_permissionDenied;
    case 'customer_not_found':
    case 'not_found':
      return l10n.customer_err_notFound;
    case 'network_error':
      return l10n.customer_err_network;
    default:
      return l10n.customer_err_unknown;
  }
}
