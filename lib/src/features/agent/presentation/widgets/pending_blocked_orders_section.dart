import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';

/// Surfaces the locally-blocked CreateOrder rows for a given customer
/// inside [ClientDetailSheet] (M12 P0.3).
///
/// Source of truth: `create_order` table rows where
/// `is_synced = 0 AND sync_error = 'debt_limit_exceeded' AND
/// code_client = <this customer>`. Written by
/// [DataSyncService.syncCreateOrders] when the M11 pre-submit recheck
/// refuses to push an order.
///
/// Each row exposes a "Retry" button that re-runs `syncCreateOrders()`
/// (which re-evaluates the gate with `forceFresh: true`). Single-customer
/// flush isn't a separate API — flushing all unsynced rows is cheap and
/// keeps the surface small. Returns [SizedBox.shrink] when there are no
/// blocked orders so the section disappears entirely on the happy path.
class PendingBlockedOrdersSection extends StatefulWidget {
  /// `TradingPoint.id` — matches `CreateOrder.codeClient`.
  final String clientCode;

  const PendingBlockedOrdersSection({
    super.key,
    required this.clientCode,
  });

  @override
  State<PendingBlockedOrdersSection> createState() =>
      _PendingBlockedOrdersSectionState();
}

class _PendingBlockedOrdersSectionState
    extends State<PendingBlockedOrdersSection> {
  late Future<List<CreateOrder>> _future;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CreateOrder>> _load() async {
    final db = sl<ApiDatabaseService>();
    final all = await db.getUnsyncedCreateOrders();
    return all
        .where((o) =>
            o.codeClient == widget.clientCode &&
            o.syncError == 'debt_limit_exceeded')
        .toList();
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await sl<DataSyncService>().syncCreateOrders();
    } finally {
      if (mounted) {
        setState(() {
          _retrying = false;
          _future = _load();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CreateOrder>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final orders = snapshot.data ?? const <CreateOrder>[];
        if (orders.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final l10n = AppLocalizations.of(context)!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.error.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, color: cs.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.pendingBlockedOrdersTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...orders.map((order) => _OrderRow(
                    order: order,
                    busy: _retrying,
                    onRetry: _retry,
                    l10n: l10n,
                    theme: theme,
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  final CreateOrder order;
  final bool busy;
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _OrderRow({
    required this.order,
    required this.busy,
    required this.onRetry,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_Hm();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.orderBlockedByDebtBadge,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.pendingBlockedOrdersCreatedAt(
                    dateFmt.format(order.createDate),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: busy ? null : onRetry,
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: Text(l10n.retrySyncButton),
          ),
        ],
      ),
    );
  }
}
