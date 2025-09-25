import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../../../navbars/fluid_nav_bar.dart';
/// Drop-in, logic-safe visual redesign for the agent home page.
///
/// ✨ Key ideas
/// - Purely presentational. No storage/network logic.
/// - Parameterized with the data you already load (names resemble your existing fields).
/// - All buttons are callbacks so your routing stays unchanged.
/// - Material 3 tokens, modern cards, responsive grid, pull-to-refresh.
///
/// How to use
/// Replace the body of your current page with [AgentHomeModern] and
/// pass the data + callbacks you already have.
///
/// Example:
/// AgentHomeModern(
///   userName: currentUserName,
///   userCode: userCode,
///   kpi: KpiView(
///     salesSum: _kpiData?.totalForecast, // or actual sales sum if you have it
///     itemsSold: _kpiData?.itemsSold,
///     customersServed: _kpiData?.customersServed,
///     totalPercent: _kpiData?.totalPercent,
///     akbPlan: _kpiData?.akbPlan,
///     akbFact: _kpiData?.akbFact,
///     akbPercent: _kpiData?.akbPercent,
///     okb: _kpiData?.okb,
///   ),
///   onRefresh: _refreshKpi,
///   onCreateOrder: () => context.pushNamed(AppRouter.tradingPointsRoute),
///   onOpenCustomers: _openCustomers,
///   onOpenProducts: _openProducts,
/// );

class KpiView {
  final String? salesSum; // e.g. formatted "128 000 000"
  final String? itemsSold; // e.g. "342"
  final String? customersServed; // e.g. "58"
  final String? totalPercent; // e.g. "76" (without % sign) or "76.3"
  final String? akbPlan; // plan value
  final String? akbFact; // fact value
  final String? akbPercent; // percent string without %
  final String? okb; // OKB value

  const KpiView({
    this.salesSum,
    this.itemsSold,
    this.customersServed,
    this.totalPercent,
    this.akbPlan,
    this.akbFact,
    this.akbPercent,
    this.okb,
  });
}

class AgentHomeModern extends StatefulWidget {
  final String userName;
  final String userCode;
  final KpiView? kpi;

  final Future<void> Function()? onRefresh;
  final VoidCallback? onCreateOrder;
  final VoidCallback? onOpenCustomers;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onLogout;

  const AgentHomeModern({
    super.key,
    required this.userName,
    required this.userCode,
    this.kpi,
    this.onRefresh,
    this.onCreateOrder,
    this.onOpenCustomers,
    this.onOpenProducts,
    this.onLogout,
  });
  static String _pct(String? v) {
    if (v == null || v.trim().isEmpty) return '-';
    final cleaned = v.replaceAll('%', '').replaceAll(',', '.').trim();
    final d = double.tryParse(cleaned);
    if (d == null) return '-';
    return '${d.toStringAsFixed(1)}%';
  }

  static String _pctNum(String? v) {
    if (v == null || v.trim().isEmpty) return '-';
    final cleaned = v.replaceAll('%', '').replaceAll(',', '.').trim();
    final d = double.tryParse(cleaned);
    if (d == null) return '-';
    return d.toStringAsFixed(1);
  }
  @override
  State<AgentHomeModern> createState() => _AgentHomeModernState();
}

class _AgentHomeModernState extends State<AgentHomeModern> with TickerProviderStateMixin {
  bool _expanded = true;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: _Header(userName: widget.userName, userCode: widget.userCode),
            actions: [
              IconButton(
                tooltip: 'Yangilash',
                onPressed: () => widget.onRefresh?.call(),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Chiqish',
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),

          // KPI ring + quick stats (TAP TO TOGGLE BELOW CARDS)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _KpiOverview(kpi: widget.kpi, onTap: _toggleExpanded, expanded: _expanded),
            ),
          ),

          // KPI grid (animated show/hide when tapping overview)
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutQuad,
                switchOutCurve: Curves.easeInQuad,
                child: _expanded
                    ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.90,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      _StatCard(
                        title: 'Savdo summasi',
                        value: AgentHomeModern._pctNum(widget.kpi?.salesSum),
                        icon: Icons.trending_up,
                      ),
                      _StatCard(
                        title: 'Sotilgan tovarlar',
                        value: widget.kpi?.itemsSold ?? '-',
                        icon: Icons.inventory_2,
                      ),
                      _StatCard(
                        title: 'Xizmat ko’rsatilgan mijozlar',
                        value: widget.kpi?.customersServed ?? '-',
                        icon: Icons.people_alt,
                      ),
                      _StatCard(
                        title: 'OKB',
                        value: widget.kpi?.okb ?? '-',
                        icon: Icons.verified_user,
                      ),
                      _StatCard(
                        title: 'AKB rejasi',
                        value: widget.kpi?.akbPlan ?? '-',
                        icon: Icons.flag,
                      ),
                      _StatCard(
                        title: 'AKB fakt',
                        value: widget.kpi?.akbFact ?? '-',
                        icon: Icons.check_circle_outline,
                      ),
                      _StatCard(
                        title: 'AKB %',
                        value: AgentHomeModern._pct(widget.kpi?.akbPercent),
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Actions stay as-is
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _ActionsRow(
                onCreateOrder: widget.onCreateOrder,
                onOpenCustomers: () => Navigator.pushNamed(context, AppRouter.tradingPointsRoute),
                onOpenProducts: widget.onOpenProducts,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Moved helper to stateful class; keep same behavior

}

class _Header extends StatelessWidget {
  final String userName;
  final String userCode;
  const _Header({required this.userName, required this.userCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                userName.isNotEmpty ? userName.characters.first.toUpperCase() : 'U',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: $userCode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiOverview extends StatelessWidget {
  final KpiView? kpi;
  final VoidCallback? onTap;
  final bool expanded;
  const _KpiOverview({this.kpi, this.onTap, this.expanded = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = _parsePct(kpi?.totalPercent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ProgressRing(percent: percent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Reja bajarilishi', style: theme.textTheme.titleMedium)),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: expanded ? 0.0 : 0.5,
                          child: const Icon(Icons.expand_more),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      percent == null ? '-' : '${(percent * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _chip('Reja', kpi?.akbPlan),
                        _chip('Fakt', kpi?.akbFact),
                        _chip('Qolgan', _remaining(kpi?.akbPlan, kpi?.akbFact)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ... rest stays same
  static String? _remaining(String? plan, String? fact) {
    final p = _num(plan);
    final f = _num(fact);
    if (p == null || f == null) return null;
    final r = (p - f);
    if (r < 0) return '0';
    return _fmt(r);
  }

  static double? _num(String? s) {
    if (s == null) return null;
    final clean = s.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(RegExp(r"[-+]?[0-9]*\.?[0-9]+").stringMatch(clean) ?? '');
  }

  static double? _parsePct(String? s) {
    if (s == null) return null;
    final clean = s.replaceAll('%', '').replaceAll(',', '.');
    final v = double.tryParse(clean);
    if (v == null) return null;
    return (v.clamp(0, 100)) / 100.0;
  }

  static String _fmt(num n) {
    final str = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final idx = str.length - i;
      b.write(str[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  static Widget _chip(String label, String? value) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      visualDensity: VisualDensity.compact,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value == null || value.isEmpty ? '-' : value),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double? percent; // 0..1
  const _ProgressRing({this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double? p = percent == null
        ? null
        : percent!.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: (p == null || p == 0.0) ? null : p, // CHANGED
              strokeWidth: 10,
            ),
          ),
          Text(
            p == null ? '—' : '${(p * 100).toStringAsFixed(1)}%', // CHANGED
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12) // CHANGED
        ,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  FittedBox( // CHANGED: ensure long sums (up to 10 digits) fit on one row
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value.isEmpty ? '-' : value,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final VoidCallback? onCreateOrder;
  final VoidCallback? onOpenCustomers;
  final VoidCallback? onOpenProducts;
  const _ActionsRow({this.onCreateOrder, this.onOpenCustomers, this.onOpenProducts});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final children = <Widget>[
          _ActionTile(
            label: 'Buyurtma yaratish',
            icon: Icons.add_shopping_cart,
            onTap: onCreateOrder,
          ),
          _ActionTile(
            label: 'Mijozlar',
            icon: Icons.people,
            onTap: onOpenCustomers,
          ),
          _ActionTile(
            label: 'Tovarlar',
            icon: Icons.storefront,
            onTap: onOpenProducts,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            children[0],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: children[1]),
              const SizedBox(width: 12),
              Expanded(child: children[2]),
            ]),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionTile({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
