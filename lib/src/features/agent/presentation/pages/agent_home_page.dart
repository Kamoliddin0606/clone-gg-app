import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';

class AgentHomePage extends StatefulWidget {
  const AgentHomePage({super.key});

  @override
  State<AgentHomePage> createState() => _AgentHomePageState();
}

class _AgentHomePageState extends State<AgentHomePage> {
  // KPI Data
  KpiData? _kpiData;
  String userName = "Agent User";
  String userCode = "";
  String password = "";
  String warehouseCode = "";
  bool _isLoadingKpi = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      
      // Load KPI data after user data is loaded
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
    print(_isLoadingKpi ? 'Already loading KPI data' : 'Refreshing KPI data...');
    print('Refreshing KPI data...');
    if (userCode.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foydalanuvchi ma\'lumotlari mavjud emas')),
      );
      return;
    }
    // if (userCode.isEmpty || password.isEmpty) return;
    print('User Code: $userCode, Password: $password');
    // Show loading indicator
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KPI ma\'lumotlari yangilandi'),
            backgroundColor: Colors.green,
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
      appBar: AppBar(
        title: const Text('Agent'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  // TODO: Navigate to settings
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
      body: RefreshIndicator(
        onRefresh: _refreshKpi,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildUserProfileSection(theme),
              _buildKpiSection(theme),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // KPI Plan and Fact Row
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'KPI Plan',
                  value: _kpiData?.plan ?? '-',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  title: 'KPI Fact',
                  value: _kpiData?.fact ?? '-',
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Total Percent and Forecast Row
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Total %',
                  value: _kpiData?.totalPercent ?? '-',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  title: 'Total Forecast',
                  value: _kpiData?.totalForecast ?? '-',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Forecast Fact Percent
          _buildKpiCard(
            title: 'Total % Forecast Fact',
            value: _kpiData?.totalPercentForecastFact ?? '-',
            color: Colors.teal,
          ),
          const SizedBox(height: 8),
          // AKB and OKB Row
          Row(
            children: [
              Expanded(
                child: _buildAkbCard(theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _buildKpiCard(
                      title: 'OKB',
                      value: _kpiData?.okb ?? '-',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildRefreshButton(theme),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAkbCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AKB',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _kpiData?.akbPlan ?? '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fact',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _kpiData?.akbFact ?? '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Percent',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _kpiData?.akbPercent ?? '-',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.primary,
      child: InkWell(
        onTap: _isLoadingKpi ? null : _refreshKpi,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_isLoadingKpi) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ] else ...[
                Text(
                  'Yangilash',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_kpiData?.updateDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateTime.parse(_kpiData!.updateDate).toString().substring(0, 16),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildActionCard(
            title: 'Vazifalar',
            subtitle: 'Savdo nuqtalari ro\'yxati',
            color: const Color(0xFF4CAF50),
            onTap: () {
              Navigator.pushNamed(context, AppRouter.tradingPointsRoute);
            },
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            title: 'Shartnomalar',
            subtitle: 'Shartnomalar bilan ishlash',
            color: const Color(0xFF4CAF50),
            onTap: () {
              // TODO: Navigate to contracts page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shartnomalar sahifasi hali tayyor emas')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
    } catch (e) {
      // SharedPreferences not ready, continue with logout
    }
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.loginRoute,
        (route) => false,
      );
    }
  }
}