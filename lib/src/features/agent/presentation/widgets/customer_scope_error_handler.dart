import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';

/// Centralised mapping of the 5 new error codes from the
/// `customer_scope` rollout to a consistent UI reaction.
///
/// Returns `true` when the caller should retry the last action — only
/// `customer_project_required` triggers a retry after the user picks a
/// project. The other codes are terminal toast / silent self-heal flows.
class CustomerScopeErrorHandler {
  CustomerScopeErrorHandler._();

  /// Handle a backend error code in the UI. Safe to call with any
  /// code — unknown codes fall through to a no-op (caller falls back
  /// to its existing snackbar / dialog).
  static Future<bool> handle(
    BuildContext context,
    String code, {
    Map<String, dynamic>? details,
  }) async {
    final l10n = AppLocalizations.of(context);
    switch (code) {
      case 'customer_project_required':
        await Navigator.of(context, rootNavigator: true).pushNamed(
          AppRouter.projectPickerRoute,
          arguments: const <String, dynamic>{'mandatory': true},
        );
        return true;
      case 'customer_project_not_allowed':
        _toast(context, l10n?.customerScopeMismatchToast ??
            'Configuration fixed. Retrying...');
        return true;
      case 'customer_code_duplicate_in_org':
        _toast(context,
            l10n?.customerCodeDuplicateToast ?? 'Customer already exists');
        return false;
      case 'customer_code_duplicate_in_project':
        _toast(
            context,
            l10n?.customerCodeDuplicateToastProject ??
                'Customer already exists in this project');
        return false;
      case 'customer_cross_project_denied':
        _toast(context,
            l10n?.customerNotFoundToast ?? 'Customer not found');
        Navigator.of(context).maybePop();
        return false;
      default:
        return false;
    }
  }

  /// Returns `true` when [code] is one of the 5 customer-scope codes —
  /// callers can use this to decide whether to delegate to [handle] or
  /// fall back to their generic error UI.
  static bool handles(String code) {
    switch (code) {
      case 'customer_project_required':
      case 'customer_project_not_allowed':
      case 'customer_code_duplicate_in_org':
      case 'customer_code_duplicate_in_project':
      case 'customer_cross_project_denied':
        return true;
      default:
        return false;
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
