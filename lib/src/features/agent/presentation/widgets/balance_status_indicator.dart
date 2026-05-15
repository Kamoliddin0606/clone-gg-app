import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';

import 'balance_status_details_sheet.dart';
import 'balance_status_theme.dart';

/// Small pulsing dot rendered on every customer card / detail header / visit
/// step tile that has a non-neutral [CustomerBalanceStatus]. Tapping it
/// opens [BalanceStatusDetailsSheet] with the balance / limit / age details.
///
/// Subscribes to [CustomerBalanceStatusCache] so the dot appears or
/// disappears the moment a fresh balance is persisted via
/// `ClientBalanceService.saveClientBalance` (M12).
///
/// Renders nothing for [CustomerBalanceStatus.noDebt] /
/// [CustomerBalanceStatus.unknown] — the surrounding layout never has to
/// reserve space for a missing dot.
class BalanceStatusIndicator extends StatefulWidget {
  /// INN to look up in the cache. Empty string is allowed (renders nothing).
  final String inn;

  /// Customer name surfaced in the details sheet header.
  final String customerName;

  /// Visual size of the dot in logical pixels. Defaults to 10 — the size we
  /// settled on for the inline-with-name placement.
  final double size;

  const BalanceStatusIndicator({
    super.key,
    required this.inn,
    required this.customerName,
    this.size = 10,
  });

  @override
  State<BalanceStatusIndicator> createState() => _BalanceStatusIndicatorState();
}

class _BalanceStatusIndicatorState extends State<BalanceStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  CustomerBalanceStatusCache? _cache;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (sl.isRegistered<CustomerBalanceStatusCache>()) {
      _cache = sl<CustomerBalanceStatusCache>();
      // Lazy bootstrap — first widget that mounts triggers the DB scan.
      _cache!.bootstrap();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inn.isEmpty || _cache == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _cache!,
      builder: (context, _) {
        final entry = _cache!.entryFor(widget.inn);
        final status = entry?.status ?? CustomerBalanceStatus.unknown;
        final color = BalanceStatusTheme.indicatorColorFor(
          status,
          Theme.of(context).colorScheme,
        );
        if (color == null) {
          return const SizedBox.shrink();
        }

        return Semantics(
          button: true,
          label: 'Balance status indicator',
          child: GestureDetector(
            onTap: () => _openDetails(context, entry),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              // Generous tap target without inflating layout footprint.
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: _pulse.value),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35 * _pulse.value),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetails(BuildContext context, CustomerBalanceStatusEntry? entry) {
    if (entry == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BalanceStatusDetailsSheet(
        customerName: widget.customerName,
        entry: entry,
      ),
    );
  }
}
