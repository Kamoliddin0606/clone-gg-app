
import 'dart:math';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/Utility/formatter.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_exceptions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/data_sync_progress_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/server_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/theme_controller.dart';
import '../../../../theme/theme_toggle.dart';
import '../../../../theme/theme_schemes.dart';
import '../../../navbars/fluid_nav_bar.dart';
import 'prices_page.dart';

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

  // Note: XML parsing functionality removed for now to avoid import issues
  // Can be added back when xml package is properly imported
}

class AgentHomeModern extends StatefulWidget {
  final String userName;
  final String userCode;
  final String? position;
  final String? project;
  final String? avatarUrl;
  final KpiView? kpi;

  final Future<void> Function()? onRefresh;
  final VoidCallback? onCreateOrder;
  final VoidCallback? onOpenCustomers;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onReports;
  final VoidCallback? onCash;
  final VoidCallback? onDebitCredit;
  final VoidCallback? onWarehouses;
  final VoidCallback? onPrices;
  final VoidCallback? onContracts;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  const AgentHomeModern({
    super.key,
    required this.userName,
    required this.userCode,
    this.position,
    this.project,
    this.avatarUrl,
    this.kpi,
    this.onRefresh,
    this.onCreateOrder,
    this.onOpenCustomers,
    this.onOpenProducts,
    this.onReports,
    this.onCash,
    this.onDebitCredit,
    this.onWarehouses,
    this.onPrices,
    this.onContracts,
    this.onSettings,
    this.onLogout,
  });
  static String _pct(String? v) {
    if (v == null || v.trim().isEmpty) return '-';
    final cleaned = v.replaceAll('%', '').replaceAll(',', '.').trim();
    final d = double.tryParse(cleaned);
    if (d == null) return '-';
    return '${d.toStringAsFixed(1)}%';
  }

  static String _sumFmt(String? v) {
    final s = v?.trim();
    if (s == null || s.isEmpty) return '-';
    final n = double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.'));
    if (n == null) return s; // kelgan formatni qoldiramiz
    final t = n.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < t.length; i++) {
      final idx = t.length - i;
      b.write(t[i]);
      if (idx > 1 && idx % 3 == 1) b.write(' ');
    }
    return b.toString();
  }
  @override
  State<AgentHomeModern> createState() => _AgentHomeModernState();
}

class _AgentHomeModernState extends State<AgentHomeModern> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _expanded = true;
  bool _isDataSyncInProgress = false;
  Stream<SyncStep>? _syncStepStream;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  Future<void> _syncDataWithProgress() async {
    final prefs = sl<SharedPreferencesService>();
    final userCode = prefs.getUserCode() ?? '';
    final password = prefs.getPassword() ?? '';
    final codeProject = prefs.getCodeProject() ?? '';
    final warehouseCode = prefs.getWarehouseCode() ?? '';
    final dataSyncService = sl<DataSyncService>();

    setState(() {
      _isDataSyncInProgress = true;
      _syncStepStream = dataSyncService.syncAllUserDataWithProgress(
        userCode: userCode,
        password: password,
        codeProject: codeProject,
        codeSklad: warehouseCode,
      );
    });
  }

  void _onDataSyncComplete() {
    setState(() {
      _isDataSyncInProgress = false;
      _syncStepStream = null;
    });
    // Refresh KPI data after sync
    widget.onRefresh?.call();
  }

  void _onDataSyncError(dynamic error) {
    // Show user-friendly error message
    String errorMessage = 'Ma\'lumotlarni yangilashda xatolik yuz berdi.';

    if (error is PaymentRequiredException) {
      errorMessage = 'To\'lov talab qilinmoqda. Iltimos, obunangizni tekshiring.';
    } else if (error is AuthenticationException) {
      errorMessage = 'Autentifikatsiya xatosi. Iltimos, qayta kiring.';
    } else if (error is ForbiddenException) {
      errorMessage = 'Kirish taqiqlangan. Sizda ruxsat yo\'q.';
    } else if (error is NotFoundException) {
      errorMessage = 'Xizmat topilmadi. Iltimos, qo\'llab-quvvatlashga murojaat qiling.';
    } else if (error is ServerUnavailableException) {
      errorMessage = 'Server mavjud emas. Iltimos, keyinroq urinib ko\'ring.';
    } else if (error is SoapFaultException) {
      errorMessage = 'Server xatosi: ${error.message}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _onOfflineIndicatorTap() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Online rejimga qaytish'),
        content: const Text('Internet bilan va server bilan aloqa borligini tekshirib, online rejimga qaytishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Check internet connection
        final dio = Dio();
        await dio.get('https://www.google.com');

        // Check server connection
        final prefs = sl<SharedPreferencesService>();

        final serverService = sl<ServerService>();
        final serverUrl = serverService.baseUrl;

        // final serverName = prefs.getServerName();
        // final serverUrl = switch (serverName) {
        //   'Evyap' => 'http://kit.gloriya.uz:5443/EVYAP_UT/EVYAP_UT.1cws',
        //   'Garnier' => 'http://kit.gloriya.uz:5443/loreal_ut/loreal_ut.1cws',
        //   'PPD' => 'http://kit.gloriya.uz:5443/UT_Professionnel/UT_Professionnel.1cws',
        //   'Avon' => 'http://kit.gloriya.uz:5443/AVON_UT/AVON_UT.1cws',
        //   'AvonTest' => 'http://kit.gloriya.uz:5443/TEST_UT/TEST_UT.1cws',
        //   _ => 'http://kit.gloriya.uz:5443/EVYAP_UT/EVYAP_UT.1cws',
        // };
        // print('Server URL: $serverUrl');
        //log serverUrl
        if (serverUrl == null || serverUrl.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server manzili topilmadi')),
            );
          }
          return;
        }
        await dio.get(serverUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server URL: $serverUrl')),
          );
        }

        // Success: set offline to false and reload
        await prefs.setOfflineMode(false);
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.agentHomeRoute);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aloqa yo\'q: ${e.toString()}')),
          );
        }
      }
    }
  }

  Kpi _convertKpiViewToKpi(KpiView? kpiView) {
    if (kpiView == null) {
      return Kpi(
        totalPlan: 0,
        totalFact: 0,
        totalPercent: 0,
        totalForecast: 0,
        totalPercentForecastFact: 0,
        okb: 0,
        akbPlan: 0,
        akbFact: 0,
      );
    }

    // Parse values from KpiView strings
    double parseDouble(String? value) {
      if (value == null || value.isEmpty) return 0.0;
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }

    int parseInt(String? value) {
      if (value == null || value.isEmpty) return 0;
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return int.tryParse(cleaned) ?? 0;
    }

    return Kpi(
      totalPlan: parseDouble(kpiView.salesSum),
      totalFact: parseDouble(kpiView.salesSum), // Using salesSum as fact for now
      totalPercent: parseDouble(kpiView.totalPercent),
      totalForecast: parseDouble(kpiView.salesSum), // Using salesSum as forecast for now
      totalPercentForecastFact: parseDouble(kpiView.totalPercent),
      okb: parseInt(kpiView.customersServed),
      akbPlan: parseInt(kpiView.akbPlan),
      akbFact: parseInt(kpiView.akbFact),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        userName: widget.userName,
        userCode: widget.userCode,
        position: widget.position,
        project: widget.project,
        avatarUrl: widget.avatarUrl,
        onOpenCustomers: widget.onOpenCustomers,
        onReports: widget.onReports,
        onCash: widget.onCash,
        onDebitCredit: widget.onDebitCredit,
        onWarehouses: widget.onWarehouses,
        onProducts: widget.onOpenProducts,
        onPrices: widget.onPrices,
        onContracts: widget.onContracts,
        onSettings: widget.onSettings,
        onLogout: widget.onLogout,
      ),
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -80,
            right: -60,
            child: _decorBlob(Theme.of(context).extension<AppThemeExtension>()?.blobPrimary ?? const Color(0xFF6C8CFF), 220),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _decorBlob(Theme.of(context).extension<AppThemeExtension>()?.blobSecondary ?? const Color(0xFF00E5A8), 180),
          ),
          RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 160,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Menyu',
              ),
              flexibleSpace: _Header(userName: widget.userName, userCode: widget.userCode),
              actions: [
              //   Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8),
              //   child: ThemeToggle(
              //     mode: ThemeController.I.mode.value,
              //     onChanged: ThemeController.I.set,
              //   ),
              // ),
                Builder(
                  builder: (context) {
                    final prefs = sl<SharedPreferencesService>();
                    final isOffline = prefs.isOfflineMode();
                    if (!isOffline) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _onOfflineIndicatorTap,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Yangilash',
                  onPressed: _syncDataWithProgress,
                  icon: const Icon(Icons.refresh),
                ),
                // Offline indicator - shows when app is in offline mode

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
                child: _HeroHeader(kpi: _convertKpiViewToKpi(widget.kpi), controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))),
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
                    child: Column(
                      children: [
                        _StatsGrid(kpi: _convertKpiViewToKpi(widget.kpi)),
                        const SizedBox(height: 20),
                        _ChartsSection(kpi: _convertKpiViewToKpi(widget.kpi)),
                        const SizedBox(height: 20),
                        _Insights(kpi: _convertKpiViewToKpi(widget.kpi)),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // // Actions stay as-is
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            //     child: _ActionsRow(
            //       onCreateOrder: widget.onCreateOrder,
            //       onOpenCustomers: () => Navigator.pushNamed(context, AppRouter.tradingPointsRoute),
            //       onOpenProducts: widget.onOpenProducts,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      if (_isDataSyncInProgress && _syncStepStream != null)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: DataSyncProgressWidget(
              syncStepStream: _syncStepStream!,
              onComplete: _onDataSyncComplete,
              onError: _onDataSyncError,
            ),
          ),
        ),
    ],
  ));
  }

  // Moved helper to stateful class; keep same behavior

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
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).extension<AppThemeExtension>()?.glassBackground ?? const Color(0x334B6BFF),
                      Theme.of(context).extension<AppThemeExtension>()?.accentSecondary.withOpacity(0.3) ?? const Color(0x3316D2A6),
                    ],
                  ),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(data.icon, size: 20, color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white70),
                    const Spacer(),
                    Text(data.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white70)),
                    const SizedBox(height: 6),
                    Text(data.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white)),
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
        children: [
          Text('Charts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'AKB Progress',
            subtitle: 'Plan vs Fact',
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const _AxisLabel('Plan');
                            case 1:
                              return const _AxisLabel('Fact');
                            default:
                              return const SizedBox.shrink();
                          }
                        },
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
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).extension<AppThemeExtension>()?.glassBackground ?? const Color(0x221A73E8),
                      Theme.of(context).extension<AppThemeExtension>()?.accentSecondary.withOpacity(0.3) ?? const Color(0x2229C6B7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70)),
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
        Icon(Icons.brightness_1, size: 6, color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70),
        const SizedBox(width: 12),
        Expanded(child: Text(key, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white))),
        Text(val, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70)),
      ],
    ),
  );

  String _money(BuildContext context, double v) {
    final nf = NumberFormat.compact();
    return nf.format(v);
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).extension<AppThemeExtension>()?.glassBackground ?? const Color(
                          0x804B2DA5),
                      Theme.of(context).extension<AppThemeExtension>()?.accentSecondary.withOpacity(0.3) ?? const Color(
                          0x32FDFDFD),
                    ],
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
                              shaderCallback: (rect) => SweepGradient(
                            startAngle: -3.14159 / 2,
                            endAngle: 3 * 3.14159 / 2,
                            colors: [
                              Theme.of(context).extension<AppThemeExtension>()?.accentPrimary ?? const Color(0xFF6C8CFF),
                              Theme.of(context).extension<AppThemeExtension>()?.accentSecondary ?? const Color(0xFF00E5A8),
                            ],
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
              AnimatedPercentageWidget(
                percentage: percent ?? 0.0,
                type: PercentageDisplayType.circular,
                color: theme.colorScheme.primary,
                size: 92,
                valueText: percent == null ? '—' : '${(percent * 100).toStringAsFixed(1)}%',
              ),
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
                    AnimatedPercentageWidget(
                      percentage: percent ?? 0.0,
                      type: PercentageDisplayType.text,
                      color: theme.colorScheme.primary,
                      valueText: percent == null ? '-' : '${(percent * 100).toStringAsFixed(1)}%',
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedPercentageWidget(
                      percentage: 1.0, // Always animate to full for numbers
                      type: PercentageDisplayType.number,
                      color: theme.colorScheme.primary,
                      numberValue: value.isEmpty ? '0' : value.replaceAll(RegExp(r'[^0-9]'), ''), // Extract numbers
                      valueText: value.isEmpty ? '-' : value,
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

class _AppDrawer extends StatelessWidget {
  final String userName;
  final String userCode;
  final String? position;
  final String? project;
  final String? avatarUrl;
  final VoidCallback? onOpenCustomers;
  final VoidCallback? onReports;
  final VoidCallback? onCash;
  final VoidCallback? onDebitCredit;
  final VoidCallback? onWarehouses;
  final VoidCallback? onProducts;
  final VoidCallback? onPrices;
  final VoidCallback? onContracts;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  const _AppDrawer({
    required this.userName,
    required this.userCode,
    this.position,
    this.project,
    this.avatarUrl,
    this.onOpenCustomers,
    this.onReports,
    this.onCash,
    this.onDebitCredit,
    this.onWarehouses,
    this.onProducts,
    this.onPrices,
    this.onContracts,
    this.onSettings,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Drawer(
      child: Column(
        children: [
          // User info header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          userName.isNotEmpty ? userName.characters.first.toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (position != null)
                        Text(
                          position!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      Text(
                        'ID: $userCode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      if (project != null)
                        Text(
                          project!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _MenuItem(
                  icon: Icons.people,
                  title: 'Mijozlar',
                  onTap: () => Navigator.pushNamed(context, AppRouter.tradingPointsRoute),
                ),
                _MenuItem(
                  icon: Icons.bar_chart,
                  title: 'Hisobotlar',
                  onTap: () => Navigator.pushNamed(context, AppRouter.reportsRoute),
                ),

                _MenuItem(
                  icon: Icons.campaign,
                  title: 'Marketing',
                  onTap: () => Navigator.pushNamed(context, AppRouter.marketingRoute),
                ),
                _MenuItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Kassa',
                  onTap: null,
                ),
                _MenuItem(
                  icon: Icons.account_balance,
                  title: 'Debit-Kredit',
                  onTap: null,
                ),
                _MenuItem(
                  icon: Icons.warehouse,
                  title: 'Skladlar',
                  onTap: () => Navigator.pushNamed(context, AppRouter.warehousesRoute),
                ),
                _MenuItem(
                  icon: Icons.storefront,
                  title: 'Tovarlar',
                  onTap: onProducts,
                ),
                _MenuItem(
                  icon: Icons.price_change,
                  title: 'Narxlar',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricesPage())),
                ),
                _MenuItem(
                  icon: Icons.description,
                  title: 'Shartnomalar',
                  onTap: () => Navigator.pushNamed(context, AppRouter.contractsRoute),
                ),
                _MenuItem(
                  icon: Icons.receipt_long,
                  title: 'Buyurtmalar',
                  onTap: () => Navigator.pushNamed(context, AppRouter.ordersRoute),
                ),
              ],
            ),
          ),

          // Bottom section
          const Divider(),
          _MenuItem(
            icon: Icons.brightness_6,
            title: 'Dark mode',
            trailing: SizedBox(
              width: 80,
              child: ThemeToggle(
                mode: ThemeController.I.mode.value,
                onChanged: ThemeController.I.set,
              ),
            ),
            onTap: () => ThemeController.I.set(ThemeController.I.mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
          ),
          _MenuItem(
            icon: Icons.settings,
            title: 'Sozlamalar',
            onTap: onSettings,
          ),
          _MenuItem(
            icon: Icons.logout,
            title: 'Chiqish',
            onTap: onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    final listTile = ListTile(
      leading: Icon(
        icon,
        color: isDisabled ? theme.disabledColor : null,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDisabled ? theme.disabledColor : null,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );

    return isDisabled
        ? Opacity(
            opacity: 0.5,
            child: listTile,
          )
        : listTile;
  }
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
                userName.isNotEmpty
                    ? userName.characters.first.toUpperCase()
                    : 'U',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
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
                    maxLines: 3,
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
