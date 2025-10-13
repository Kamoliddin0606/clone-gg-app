import 'dart:math';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';


void main() {
  runApp(const KpiApp());
}


class KpiApp extends StatelessWidget {
  const KpiApp({super.key});


  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C8CFF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
    );


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1117),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      ),
      home: const KpiDashboardDemo(),
    );
  }
}
/// ---------------------------------------------------------------------------
/// DATA LAYER — Repository pattern with DEMO mode (default now)
/// Later you can wire Local (cache/DB) and Remote (server/SOAP) data sources.
/// ---------------------------------------------------------------------------
class KpiRepository {
  final KpiDataSource demo;
  final KpiDataSource? local;
  final KpiDataSource? remote;
  final bool useDemo;


  KpiRepository.demo()
      : demo = DemoKpiDataSource(),
        local = null,
        remote = null,
        useDemo = true;


  KpiRepository({required this.demo, this.local, this.remote, this.useDemo = true});


  Future<Kpi> getKpi() async {
    if (useDemo) return demo.fetchKpi();


// 1) Try local cache first
    if (local != null) {
      try {
        final cached = await local!.fetchKpi();
        return cached;
      } catch (_) {}
    }


// 2) Fallback to remote
    if (remote != null) {
      try {
        final fresh = await remote!.fetchKpi();
        return fresh;
      } catch (_) {}
    }


// 3) Final fallback — demo
    return demo.fetchKpi();
  }
}


abstract class KpiDataSource {
  Future<Kpi> fetchKpi();
}


/// DEMO data source — returns synthetic but realistic data
class DemoKpiDataSource implements KpiDataSource {
  final Random _rng = Random();
  @override
  Future<Kpi> fetchKpi() async {
    await Future.delayed(const Duration(milliseconds: 400));


// Base values
    const totalPlan = 170000000.0;
    final totalFact = 45e6 + _rng.nextInt(12e6.toInt());
    final totalPercent = (totalFact / totalPlan) * 100;
    final totalForecast = totalFact + _rng.nextInt(80e6.toInt());
    final totalPercentForecastFact = min(100, (totalForecast / totalPlan) * 100);


    final okb = 320 + _rng.nextInt(60); // visited outlets
    final akbPlan = 200;
    final akbFact = 70 + _rng.nextInt(50);


    return Kpi(
      totalPlan: totalPlan,
      totalFact: totalFact,
      totalPercent: totalPercent,
      totalForecast: totalForecast.toDouble(),
      totalPercentForecastFact: totalPercentForecastFact.toDouble(),
      okb: okb,
      akbPlan: akbPlan,
      akbFact: akbFact,
    );
  }
}


/// Local cache (DB) — stub for later (e.g., Hive/sqflite)
class LocalKpiDataSource implements KpiDataSource {
  @override
  Future<Kpi> fetchKpi() async {
// TODO: implement reading from DB cache
    throw UnimplementedError('Local cache not implemented yet');
  }
}


/// Remote (SOAP) — stub for later; keep XML parser available
class RemoteKpiDataSource implements KpiDataSource {
  final Future<String> Function() fetchXml;
  RemoteKpiDataSource(this.fetchXml);


  @override
  Future<Kpi> fetchKpi() async {
    final xmlStr = await fetchXml();
    return Kpi.fromXml(xmlStr);
  }
}
/// ---------------------------------------------------------------------------
/// UI — Dashboard screen using repository (currently DEMO mode)
/// ---------------------------------------------------------------------------
class KpiDashboardDemo extends StatefulWidget {
  const KpiDashboardDemo({super.key});


  @override
  State<KpiDashboardDemo> createState() => _KpiDashboardDemoState();
}


class _KpiDashboardDemoState extends State<KpiDashboardDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final KpiRepository repo;


  Kpi? _kpi;
  bool _loading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    repo = KpiRepository.demo(); // DEMO for now


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );


    _load();
  }


  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await repo.getKpi();
      setState(() => _kpi = data);
      _controller
        ..reset()
        ..forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B2333), Color(0xFF141A25)],
    );
    return Stack(
      children: [
        Container(decoration: BoxDecoration(gradient: gradient)),
        Positioned(top: -80, right: -60, child: _decorBlob(const Color(0xFF6C8CFF).withOpacity(0.25), 220)),
        Positioned(bottom: -60, left: -40, child: _decorBlob(const Color(0xFF00E5A8).withOpacity(0.18), 180)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('KPI Dashboard'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load,
              ),
            ],
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error:                $_error'))
                    : _kpi == null
                ? const Center(child: Text('No data'))
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroHeader(kpi: _kpi!, controller: _controller),
                  const SizedBox(height: 16),
                  _StatsGrid(kpi: _kpi!),
                  const SizedBox(height: 20),
                  _ChartsSection(kpi: _kpi!),
                  const SizedBox(height: 24),
                  _Insights(kpi: _kpi!),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _decorBlob(Color color, double size) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, Colors.transparent]),
            ),
          ),
        );
      },
    );
  }
}
// --- DATA MODEL + XML PARSER -------------------------------------------------
class Kpi {
  final double totalPlan;
  final double totalFact;
  final double totalPercent; // 0..100
  final double totalForecast;
  final double totalPercentForecastFact; // 0..100
  final int okb;
  final int akbPlan;
  final int akbFact;


  Kpi({
    required this.totalPlan,
    required this.totalFact,
    required this.totalPercent,
    required this.totalForecast,
    required this.totalPercentForecastFact,
    required this.okb,
    required this.akbPlan,
    required this.akbFact,
  });


  factory Kpi.fromXml(String xmlStr) {
    final doc = XmlDocument.parse(xmlStr);
    String _get(String tag) => doc.findAllElements(tag).first.text.trim();
    double d(String s) => double.tryParse(s) ?? 0;
    int i(String s) => int.tryParse(s) ?? 0;


    return Kpi(
      totalPlan: d(_get('m:TotalPlan')),
      totalFact: d(_get('m:TotalFact')),
      totalPercent: d(_get('m:TotalPercent')),
      totalForecast: d(_get('m:TotalForecast')),
      totalPercentForecastFact: d(_get('m:TotalPercentForecastFact')),
      okb: i(_get('m:OKB')),
      akbPlan: i(_get('m:AKBPlan')),
      akbFact: i(_get('m:AKBFact')),
    );
  }
}
// --- HEADER (unchanged UI components below) ----------------------------------
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.kpi, required this.controller});
  final Kpi kpi;
  final AnimationController controller;


  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern();
    final percent = (kpi.totalPercent / 100).clamp(0.0, 1.0);


    return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x334B6BFF), Color(0x3316D2A6)],
                  ),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                    children: [// Animated circular progress
                    SizedBox(
                    width: 110,
                    height: 110,
                    child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 900),
                        tween: Tween<double>(begin: 0.0, end: percent),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Stack(
                              alignment: Alignment.center,
                              children: [
                              ShaderMask(
                              shaderCallback: (rect) => const SweepGradient(
                            startAngle: -3.14159 / 2,
                            endAngle: 3 * 3.14159 / 2,
                            colors: [Color(0xFF6C8CFF), Color(0xFF00E5A8)],
                          ).createShader(rect),
                          child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10.0,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          ),Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${(value * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('Plan', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
                                  ],
                                )
                              ],
                          );
                        },
                    ),
                ),const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today Performance',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            _animatedMetric(context, 'Total Fact', nf.format(kpi.totalFact)),
                            _animatedMetric(context, 'Total Plan', nf.format(kpi.totalPlan)),
                            _animatedMetric(context, 'Forecast', nf.format(kpi.totalForecast)),
                          ],
                        ),
                      ),
                    ],
                ),
            ),
        ),
    );
  }
  Widget _animatedMetric(BuildContext context, String label, String value) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                const Spacer(),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}
// --- GRID CARDS ---------------------------------------------------------------
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.kpi});
  final Kpi kpi;


  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.compact();
    final items = [
      _TileData('OKB', kpi.okb.toString(), Icons.storefront_rounded),
      _TileData('AKB Plan', kpi.akbPlan.toString(), Icons.flag_circle_rounded),
      _TileData('AKB Fact', kpi.akbFact.toString(), Icons.task_alt_rounded),
      _TileData('Forecast % of Fact', '${kpi.totalPercentForecastFact.toStringAsFixed(1)}%', Icons.trending_up_rounded),
      _TileData('Total Plan', nf.format(kpi.totalPlan), Icons.layers_rounded),
      _TileData('Total Fact', nf.format(kpi.totalFact), Icons.payments_rounded),
    ];


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _GlassTile(data: items[i]),
    );
  }
}
class _TileData {
  final String title;
  final String value;
  final IconData icon;
  const _TileData(this.title, this.value, this.icon);
}


class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.data});
  final _TileData data;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, t, _) {
        return Transform.scale(
          scale: t,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0x221A73E8), Color(0x2216D2A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(data.icon, size: 20, color: Colors.white70),
                    const Spacer(),
                    Text(data.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(data.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// --- CHARTS ------------------------------------------------------------------
class _ChartsSection extends StatelessWidget {
  const _ChartsSection({required this.kpi});
  final Kpi kpi;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('Charts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    _ChartCard(title: 'AKB Progress',
    subtitle: 'Plan vs Fact',
    child: SizedBox(
    height: 180,child: BarChart(
    BarChartData(
    borderData: FlBorderData(show: false),
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
    sideTitles: SideTitles(showTitles: true,
    getTitlesWidget: (value, meta) {
    switch (value.toInt()) {
    case 0:
    return const _AxisLabel('Plan');
    case 1:
    return const _AxisLabel('Fact');
    default:
    return const SizedBox.shrink();
    }},
    ),
    ),
    ),
    barGroups: [
    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: kpi.akbPlan.toDouble(), width: 20.0)]),
    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: kpi.akbFact.toDouble(), width: 20.0)]),
    ],
    ),
    ),
    ),
    ),
    const SizedBox(height: 12),
    _ChartCard(
    title: 'Plan Completion',
    subtitle: 'Fact vs Remaining',
    child: SizedBox(
    height: 180,
    child: PieChart(
    PieChartData(
    sectionsSpace: 2.0,
    centerSpaceRadius: 44.0,
    sections: _buildPlanPie(kpi),
    ),
    ),
    ),
    ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Forecast Trend',
            subtitle: 'From Fact to Forecast',
            child: SizedBox(height: 200, child: _ForecastLine(kpi: kpi)),
          ),
        ],
    );
  }
  List<PieChartSectionData> _buildPlanPie(Kpi kpi) {
    final double fact = kpi.totalFact;
    final double remaining = max(0.0, kpi.totalPlan - fact).toDouble();
    final double total = (fact + remaining).clamp(1.0, double.infinity).toDouble();


    return [
      PieChartSectionData(value: fact / total, title: 'Fact', radius: 56.0),
      PieChartSectionData(value: remaining / total, title: 'Remaining', radius: 50.0),
    ];
  }
}


class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
class _ForecastLine extends StatelessWidget {
  const _ForecastLine({required this.kpi});
  final Kpi kpi;


  @override
  Widget build(BuildContext context) {
// Synthetic points: starting from fact, easing toward forecast
    final fact = kpi.totalFact;
    final forecast = kpi.totalForecast;
    final points = List.generate(7, (i) {
      final t = i / 6.0; // 0..1
      final y = fact + (forecast - fact) * Curves.easeInOut.transform(t);
      return FlSpot(i.toDouble(), y);
    });
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: points,
            barWidth: 3.0,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}



class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;


  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0x221A73E8), Color(0x2229C6B7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),border: Border.all(color: Colors.white10),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
        ),
    );
  }
}
// --- INSIGHTS ----------------------------------------------------------------
class _Insights extends StatelessWidget {
  const _Insights({required this.kpi});
  final Kpi kpi;


  @override
  Widget build(BuildContext context) {
    // final gap = max(0, kpi.totalPlan - kpi.totalFact);
    final double gap = max(0.0, kpi.totalPlan - kpi.totalFact).toDouble();
    final akbGap = max(0, kpi.akbPlan - kpi.akbFact);
    final trend = kpi.totalForecast >= kpi.totalPlan ? 'On track' : 'At risk';


    return _ChartCard(
      title: 'Insights',
      subtitle: 'Auto‑generated highlights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bullet(context, 'Completion', '${kpi.totalPercent.toStringAsFixed(1)}% of plan achieved'),
          _bullet(context, 'Gap to Plan', _money(context, gap)),
          _bullet(context, 'AKB Gap', '$akbGap clients to reach plan'),
          _bullet(context, 'Forecast vs Plan', trend),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String key, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      children: [
        const Icon(Icons.brightness_1, size: 6, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(child: Text(key, style: Theme.of(context).textTheme.bodyMedium)),
        Text(val, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
      ],
    ),
  );


  String _money(BuildContext context, double v) {
    final nf = NumberFormat.compact();
    return nf.format(v);
  }
}
final repo = KpiRepository(
  demo: DemoKpiDataSource(),
  // local: LocalKpiDataSource(), // TODO: implement
  // remote: RemoteKpiDataSource(() async => await yourSoapCallReturningXml()),
  useDemo: false, // ← set to false when switching off demo
);