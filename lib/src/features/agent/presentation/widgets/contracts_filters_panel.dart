import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../shared/formatters.dart';
import 'contract_models.dart';
import '../../../../features/agent/data/models/trading_point.dart';

typedef ContractsFilterOnChange = void Function(ContractsFilterState state);

typedef SimplePicker = Future<void> Function();

class ContractsFiltersPanel extends StatelessWidget {
  final ContractsFilterState state;
  final List<TradingPoint> availableTradingPoints;
  final ContractsFilterOnChange onChange;
  final SimplePicker onPickDateRange;
  final VoidCallback onClearDateRange;

  const ContractsFiltersPanel({
    super.key,
    required this.state,
    required this.availableTradingPoints,
    required this.onChange,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trading Points filter
          Text(
            l10n?.tradingPointsLabel ?? 'Trading points',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (availableTradingPoints.isEmpty)
            Text(
              l10n?.tradingPointsNotAvailable ?? 'Trading points not available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            const SizedBox(height: 8),
          SizedBox(
            height: 160, // Fixed height for 4 rows (approximately 40px per row)
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                direction: Axis.vertical,
                alignment: WrapAlignment.start,
                children: availableTradingPoints.map((tp) {
                  return FilterChip(
                    label: Text(tp.name),
                    selected: state.tradingPointCodes.contains(tp.id),
                    onSelected: (v) {
                      final ns = {...state.tradingPointCodes};
                      if (v) {
                        ns.add(tp.id);
                      } else {
                        ns.remove(tp.id);
                      }
                      onChange(state.copyWith(tradingPointCodes: ns));
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date Range filter
          Text(
            l10n?.dateRangeLabel ?? 'Date range',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDateRange,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    state.dateRange == null
                        ? l10n?.allDatesLabel ?? 'All dates'
                        : '${dateFormatShort.format(state.dateRange!.start)} — ${dateFormatShort.format(state.dateRange!.end)}',
                  ),
                ),
              ),
              if (state.dateRange != null)
                IconButton(
                  tooltip: l10n?.clearLabel ?? 'Clear',
                  onPressed: onClearDateRange,
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Status filter
          Text(
            l10n?.statusLabel ?? 'Status',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ContractStatusGroup.values.map((status) {
              return FilterChip(
                label: Text(_getStatusText(context, status)),
                selected: state.status == status,
                onSelected: (v) {
                  onChange(state.copyWith(status: v ? status : null));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context, ContractStatusGroup status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case ContractStatusGroup.all:
        return l10n?.statusAll ?? 'Hammasi';
      case ContractStatusGroup.active:
        return l10n?.contractStatusActive ?? 'Amalda';
      case ContractStatusGroup.expired:
        return l10n?.contractStatusExpired ?? 'Muddati o\'tgan';
      case ContractStatusGroup.cancelled:
        return l10n?.contractStatusCancelled ?? 'Bekor qilingan';
      case ContractStatusGroup.pending:
        return l10n?.contractStatusPending ?? 'Tastiqlanmagan';
    }
  }
}