import 'package:flutter/material.dart';


/// Animated Percentage Widget - Barcha percent elementlar uchun umumiy widget
enum PercentageDisplayType {
  circular,    // Dial gauge (doiraviy progress)
  linear,      // Chiziqli progress bar
  text,        // Faqat matn ko'rinishida
  number,      // Raqamlar uchun animatsiya
}

class AnimatedPercentageWidget extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  final PercentageDisplayType type;
  final Color color;
  final String? label;
  final String? valueText;
  final double size;
  final Duration animationDuration;
  final String? numberValue; // For number animation

  const AnimatedPercentageWidget({
    super.key,
    required this.percentage,
    this.type = PercentageDisplayType.circular,
    required this.color,
    this.label,
    this.valueText,
    this.size = 100,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.numberValue,
  });

  @override
  State<AnimatedPercentageWidget> createState() => _AnimatedPercentageWidgetState();
}

class _AnimatedPercentageWidgetState extends State<AnimatedPercentageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.percentage.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Sahifa yuklanganda animatsiyani boshlash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedPercentageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case PercentageDisplayType.circular:
            return _buildCircularProgress();
          case PercentageDisplayType.linear:
            return _buildLinearProgress();
          case PercentageDisplayType.text:
            return _buildTextProgress();
          case PercentageDisplayType.number:
            return _buildNumberProgress();
        }
      },
    );
  }

  Widget _buildCircularProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: _animation.value,
              color: widget.color,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
            ),
            child: Center(
              child: Text(
                widget.valueText ?? '${(_animation.value * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLinearProgress() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: theme.textTheme.labelMedium,
            ),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        if (widget.valueText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.valueText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextProgress() {
    return Text(
      widget.valueText ?? '${(_animation.value * 100).toStringAsFixed(1)}%',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: widget.color,
      ),
    );
  }

  Widget _buildNumberProgress() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: double.tryParse(widget.numberValue ?? '0') ?? 0),
      duration: widget.animationDuration,
      builder: (_, value, __) => Text(
        widget.valueText ?? value.toStringAsFixed(0),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: widget.color,
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // 180 degrees (semi-circle)
      3.14159,
      false,
      backgroundPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}

/// === Telegram xabarini shu yerga joylashtiring tez sinov uchun ===
const String sampleTelegramText = """
#dailyReport
📅 Sana: 9-10-2025  14:30:54
🙎🏻‍♂️ FIO: URALOVA YULDUZOY (OLMALIQ-AXONGORON DIL ) 6361354711

Hudud : ('Алмалык-1',)

OKB va AKB:

Hudud bo'yicha OKB --  227 t.t.
Bugun tashrif buyurilgan savdo nuqtalari soni  --  13 t.t.
Bugun faol mijozlar  --  8 t.t.


AKB hududlar bo'yicha taqsimlanishi:

Алмалык-1  --  8t.t.

Buyurtmalar umumiy summasi:

Naqd  --  1 220 360.0 So'm
Naqdsiz  --  1 105 730.0 So'm
Buyurtmalar umumiy summasi  --  2 326 090.0 So'm

AKB tovar kategoriyalari bo'yicha:

DURU SOAP  --  8t.t.
DURU SHOWER GEL  --  1t.t.
DEO EMOTION  --  3t.t.
DEODORANT  --  3t.t.
PRESHAVE  --  2t.t.
AFTERSHAVE  --  1t.t.


✿•┈┈┈┈••ৡ❀ৡ•┈┈┈┈•✿

📊 Oylik reja va umumiy natijalar 9-10-2025  14:30:54 uchun

Reja va fakt:

Reja  --  170 000 000.0 So'm
Fakt  --  26 832 890.0 So'm
Fakt foizda  --  15.78%
Bashorat  --  90 561 003.75 So'm
Bashorat foizda  --  53.27%

OKB va AKB:

OKB  --  219 t.t.
AKB reja  --  170 t.t.
AKB fakt  --  53 t.t.
AKB foizda --  31.18%
""";

class MainReportPage extends StatefulWidget {
  const MainReportPage({super.key});

  @override
  State<MainReportPage> createState() => _MainReportPageState();
}

class _MainReportPageState extends State<MainReportPage>
    with SingleTickerProviderStateMixin {
  late final DailyReport report;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    report = DailyReport.fromTelegram(sampleTelegramText);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.08),
            cs.primaryContainer.withOpacity(0.06),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _SectionTitle(icon: Icons.groups_2_outlined, title: 'Oylik OKB/AKB'),
                  const SizedBox(height: 8),
                  _OkbAkbMonthly(report: report),

                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.ssid_chart_rounded, title: 'Oylik reja / Fakt / Bashorat'),
                  const SizedBox(height: 8),
                  _PlanFactForecast(report: report),
                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.analytics_outlined, title: 'Bugun — asosiy ko\'rsatkichlar'),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(
                            label: 'Hudud OKB',
                            value: report.okbTerritory.toString(),
                            icon: Icons.map_outlined,
                            tooltip: 'Hudud bo\'yicha mijozlar bazasini qamrab olish',
                          ),
                          _StatCard(
                            label: 'Tashrif buyurilgan s.n.',
                            value: report.visitedTT.toString(),
                            icon: Icons.store_mall_directory_outlined,
                            tooltip: 'Tashrif buyurilgan savdo nuqtalari soni',
                          ),
                          _StatCard(
                            label: 'Faol mijozlar',
                            value: report.activeToday.toString(),
                            icon: Icons.check_circle,
                            tooltip: 'Bugun faol buyurtmalari bo\'lgan mijozlar',
                          ),
                          _MoneyCard(
                            label: 'Naqd',
                            amount: report.cash,
                            icon: Icons.payments_outlined,
                          ),
                          _MoneyCard(
                            label: 'Naqdsiz',
                            amount: report.cashless,
                            icon: Icons.account_balance_outlined,
                          ),
                          _MoneyCard(
                            label: 'Buyurtmalar jami',
                            amount: report.totalOrders,
                            icon: Icons.receipt_long_outlined,
                            highlight: true,
                          ),
                        ],
                      );
                    },
                  ),



                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.map_outlined, title: 'Hududlar bo\'yicha AKB'),
                  const SizedBox(height: 8),
                  _RegionChips(regions: report.akbByRegion),

                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.category_outlined, title: 'Tovar kategoriyalari bo\'yicha AKB'),
                  const SizedBox(height: 8),
                  _CategoryList(categories: report.categories),



                  const SizedBox(height: 28),
                  _FooterNote(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? tooltip;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = _GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, v, __) => Text(
                    v.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

class _MoneyCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final bool highlight;

  const _MoneyCard({
    required this.label,
    required this.amount,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      highlight: highlight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.tertiary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: amount),
                  duration: const Duration(milliseconds: 800),
                  builder: (_, v, __) => Text(
                    formatCurrencyUz(v),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool highlight;
  const _GlassCard({required this.child, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        gradient: highlight
            ? LinearGradient(
          colors: [cs.primary.withOpacity(0.06), cs.surface.withOpacity(0.0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
      ),
      child: child,
    );
  }
}

class _PlanFactForecast extends StatelessWidget {
  final DailyReport report;
  const _PlanFactForecast({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget buildBar({required String label, required double percent, required Color color, String? value}) {
      percent = percent.clamp(0, 1);
      return _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                if (value != null)
                  Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedPercentageWidget(
              percentage: percent,
              type: PercentageDisplayType.linear,
              color: color,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        buildBar(
          label: 'Fakt',
          percent: report.fact / (report.plan == 0 ? 1 : report.plan),
          color: cs.primary,
          value: formatCurrencyUz(report.fact),
        ),
        const SizedBox(height: 10),
        buildBar(
          label: 'Bashorat',
          percent: report.forecast / (report.plan == 0 ? 1 : report.plan),
          color: cs.tertiary,
          value: formatCurrencyUz(report.forecast),
        ),
        const SizedBox(height: 10),
        buildBar(
          label: 'Reja',
          percent: 1,
          color: cs.secondary,
          value: formatCurrencyUz(report.plan),
        ),
      ],
    );
  }
}

class _RegionChips extends StatelessWidget {
  final Map<String, int> regions;
  const _RegionChips({required this.regions});

  @override
  Widget build(BuildContext context) {
    final entries = regions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in entries)
          Chip(
            avatar: const Icon(Icons.location_city_outlined, size: 18),
            label: Text('${e.key}: ${e.value} t.t.'),
          ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  final Map<String, int> categories;
  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _GlassCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_mall_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        AnimatedPercentageWidget(
                          percentage: e.value / (items.first.value == 0 ? 1 : items.first.value),
                          type: PercentageDisplayType.linear,
                          color: cs.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}

class _OkbAkbMonthly extends StatelessWidget {
  final DailyReport report;
  const _OkbAkbMonthly({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _GlassCard(
            child: AnimatedPercentageWidget(
              percentage: report.akbPercent / 100.0,
              type: PercentageDisplayType.circular,
              color: cs.primary,
              label: 'AKB %',
              valueText: '${report.akbPercent.toStringAsFixed(2)}%',
              size: 100,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Oylik OKB', report.okbMonth.toString()),
                const SizedBox(height: 6),
                _kv('AKB reja', report.akbPlan.toString()),
                const SizedBox(height: 6),
                _kv('AKB fakt', report.akbFact.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(v, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      ],
    );
  }
}



class _FooterNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.08), cs.surfaceVariant.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ma\'lumotlar Telegram hisobotidan import qilingan. Yangi manbaga o\'tish uchun matnni o\'zgartirishingiz mumkin — UI yangilanadi.',
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// Parsing & Model Layer
/// =====================
class DailyReport {
  final DateTime? dateTime;
  final String agentName;
  final String territoryLabel;

  // Today
  final int okbTerritory;
  final int visitedTT;
  final int activeToday;

  // Orders
  final double cash;
  final double cashless;
  final double totalOrders;

  // Regions & Categories
  final Map<String, int> akbByRegion;
  final Map<String, int> categories;

  // Monthly
  final double plan;
  final double fact;
  final double forecast;
  final double factPercent;
  final double forecastPercent;
  final int okbMonth;
  final int akbPlan;
  final int akbFact;
  final double akbPercent;

  DailyReport({
    required this.dateTime,
    required this.agentName,
    required this.territoryLabel,
    required this.okbTerritory,
    required this.visitedTT,
    required this.activeToday,
    required this.cash,
    required this.cashless,
    required this.totalOrders,
    required this.akbByRegion,
    required this.categories,
    required this.plan,
    required this.fact,
    required this.forecast,
    required this.factPercent,
    required this.forecastPercent,
    required this.okbMonth,
    required this.akbPlan,
    required this.akbFact,
    required this.akbPercent,
  });

  String get formattedDateTime {
    if (dateTime == null) return '-';
    final d = dateTime!;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  factory DailyReport.fromTelegram(String raw) {
    String getLineAfter(String label) {
      final m = RegExp(RegExp.escape(label) + r"\s*([^\n]+)").firstMatch(raw);
      return (m != null ? m.group(1) : '')!.trim();
    }

    double parseMoney(String s) {
      // Keep digits and separators
      final cleaned = s.replaceAll(RegExp(r"[^0-9.,]"), '').replaceAll(' ', '').replaceAll(',', '.');
      if (cleaned.isEmpty) return 0;
      return double.tryParse(cleaned) ?? 0;
    }

    int parseCount(String s) {
      final m = RegExp(r"(\d+)").firstMatch(s);
      return int.tryParse(m?.group(1) ?? '0') ?? 0;
    }

    // Date
    DateTime? dt;
    try {
      final dateLine = getLineAfter('Sana:');
      // Expect formats like 9-10-2025  14:30:54
      final parts = RegExp(r"(\d{1,2})[-./](\d{1,2})[-./](\d{4})\s+(\d{1,2}):(\d{2})").firstMatch(dateLine);
      if (parts != null) {
        final d = int.parse(parts.group(1)!);
        final m = int.parse(parts.group(2)!);
        final y = int.parse(parts.group(3)!);
        final hh = int.parse(parts.group(4)!);
        final mm = int.parse(parts.group(5)!);
        dt = DateTime(y, m, d, hh, mm);
      }
    } catch (_) {}

    // Agent name
    final nameLine = getLineAfter('FIO:');
    final agentName = nameLine.isEmpty ? '—' : nameLine;

    // Territory
    String territory = '—';
    final terr = getLineAfter('Hudud :');
    final terrM = RegExp(r"\('([^']+)'\)").firstMatch(terr);
    if (terrM != null) territory = terrM.group(1)!;

    // Today block
    final okbTerritory = parseCount(getLineAfter('Hudud bo\'yicha OKB --'));
    final visited = parseCount(getLineAfter('Bugun tashrif buyurilgan savdo nuqtalari soni  --'));
    final active = parseCount(getLineAfter('Bugun faol mijozlar  --'));

    // Orders block
    final cash = parseMoney(getLineAfter('Naqd  --'));
    final cashless = parseMoney(getLineAfter('Naqdsiz  --'));
    final total = parseMoney(getLineAfter('Buyurtmalar umumiy summasi  --'));

    // Regions section
    Map<String, int> regions = {};
    final regionSection = _sectionBetween(raw, 'AKB hududlar bo\'yicha taqsimlanishi:', 'Buyurtmalar umumiy summasi:');
    for (final line in regionSection.split('\n')) {
      final m = RegExp(r"^\s*([^\-\n]+?)\s*--\s*(\d+)").firstMatch(line);
      if (m != null) {
        regions[m.group(1)!.trim()] = int.parse(m.group(2)!);
      }
    }

    // Categories section
    Map<String, int> categories = {};
    final catSection = _sectionBetween(raw, 'AKB tovar kategoriyalari bo\'yicha:', '✿');
    for (final line in catSection.split('\n')) {
      final m = RegExp(r"^\s*([^\-\n]+?)\s*--\s*(\d+)").firstMatch(line);
      if (m != null) {
        categories[m.group(1)!.trim()] = int.parse(m.group(2)!);
      }
    }

    // Monthly block
    final plan = parseMoney(getLineAfter('Reja  --'));
    final fact = parseMoney(getLineAfter('Fakt  --'));
    final factP = parseMoney(getLineAfter('Fakt foizda  --'));
    final forecast = parseMoney(getLineAfter('Bashorat  --'));
    final forecastP = parseMoney(getLineAfter('Bashorat foizda  --'));

    final okbMonth = parseCount(getLineAfter('OKB  --'));
    final akbPlan = parseCount(getLineAfter('AKB reja  --'));
    final akbFact = parseCount(getLineAfter('AKB fakt  --'));
    final akbP = parseMoney(getLineAfter('AKB foizda --'));

    return DailyReport(
      dateTime: dt,
      agentName: agentName,
      territoryLabel: territory,
      okbTerritory: okbTerritory,
      visitedTT: visited,
      activeToday: active,
      cash: cash,
      cashless: cashless,
      totalOrders: total,
      akbByRegion: regions.isEmpty ? {'—': 0} : regions,
      categories: categories.isEmpty ? {'—': 0} : categories,
      plan: plan,
      fact: fact,
      forecast: forecast,
      factPercent: factP,
      forecastPercent: forecastP,
      okbMonth: okbMonth,
      akbPlan: akbPlan,
      akbFact: akbFact,
      akbPercent: akbP,
    );
  }
}

String _sectionBetween(String raw, String start, String end) {
  final sIdx = raw.indexOf(start);
  if (sIdx == -1) return '';
  final from = sIdx + start.length;
  final eIdx = raw.indexOf(end, from);
  final to = eIdx == -1 ? raw.length : eIdx;
  return raw.substring(from, to).trim();
}

String formatCurrencyUz(num n) {
  // space-separated thousands, no currency symbol; append " so'm" where needed externally
  final s = n.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final remaining = s.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buf.write(' ');
  }
  return '${buf.toString()} so\'m';
}
