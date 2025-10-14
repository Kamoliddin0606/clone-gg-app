
// =============================
// presentation/widgets/order_filters_panel.dart
// =============================
import 'package:flutter/material.dart';
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
  final List<MapEntry<String,int?>> statusMap; // tab label -> code (null=Barchasi)
  final List<String> clients; // future: id-title
  final OrdersFilterOnChange onChange;
  final SimplePicker onPickDateRange;
  final VoidCallback onClearDateRange;
  const OrdersFiltersPanel({super.key, required this.state, required this.statusMap, required this.clients, required this.onChange, required this.onPickDateRange, required this.onClearDateRange});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Status', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 120, // Fixed height for 3 rows (approximately 40px per row)
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              direction: Axis.vertical,
              alignment: WrapAlignment.start,
              children: [
                for(final e in statusMap)
                  if(e.value!=null)
                    FilterChip(
                      label: Text(e.key),
                      selected: state.statuses.contains(e.value),
                      onSelected: (v){
                        final ns = {...state.statuses};
                        if(v) ns.add(e.value!); else ns.remove(e.value!);
                        onChange(OrdersFilterState(statuses: ns, clients: state.clients, range: state.range));
                      },
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Sana oralig\'i', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children:[
          Expanded(child: OutlinedButton.icon(onPressed: onPickDateRange, icon: const Icon(Icons.calendar_month_rounded), label: Text(state.range==null ? 'Barcha sanalar' : '${dateFormatShort.format(state.range!.start)} — ${dateFormatShort.format(state.range!.end)}'))),
          if(state.range!=null) IconButton(tooltip: 'Tozalash', onPressed: onClearDateRange, icon: const Icon(Icons.clear))
        ]),
        const SizedBox(height: 12),
        Text('Mijozlar', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 160, // Fixed height for scrollable container
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for(final c in clients)
                  FilterChip(
                    label: Text(c, overflow: TextOverflow.ellipsis),
                    selected: state.clients.contains(c),
                    onSelected: (v){
                      final nc = {...state.clients};
                      if(v) nc.add(c); else nc.remove(c);
                      onChange(OrdersFilterState(statuses: state.statuses, clients: nc, range: state.range));
                    },
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

