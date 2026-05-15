import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';

import 'balance_status_theme.dart';

/// Bottom sheet opened by tapping a [BalanceStatusIndicator]. Shows the
/// numeric balance, the project debt limit and the age of the cached
/// snapshot so the agent understands *why* a customer is yellow / red.
///
/// Read-only — no actions. The actual block / unblock decision lives on the
/// "create order" visit step, which surfaces the same data via
/// [DebtBlockedDialog]. Keeping this sheet informational avoids duplicating
/// the gate logic in the UI.
class BalanceStatusDetailsSheet extends StatelessWidget {
  final String customerName;
  final CustomerBalanceStatusEntry entry;

  const BalanceStatusDetailsSheet({
    super.key,
    required this.customerName,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = BalanceStatusTheme.indicatorColorFor(entry.status, cs) ??
        cs.onSurface;

    final balanceText = _formatNumber(entry.balance);
    final limitText =
        entry.limit != null ? _formatNumber(entry.limit!) : '—';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _statusHeadline(context, l10n),
            const SizedBox(height: 16),
            _kvRow(
              context,
              l10n.balanceStatusBalanceLabel,
              '$balanceText ${entry.currency}',
              valueColor: entry.balance > 0 ? cs.error : cs.onSurface,
            ),
            const SizedBox(height: 8),
            _kvRow(
              context,
              l10n.balanceStatusLimitLabel,
              entry.limit == null
                  ? l10n.balanceStatusLimitNone
                  : '$limitText ${entry.currency}',
            ),
            if (entry.lastUpdated != null) ...[
              const SizedBox(height: 8),
              _kvRow(
                context,
                l10n.balanceStatusLastUpdatedLabel,
                _formatAge(entry.lastUpdated!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusHeadline(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color =
        BalanceStatusTheme.indicatorColorFor(entry.status, cs) ?? cs.onSurface;
    final icon = switch (entry.status) {
      CustomerBalanceStatus.debtOverLimit => Icons.error_outline,
      CustomerBalanceStatus.debtUnderLimit => Icons.warning_amber_rounded,
      CustomerBalanceStatus.noDebt => Icons.check_circle_outline,
      CustomerBalanceStatus.unknown => Icons.help_outline,
    };
    final label = switch (entry.status) {
      CustomerBalanceStatus.debtOverLimit =>
        l10n.balanceStatusHeadlineOverLimit,
      CustomerBalanceStatus.debtUnderLimit =>
        l10n.balanceStatusHeadlineUnderLimit,
      CustomerBalanceStatus.noDebt => l10n.balanceStatusHeadlineOk,
      CustomerBalanceStatus.unknown => l10n.balanceStatusHeadlineUnknown,
    };
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _kvRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    return NumberFormat.decimalPattern().format(value);
  }

  static String _formatAge(DateTime fetchedAt) {
    final delta = DateTime.now().difference(fetchedAt);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }
}
