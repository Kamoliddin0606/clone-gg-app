import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/util/format_time_ago.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/balance_gate_event_logger.dart';
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
///
/// Fires a `customer.balance.blocked` analytics event in `initState` (once
/// per show) via [BalanceGateEventLogger]. Caller passes [code1c] and
/// [projectCode] so the event payload is fully populated; both default to
/// empty strings when the surface doesn't have them (e.g. legacy callers
/// that haven't been updated yet) — the event still fires, just with
/// reduced fidelity.
class DebtBlockedDialog extends StatefulWidget {
  final BalanceGateResult gateResult;
  final String customerName;
  final String code1c;
  final String projectCode;
  final String trigger;

  const DebtBlockedDialog({
    super.key,
    required this.gateResult,
    required this.customerName,
    this.code1c = '',
    this.projectCode = '',
    this.trigger = 'unknown',
  });

  @override
  State<DebtBlockedDialog> createState() => _DebtBlockedDialogState();
}

class _DebtBlockedDialogState extends State<DebtBlockedDialog> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget analytics; never blocks the UI. Wrapped in
    // try/catch by the logger itself.
    if (sl.isRegistered<BalanceGateEventLogger>()) {
      // ignore: discarded_futures
      sl<BalanceGateEventLogger>().logBlocked(
        result: widget.gateResult,
        code1c: widget.code1c,
        projectCode: widget.projectCode,
        trigger: widget.trigger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final balanceText = _formatNumber(widget.gateResult.balance);
    final limitText = widget.gateResult.limit != null
        ? _formatNumber(widget.gateResult.limit!)
        : '—';
    final currency = widget.gateResult.currency;

    final body = <Widget>[
      Text(
        widget.customerName,
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
    ];

    if (widget.gateResult.reason == 'no_cached_balance') {
      body.add(Text(l10n.debtBlockedNoCachedBalance));
    } else if (widget.gateResult.isOffline) {
      body.add(Text(
        l10n.debtBlockedBodyOffline(
          '$balanceText $currency',
          '$limitText $currency',
          widget.gateResult.fetchedAt == null
              ? '—'
              : formatTimeAgo(widget.gateResult.fetchedAt!, l10n),
        ),
      ));
    } else {
      body.add(Text(
        l10n.debtBlockedBodyOnline(balanceText, limitText, currency),
      ));
    }

    if (widget.gateResult.isStale) {
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
}
