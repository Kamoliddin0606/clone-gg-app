
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/Utility/formatter.dart';

class AgentHomePage extends StatefulWidget {
  const AgentHomePage({super.key});

  @override
  State<AgentHomePage> createState() => _AgentHomePageState();
}

class _AgentHomePageState extends State<AgentHomePage> with TickerProviderStateMixin {
  KpiData? _kpiData;
  String userName = "Agent User";
  String userCode = "";
  String password = "";
  String warehouseCode = "";
  bool _isLoadingKpi = false;
  bool _isKpiCardsExpanded = false;

  late AnimationController _planFactController;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Rang sxemasi
  static const Color primaryColor = Color(0xFF7CC4F8); // Asosiy ko'k
  static const Color primaryColorText = Color(0xFF197FAA); // Asosiy ko'k
  static const Color successColor = Color(0xFF52C591); // Yashil
  static const Color successColorText = Color(0xFF438E71); // Yashil
  static const Color accentColor = Color(0xFFFFE8A3); // To'q sariq
  // static const Color primaryColor = Color(0xFF1E1E2E); // Asosiy ko'k
  // static const Color successColor = Color(0xFF656565); // Yashil
  // static const Color accentColor = Color(0xFFCDD6F4); // To'q sariq
  @override
  void initState() {
    super.initState();
    _planFactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _planFactController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleKpiCards() {
    setState(() {
      _isKpiCardsExpanded = !_isKpiCardsExpanded;
    });

    if (_isKpiCardsExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  Future<void> _loadUserData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();

      setState(() {
        userCode = prefs.getUserCode() ?? "";
        password = prefs.getPassword() ?? "";
        warehouseCode = prefs.getWarehouseCode() ?? "";
        userName = prefs.getUserName() ?? "Agent User";
      });

      if (userCode.isNotEmpty && password.isNotEmpty) {
        await _loadKpiData();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadKpiData() async {
    if (userCode.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoadingKpi = true;
    });

    try {
      final repository = sl<AgentRepository>();
      final kpiData = await repository.getKpiData(
        userCode: userCode,
        password: password,
      );

      setState(() {
        _kpiData = kpiData;
        _isLoadingKpi = false;
      });
      _planFactController.forward(from: 0);
    } catch (e) {
      setState(() {
        _isLoadingKpi = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KPI ma\'lumotlarini yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshKpi() async {
    if (userCode.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foydalanuvchi ma\'lumotlari mavjud emas')),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KPI ma\'lumotlari yangilanmoqda...')),
      );
    }

    setState(() {
      _isLoadingKpi = true;
    });

    try {
      final repository = sl<AgentRepository>();
      final kpiData = await repository.getKpiData(
        userCode: userCode,
        password: password,
        forceRefresh: true,
      );

      setState(() {
        _kpiData = kpiData;
        _isLoadingKpi = false;
      });
      _planFactController.forward(from: 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KPI ma\'lumotlari yangilandi'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingKpi = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KPI ma\'lumotlarini yangilashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Agent'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Sozlamalar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Chiqish'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background - faqat asosiy rang
          // Container(
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [primaryColor, Color(0xFF1E40AF)],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //   ),
          // ),
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshKpi,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        _buildUserProfileSection(theme),
                        const SizedBox(height: 16),
                        _buildPlanFactProgress(theme),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _expandAnimation,
                          builder: (context, child) {
                            return SizeTransition(
                              sizeFactor: _expandAnimation,
                              child: _isKpiCardsExpanded
                                  ? Column(
                                children: [
                                  _buildKpiCards(theme),
                                  // const SizedBox(height: 16),
                                   _buildAkbOkbSection(theme),
                                  // const SizedBox(height: 16),
                                ],
                              )
                                  : const SizedBox.shrink(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomSection(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.7),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: primaryColor,
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: primaryColorText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: $userCode",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanFactProgress(ThemeData theme) {
    final plan = _kpiData?.plan != null ? num.tryParse(_kpiData!.plan) ?? 0 : 0;
    final fact = _kpiData?.fact != null ? num.tryParse(_kpiData!.fact) ?? 0 : 0;
    final percent = plan > 0 ? (fact / plan).clamp(0, 1).toDouble() : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _toggleKpiCards,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "KPI Plan / Fact",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColorText,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isKpiCardsExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryColorText,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: plan.toDouble(),
                        ),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Plan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                formatSum(value),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColorText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: fact.toDouble(),
                        ),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Fact", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                formatSum(value),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: successColorText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _planFactController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: percent * _planFactController.value,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(successColorText),
                      borderRadius: BorderRadius.circular(8),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(percent * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: successColorText,
                      ),
                    ),
                    Text(
                      _isKpiCardsExpanded ? "Yopish" : "Batafsil",
                      style: TextStyle(
                        color: primaryColorText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedKpiCard(
              title: "Total %",
              value: _kpiData?.totalPercent != null
                  ? formatProcent(num.tryParse(_kpiData!.totalPercent))
                  : "-",
              color: accentColor,
              icon: Icons.percent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _AnimatedKpiCard(
              title: "Total Forecast",
              value: _kpiData?.totalForecast != null
                  ? formatSum(num.tryParse(_kpiData!.totalForecast))
                  : "-",
              color: primaryColorText,
              icon: Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAkbOkbSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AnimatedKpiCard(
                  title: "AKB",
                  value: _kpiData?.akbPlan ?? "-",
                  color: primaryColorText,
                  icon: Icons.account_balance,
                  subtitle: "Plan",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnimatedKpiCard(
                  title: "OKB",
                  value: _kpiData?.okb ?? "-",
                  color: successColorText,
                  icon: Icons.all_inbox,
                  subtitle: "Fact",
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _AnimatedKpiCard(
                  title: "AKB ",
                  value: _kpiData?.akbFact ?? "-",
                  color: primaryColorText,
                  icon: Icons.check_circle,
                  subtitle: "Fact",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnimatedKpiCard(
                  title: "AKB ",
                  value: _kpiData?.totalPercent != null
                      ? formatProcent(num.tryParse(_kpiData!.akbPercent))
                      : "-",
                  color: successColorText,
                  icon: Icons.report_gmailerrorred,
                  subtitle: "Fact %",
                ),
              ),
            ],
          ),
        ],
      ),

    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.7),
          Colors.transparent,
        ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // _buildRefreshButton(theme),
              // const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),

    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _isLoadingKpi
          ? Card(
        key: const ValueKey('loading'),
        elevation: 4,
        color: primaryColorText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      )
          : Card(
        key: const ValueKey('button'),
        elevation: 4,
        color: primaryColorText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _refreshKpi,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Yangilash',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(

      child: Row(
        children: [
          Expanded(
            child: _AnimatedActionCard(
              title: 'Vazifalar',
              subtitle: 'Savdo nuqtalari',
              color: successColor,
              icon: Icons.list_alt,
              onTap: () {
                Navigator.pushNamed(context, AppRouter.tradingPointsRoute);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnimatedActionCard(
              title: 'Shartnomalar',
              subtitle: 'Shartnomalar',
              color: primaryColor,
              icon: Icons.assignment,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shartnomalar sahifasi hali tayyor emas')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chiqish'),
          content: const Text('Haqiqatan ham ilovadan chiqmoqchimisiz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => _logout(context),
              child: const Text('Chiqish'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      await prefs.clearCredentials();
    } catch (e) {}
    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.loginRoute,
            (route) => false,
      );
    }
  }
}

class _AnimatedKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _AnimatedKpiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedActionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}