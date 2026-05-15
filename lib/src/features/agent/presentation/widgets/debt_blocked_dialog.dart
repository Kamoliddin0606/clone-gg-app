import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_balance_gate.dart';

/// Dialog shown when [OrderBalanceGate.check] returns `blocked = true`.
///
/// Two paths feed it:
/// - Online: the backend returned `blocked = true` (Passport §5).
/// - Offline: local balance > local `UserProject.debtLimit`, **or** there is
///   no cached balance at all (`reason == "no_cached_balance"`).
///
/// The dialog is informational only — there is no override action. If the
/// agent disagrees they must speak to ops; the only way out is to settle the
/// debt or re-fetch online once the customer has paid.
class DebtBlockedDialog extends StatelessWidget {
  final BalanceGateResult gateResult;
  final String customerName;

  const DebtBlockedDialog({
    super.key,
    required this.gateResult,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final balanceText = _formatNumber(gateResult.balance);
    final limitText = gateResult.limit != null
        ? _formatNumber(gateResult.limit!)
        : '—';
    final currency = gateResult.currency;

    final body = <Widget>[
      Text(
        customerName,
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
    ];

    if (gateResult.reason == 'no_cached_balance') {
      body.add(Text(l10n.debtBlockedNoCachedBalance));
    } else if (gateResult.isOffline) {
      body.add(Text(
        l10n.debtBlockedBodyOffline(
          '$balanceText $currency',
          '$limitText $currency',
          _formatAge(gateResult.fetchedAt),
        ),
      ));
    } else {
      body.add(Text(
        l10n.debtBlockedBodyOnline(balanceText, limitText, currency),
      ));
    }

    if (gateResult.isStale) {
      body.add(const SizedBox(height: 8));
      body.add(Text(
        l10n.debtBlockedStaleWarning,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ));
    }

    return AlertDialog(
      icon: Icon(
        Icons.block,
        color: theme.colorScheme.error,
      ),
      title: Text(l10n.debtBlockedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).backButtonTooltip),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(value);
  }

  static String _formatAge(DateTime? fetchedAt) {
    if (fetchedAt == null) return '—';
    final delta = DateTime.now().difference(fetchedAt);
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    return '${delta.inDays}d';
  }
}
