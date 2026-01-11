// =============================
// presentation/widgets/trading_points_filters_panel.dart
// =============================
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

class TradingPointsFilterState {
  Set<String> tradePointTypes; // multi-select savdo nuqtasi turlari
  Set<String> businessRegions; // multi-select biznes regionlar (code)
  TradingPointsFilterState({Set<String>? tradePointTypes, Set<String>? businessRegions})
      : tradePointTypes = tradePointTypes ?? {}, businessRegions = businessRegions ?? {};
}

typedef TradingPointsFilterOnChange = void Function(TradingPointsFilterState state);

class TradingPointsFiltersPanel extends StatelessWidget {
  final TradingPointsFilterState state;
  final List<String> availableTradePointTypes;
  final Map<String, String> regionNames; // code -> name
  final TradingPointsFilterOnChange onChange;

  const TradingPointsFiltersPanel({
    super.key,
    required this.state,
    required this.availableTradePointTypes,
    required this.regionNames,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16)
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Savdo nuqtasi turi
          Text(l10n.labelTradingPointType, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 120, // Fixed height for scrollable container
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                direction: Axis.vertical,
                alignment: WrapAlignment.start,
                children: [
                  for(final type in availableTradePointTypes.where((t) => t.isNotEmpty))
                    FilterChip(
                      label: Text(type),
                      selected: state.tradePointTypes.contains(type),
                      onSelected: (v){
                        final ns = {...state.tradePointTypes};
                        if(v) ns.add(type); else ns.remove(type);
                        onChange(TradingPointsFilterState(
                          tradePointTypes: ns,
                          businessRegions: state.businessRegions
                        ));
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Biznes region
          Text(l10n.labelBusinessRegion, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 120, // Fixed height for scrollable container
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                direction: Axis.vertical,
                alignment: WrapAlignment.start,
                children: [
                  for(final regionEntry in regionNames.entries)
                    FilterChip(
                      label: Text(regionEntry.value), // Display name
                      selected: state.businessRegions.contains(regionEntry.key), // Check by code
                      onSelected: (v){
                        final nr = {...state.businessRegions};
                        if(v) nr.add(regionEntry.key); else nr.remove(regionEntry.key);
                        onChange(TradingPointsFilterState(
                          tradePointTypes: state.tradePointTypes,
                          businessRegions: nr
                        ));
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}