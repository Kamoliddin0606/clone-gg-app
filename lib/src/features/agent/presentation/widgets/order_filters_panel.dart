
// =============================
// presentation/widgets/order_filters_panel.dart
// =============================
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../shared/formatters.dart';

class OrdersFilterState {
  Set<int> statuses; // multi-select
  Set<String> clients; // multi-select by name (id in future)
  DateTimeRange? range;
  OrdersFilterState({Set<int>? statuses, Set<String>? clients, this.range})
      : statuses = statuses ?? {}, clients = clients ?? {};
}

typedef OrdersFilterOnChange = void Function(OrdersFilterState state);

typedef SimplePicker = Future<void> Function();

class OrdersFiltersPanel extends StatelessWidget {
  final OrdersFilterState state;
  final OrdersFilterOnChange onChange;
  final SimplePicker onPickDateRange;
  final VoidCallback onClearDateRange;
  final VoidCallback onPickClients;
  final VoidCallback onClearClients;
  const OrdersFiltersPanel({
    super.key,
    required this.state,
    required this.onChange,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.onPickClients,
    required this.onClearClients,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(l10n.labelDateRange, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children:[
          Expanded(child: OutlinedButton.icon(onPressed: onPickDateRange, icon: const Icon(Icons.calendar_month_rounded), label: Text(state.range==null ? l10n.allDates : '${dateFormatShort.format(state.range!.start)} — ${dateFormatShort.format(state.range!.end)}'))),
          if(state.range!=null) IconButton(tooltip: l10n.clear, onPressed: onClearDateRange, icon: const Icon(Icons.clear))
        ]),
        const SizedBox(height: 12),
        Text(l10n.labelClients, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children:[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickClients,
              icon: const Icon(Icons.groups_rounded),
              label: Text(
                state.clients.isEmpty
                    ? l10n.all
                    : '${state.clients.length}',
              ),
            ),
          ),
          if (state.clients.isNotEmpty)
            IconButton(
              tooltip: l10n.clear,
              onPressed: onClearClients,
              icon: const Icon(Icons.clear),
            ),
        ]),
      ]),
    );
  }
}

