import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/util/format_time_ago.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';

import 'balance_status_theme.dart';

/// Bottom sheet opened by tapping a [BalanceStatusIndicator]. Shows the
/// numeric balance, the project debt limit and the age of the cached
/// snapshot so the agent understands *why* a customer is yellow / red.
///
/// Has one optional action — **Refresh** — which calls
/// [ClientBalanceService.fetchClientBalance] with `forceRefresh: true`.
/// On success the [CustomerBalanceStatusCache] receives a push update via
/// `onBalanceUpdated`, this sheet's [ListenableBuilder] picks it up and
/// re-renders with the fresh data. The button is hidden when [code1c] is
/// empty (older callers that don't pass it yet).
///
/// Sheet stays informational — no override action. The block / unblock
/// decision still lives on the visit-step "create order" tile via
/// [DebtBlockedDialog].
class BalanceStatusDetailsSheet extends StatefulWidget {
  final String customerName;
  final CustomerBalanceStatusEntry entry;

  /// INN — used to read the live entry from the cache after a refresh.
  /// Defaults to empty for back-compat; the live-update path requires it.
  final String inn;

  /// `TradingPoint.code1c` — required to fire the REST refresh. When empty
  /// the Refresh button is hidden.
  final String code1c;

  const BalanceStatusDetailsSheet({
    super.key,
    required this.customerName,
    required this.entry,
    this.inn = '',
    this.code1c = '',
  });

  @override
  State<BalanceStatusDetailsSheet> createState() =>
      _BalanceStatusDetailsSheetState();
}

class _BalanceStatusDetailsSheetState extends State<BalanceStatusDetailsSheet> {
  bool _refreshing = false;
  CustomerBalanceStatusCache? _cache;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<CustomerBalanceStatusCache>()) {
      _cache = sl<CustomerBalanceStatusCache>();
    }
  }

  Future<void> _refresh() async {
    if (widget.code1c.isEmpty) return;
    if (!sl.isRegistered<ClientBalanceService>()) return;
    final projectCode = sl.isRegistered<ProjectContext>()
        ? (sl<ProjectContext>().activeProject?.code ?? '')
        : '';
    if (projectCode.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      await sl<ClientBalanceService>().fetchClientBalance(
        code1c: widget.code1c,
        projectCode: projectCode,
        inn: widget.inn.isEmpty ? null : widget.inn,
        forceRefresh: true,
      );
      // Cache push is automatic via ClientBalanceService.saveClientBalance
      // → CustomerBalanceStatusCache.onBalanceUpdated. Our ListenableBuilder
      // will re-render on the next frame.
    } catch (e) {
      // Service now rethrows transport / parsing errors (previously
      // swallowed). The bottom-sheet UX is read-only — log only; the
      // ListenableBuilder keeps showing the previously-cached row.
      if (kDebugMode) {
        // ignore: avoid_print
        print('BalanceStatusDetailsSheet: refresh failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cache ?? ValueNotifier<int>(0),
      builder: (context, _) {
        // Prefer the live cache entry (post-refresh) when available;
        // fall back to the snapshot the caller passed in.
        final liveEntry = (widget.inn.isNotEmpty)
            ? _cache?.entryFor(widget.inn)
            : null;
        final entry = liveEntry ?? widget.entry;
        return _buildSheet(context, entry);
      },
    );
  }

  Widget _buildSheet(BuildContext context, CustomerBalanceStatusEntry entry) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = BalanceStatusTheme.indicatorColorFor(entry.status, cs) ??
        cs.onSurface;

    final balanceText = _formatNumber(entry.balance);
    final limitText =
        entry.limit != null ? _formatNumber(entry.limit!) : '—';
    final canRefresh = widget.code1c.isNotEmpty;

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
                    widget.customerName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _statusHeadline(context, l10n, entry),
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
                formatTimeAgo(entry.lastUpdated!, l10n),
              ),
            ],
            if (canRefresh) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _refreshing ? null : _refresh,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.balanceStatusRefreshButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusHeadline(
    BuildContext context,
    AppLocalizations l10n,
    CustomerBalanceStatusEntry entry,
  ) {
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
}
